#include "uinput_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <linux/uinput.h>
#include <linux/input-event-codes.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>

#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xrandr.h>
#endif

#define UINPUT_CHANNEL "com.xbmouse/uinput"

// Virtual device file descriptors
static int mouse_fd = -1;
static int keyboard_fd = -1;

// Screen dimensions for absolute positioning
static int total_screen_width = 1920;
static int total_screen_height = 1080;

static void emit_event(int fd, int type, int code, int val) {
  struct input_event ie;
  memset(&ie, 0, sizeof(ie));
  ie.type = type;
  ie.code = code;
  ie.value = val;
  if (write(fd, &ie, sizeof(ie)) < 0) {
    fprintf(stderr, "uinput: failed to emit event: %s\n", strerror(errno));
  }
}

static void emit_syn(int fd) {
  emit_event(fd, EV_SYN, SYN_REPORT, 0);
}

static int create_virtual_mouse() {
  int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
  if (fd < 0) {
    fprintf(stderr, "uinput: cannot open /dev/uinput: %s\n", strerror(errno));
    return -1;
  }

  // Enable relative movement events
  ioctl(fd, UI_SET_EVBIT, EV_REL);
  ioctl(fd, UI_SET_RELBIT, REL_X);
  ioctl(fd, UI_SET_RELBIT, REL_Y);

  // Enable key events (mouse buttons)
  ioctl(fd, UI_SET_EVBIT, EV_KEY);
  ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);
  ioctl(fd, UI_SET_KEYBIT, BTN_RIGHT);
  ioctl(fd, UI_SET_KEYBIT, BTN_MIDDLE);

  // Set as a pointer device to avoid being detected as a joystick
  ioctl(fd, UI_SET_PROPBIT, INPUT_PROP_POINTER);

  // Enable absolute movement events (for cross-screen jumps)
  ioctl(fd, UI_SET_EVBIT, EV_ABS);
  ioctl(fd, UI_SET_ABSBIT, ABS_X);
  ioctl(fd, UI_SET_ABSBIT, ABS_Y);

  struct uinput_setup usetup;
  memset(&usetup, 0, sizeof(usetup));
  usetup.id.bustype = BUS_USB;
  usetup.id.vendor  = 0x1234;
  usetup.id.product = 0x5678;
  snprintf(usetup.name, UINPUT_MAX_NAME_SIZE, "XBMouse Virtual Mouse");

  // Configure absolute axis ranges
  struct uinput_abs_setup abs_setup_x;
  memset(&abs_setup_x, 0, sizeof(abs_setup_x));
  abs_setup_x.code = ABS_X;
  abs_setup_x.absinfo.minimum = 0;
  abs_setup_x.absinfo.maximum = total_screen_width - 1;
  abs_setup_x.absinfo.resolution = 1;
  ioctl(fd, UI_ABS_SETUP, &abs_setup_x);

  struct uinput_abs_setup abs_setup_y;
  memset(&abs_setup_y, 0, sizeof(abs_setup_y));
  abs_setup_y.code = ABS_Y;
  abs_setup_y.absinfo.minimum = 0;
  abs_setup_y.absinfo.maximum = total_screen_height - 1;
  abs_setup_y.absinfo.resolution = 1;
  ioctl(fd, UI_ABS_SETUP, &abs_setup_y);

  ioctl(fd, UI_DEV_SETUP, &usetup);

  if (ioctl(fd, UI_DEV_CREATE) < 0) {
    fprintf(stderr, "uinput: UI_DEV_CREATE failed: %s\n", strerror(errno));
    close(fd);
    return -1;
  }

  // Give the system time to register the device
  usleep(100000);

  fprintf(stderr, "uinput: virtual mouse created successfully\n");
  return fd;
}

static int create_virtual_keyboard() {
  int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
  if (fd < 0) {
    fprintf(stderr, "uinput: cannot open /dev/uinput: %s\n", strerror(errno));
    return -1;
  }

  ioctl(fd, UI_SET_EVBIT, EV_KEY);

  // Enable all standard keys
  for (int i = 0; i < KEY_MAX; i++) {
    ioctl(fd, UI_SET_KEYBIT, i);
  }

  struct uinput_setup usetup;
  memset(&usetup, 0, sizeof(usetup));
  usetup.id.bustype = BUS_USB;
  usetup.id.vendor  = 0x1234;
  usetup.id.product = 0x5679;
  snprintf(usetup.name, UINPUT_MAX_NAME_SIZE, "XBMouse Virtual Keyboard");

  ioctl(fd, UI_DEV_SETUP, &usetup);

  if (ioctl(fd, UI_DEV_CREATE) < 0) {
    fprintf(stderr, "uinput: UI_DEV_CREATE for keyboard failed: %s\n", strerror(errno));
    close(fd);
    return -1;
  }

  usleep(100000);

  fprintf(stderr, "uinput: virtual keyboard created successfully\n");
  return fd;
}

static void destroy_virtual_devices() {
  if (mouse_fd >= 0) {
    ioctl(mouse_fd, UI_DEV_DESTROY);
    close(mouse_fd);
    mouse_fd = -1;
  }
  if (keyboard_fd >= 0) {
    ioctl(keyboard_fd, UI_DEV_DESTROY);
    close(keyboard_fd);
    keyboard_fd = -1;
  }
  fprintf(stderr, "uinput: virtual devices destroyed\n");
}

// Get screen info using GDK
static FlValue* get_screen_info() {
  FlValue* screens = fl_value_new_list();

  GdkDisplay* display = gdk_display_get_default();
  if (display == nullptr) {
    return screens;
  }

  int n_monitors = gdk_display_get_n_monitors(display);
  int total_w = 0;
  int total_h = 0;

  for (int i = 0; i < n_monitors; i++) {
    GdkMonitor* monitor = gdk_display_get_monitor(display, i);
    GdkRectangle geom;
    gdk_monitor_get_geometry(monitor, &geom);

    FlValue* screen = fl_value_new_map();
    fl_value_set_string_take(screen, "index", fl_value_new_int(i));
    fl_value_set_string_take(screen, "x", fl_value_new_int(geom.x));
    fl_value_set_string_take(screen, "y", fl_value_new_int(geom.y));
    fl_value_set_string_take(screen, "width", fl_value_new_int(geom.width));
    fl_value_set_string_take(screen, "height", fl_value_new_int(geom.height));
    fl_value_set_string_take(screen, "isPrimary",
        fl_value_new_bool(gdk_monitor_is_primary(monitor)));

    fl_value_append_take(screens, screen);

    // Track total screen bounds
    int right = geom.x + geom.width;
    int bottom = geom.y + geom.height;
    if (right > total_w) total_w = right;
    if (bottom > total_h) total_h = bottom;
  }

  // Update global screen dimensions for absolute positioning
  total_screen_width = total_w > 0 ? total_w : 1920;
  total_screen_height = total_h > 0 ? total_h : 1080;

  return screens;
}

static void method_call_handler(FlMethodChannel* channel,
                                FlMethodCall* method_call,
                                gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "init") == 0) {
    // Initialize virtual devices
    if (mouse_fd < 0) {
      mouse_fd = create_virtual_mouse();
    }
    if (keyboard_fd < 0) {
      keyboard_fd = create_virtual_keyboard();
    }
    bool success = (mouse_fd >= 0 && keyboard_fd >= 0);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(success)));

  } else if (strcmp(method, "dispose") == 0) {
    destroy_virtual_devices();
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(true)));

  } else if (strcmp(method, "moveMouse") == 0) {
    if (mouse_fd >= 0 && args != nullptr &&
        fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      int dx = fl_value_get_int(fl_value_lookup_string(args, "dx"));
      int dy = fl_value_get_int(fl_value_lookup_string(args, "dy"));
      emit_event(mouse_fd, EV_REL, REL_X, dx);
      emit_event(mouse_fd, EV_REL, REL_Y, dy);
      emit_syn(mouse_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "moveMouseAbsolute") == 0) {
    if (mouse_fd >= 0 && args != nullptr &&
        fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      int x = fl_value_get_int(fl_value_lookup_string(args, "x"));
      int y = fl_value_get_int(fl_value_lookup_string(args, "y"));
      emit_event(mouse_fd, EV_ABS, ABS_X, x);
      emit_event(mouse_fd, EV_ABS, ABS_Y, y);
      emit_syn(mouse_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "mouseDown") == 0) {
    if (mouse_fd >= 0 && args != nullptr) {
      int button = fl_value_get_int(args);
      emit_event(mouse_fd, EV_KEY, button, 1);
      emit_syn(mouse_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "mouseUp") == 0) {
    if (mouse_fd >= 0 && args != nullptr) {
      int button = fl_value_get_int(args);
      emit_event(mouse_fd, EV_KEY, button, 0);
      emit_syn(mouse_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "mouseClick") == 0) {
    if (mouse_fd >= 0 && args != nullptr) {
      int button = fl_value_get_int(args);
      emit_event(mouse_fd, EV_KEY, button, 1);
      emit_syn(mouse_fd);
      usleep(10000);
      emit_event(mouse_fd, EV_KEY, button, 0);
      emit_syn(mouse_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "keyDown") == 0) {
    if (keyboard_fd >= 0 && args != nullptr) {
      int keycode = fl_value_get_int(args);
      emit_event(keyboard_fd, EV_KEY, keycode, 1);
      emit_syn(keyboard_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "keyUp") == 0) {
    if (keyboard_fd >= 0 && args != nullptr) {
      int keycode = fl_value_get_int(args);
      emit_event(keyboard_fd, EV_KEY, keycode, 0);
      emit_syn(keyboard_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "keyPress") == 0) {
    if (keyboard_fd >= 0 && args != nullptr) {
      int keycode = fl_value_get_int(args);
      emit_event(keyboard_fd, EV_KEY, keycode, 1);
      emit_syn(keyboard_fd);
      usleep(10000);
      emit_event(keyboard_fd, EV_KEY, keycode, 0);
      emit_syn(keyboard_fd);
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "keyCombo") == 0) {
    if (keyboard_fd >= 0 && args != nullptr &&
        fl_value_get_type(args) == FL_VALUE_TYPE_LIST) {
      size_t len = fl_value_get_length(args);
      // Press all keys
      for (size_t i = 0; i < len; i++) {
        int keycode = fl_value_get_int(fl_value_get_list_value(args, i));
        emit_event(keyboard_fd, EV_KEY, keycode, 1);
        emit_syn(keyboard_fd);
      }
      usleep(10000);
      // Release all keys in reverse order
      for (size_t i = len; i > 0; i--) {
        int keycode = fl_value_get_int(fl_value_get_list_value(args, i - 1));
        emit_event(keyboard_fd, EV_KEY, keycode, 0);
        emit_syn(keyboard_fd);
      }
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(true)));
    } else {
      response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_bool(false)));
    }

  } else if (strcmp(method, "getScreenInfo") == 0) {
    FlValue* screens = get_screen_info();
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(screens));

  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

void uinput_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      UINPUT_CHANNEL,
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel, method_call_handler, nullptr, nullptr);
}
