#ifndef UINPUT_PLUGIN_H_
#define UINPUT_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

// Registers the uinput plugin with the Flutter engine.
void uinput_plugin_register_with_registrar(FlPluginRegistrar* registrar);

#endif  // UINPUT_PLUGIN_H_
