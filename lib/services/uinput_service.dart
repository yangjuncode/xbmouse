/// Service for communicating with the C++ uinput native plugin
/// via Flutter MethodChannel.

import 'package:flutter/services.dart';

class UinputService {
  static const _channel = MethodChannel('com.xbmouse/uinput');

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize virtual mouse and keyboard devices.
  Future<bool> init() async {
    try {
      final result = await _channel.invokeMethod<bool>('init');
      _initialized = result ?? false;
      return _initialized;
    } catch (e) {
      print('UinputService.init error: $e');
      _initialized = false;
      return false;
    }
  }

  /// Destroy virtual devices.
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
      _initialized = false;
    } catch (e) {
      print('UinputService.dispose error: $e');
    }
  }

  /// Move mouse relatively by (dx, dy) pixels.
  Future<void> moveMouse(int dx, int dy) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('moveMouse', {'dx': dx, 'dy': dy});
    } catch (e) {
      // Silently fail for movement to avoid log spam
    }
  }

  /// Move mouse to absolute position (x, y) across all screens.
  Future<void> moveMouseAbsolute(int x, int y) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('moveMouseAbsolute', {'x': x, 'y': y});
    } catch (e) {
      print('UinputService.moveMouseAbsolute error: $e');
    }
  }

  /// Press and release a mouse button.
  /// button: 0x110 (BTN_LEFT), 0x111 (BTN_RIGHT), 0x112 (BTN_MIDDLE)
  Future<void> mouseClick(int button) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('mouseClick', button);
    } catch (e) {
      print('UinputService.mouseClick error: $e');
    }
  }

  /// Press a mouse button down.
  Future<void> mouseDown(int button) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('mouseDown', button);
    } catch (e) {
      print('UinputService.mouseDown error: $e');
    }
  }

  /// Release a mouse button.
  Future<void> mouseUp(int button) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('mouseUp', button);
    } catch (e) {
      print('UinputService.mouseUp error: $e');
    }
  }

  /// Press a keyboard key down.
  Future<void> keyDown(int keycode) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('keyDown', keycode);
    } catch (e) {
      print('UinputService.keyDown error: $e');
    }
  }

  /// Release a keyboard key.
  Future<void> keyUp(int keycode) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('keyUp', keycode);
    } catch (e) {
      print('UinputService.keyUp error: $e');
    }
  }

  /// Press and release a keyboard key.
  Future<void> keyPress(int keycode) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('keyPress', keycode);
    } catch (e) {
      print('UinputService.keyPress error: $e');
    }
  }

  /// Press and release a combination of keys.
  Future<void> keyCombo(List<int> keycodes) async {
    if (!_initialized) return;
    try {
      await _channel.invokeMethod('keyCombo', keycodes);
    } catch (e) {
      print('UinputService.keyCombo error: $e');
    }
  }

  /// Get screen layout information from native layer.
  Future<List<Map<String, dynamic>>> getScreenInfo() async {
    try {
      final result = await _channel.invokeMethod('getScreenInfo');
      if (result is List) {
        return result.map((e) {
          if (e is Map) {
            return Map<String, dynamic>.from(e);
          }
          return <String, dynamic>{};
        }).toList();
      }
      return [];
    } catch (e) {
      print('UinputService.getScreenInfo error: $e');
      return [];
    }
  }
}

/// Linux input event key codes (from linux/input-event-codes.h).
/// Only commonly used ones are listed here.
class LinuxKeyCodes {
  // Mouse buttons
  static const int btnLeft = 0x110;
  static const int btnRight = 0x111;
  static const int btnMiddle = 0x112;

  // Standard keys
  static const int keyEsc = 1;
  static const int key1 = 2;
  static const int key2 = 3;
  static const int key3 = 4;
  static const int key4 = 5;
  static const int key5 = 6;
  static const int key6 = 7;
  static const int key7 = 8;
  static const int key8 = 9;
  static const int key9 = 10;
  static const int key0 = 11;
  static const int keyMinus = 12;
  static const int keyEqual = 13;
  static const int keyBackspace = 14;
  static const int keyTab = 15;
  static const int keyQ = 16;
  static const int keyW = 17;
  static const int keyE = 18;
  static const int keyR = 19;
  static const int keyT = 20;
  static const int keyY = 21;
  static const int keyU = 22;
  static const int keyI = 23;
  static const int keyO = 24;
  static const int keyP = 25;
  static const int keyLeftBrace = 26;
  static const int keyRightBrace = 27;
  static const int keyEnter = 28;
  static const int keyLeftCtrl = 29;
  static const int keyA = 30;
  static const int keyS = 31;
  static const int keyD = 32;
  static const int keyF = 33;
  static const int keyG = 34;
  static const int keyH = 35;
  static const int keyJ = 36;
  static const int keyK = 37;
  static const int keyL = 38;
  static const int keySemicolon = 39;
  static const int keyApostrophe = 40;
  static const int keyGrave = 41;
  static const int keyLeftShift = 42;
  static const int keyBackslash = 43;
  static const int keyZ = 44;
  static const int keyX = 45;
  static const int keyC = 46;
  static const int keyV = 47;
  static const int keyB = 48;
  static const int keyN = 49;
  static const int keyM = 50;
  static const int keyComma = 51;
  static const int keyDot = 52;
  static const int keySlash = 53;
  static const int keyRightShift = 54;
  static const int keyLeftAlt = 56;
  static const int keySpace = 57;
  static const int keyCapsLock = 58;
  static const int keyF1 = 59;
  static const int keyF2 = 60;
  static const int keyF3 = 61;
  static const int keyF4 = 62;
  static const int keyF5 = 63;
  static const int keyF6 = 64;
  static const int keyF7 = 65;
  static const int keyF8 = 66;
  static const int keyF9 = 67;
  static const int keyF10 = 68;
  static const int keyF11 = 87;
  static const int keyF12 = 88;

  // Navigation
  static const int keyHome = 102;
  static const int keyUp = 103;
  static const int keyPageUp = 104;
  static const int keyLeft = 105;
  static const int keyRight = 106;
  static const int keyEnd = 107;
  static const int keyDown = 108;
  static const int keyPageDown = 109;
  static const int keyInsert = 110;
  static const int keyDelete = 111;

  // Modifiers
  static const int keyRightCtrl = 97;
  static const int keyRightAlt = 100;
  static const int keyLeftMeta = 125;
  static const int keyRightMeta = 126;
  static const int keyMenu = 127;

  /// Map X11/human-readable key names to Linux keycodes.
  static final Map<String, int> nameToKeycode = {
    // Mouse buttons
    'BTN_LEFT': btnLeft,
    'BTN_RIGHT': btnRight,
    'BTN_MIDDLE': btnMiddle,

    // Letters
    'a': keyA, 'b': keyB, 'c': keyC, 'd': keyD,
    'e': keyE, 'f': keyF, 'g': keyG, 'h': keyH,
    'i': keyI, 'j': keyJ, 'k': keyK, 'l': keyL,
    'm': keyM, 'n': keyN, 'o': keyO, 'p': keyP,
    'q': keyQ, 'r': keyR, 's': keyS, 't': keyT,
    'u': keyU, 'v': keyV, 'w': keyW, 'x': keyX,
    'y': keyY, 'z': keyZ,

    // Numbers
    '1': key1, '2': key2, '3': key3, '4': key4, '5': key5,
    '6': key6, '7': key7, '8': key8, '9': key9, '0': key0,

    // Standard keys (X11-style names)
    'Return': keyEnter,
    'Escape': keyEsc,
    'BackSpace': keyBackspace,
    'Tab': keyTab,
    'space': keySpace,
    'Space': keySpace,
    'Delete': keyDelete,
    'Insert': keyInsert,

    // Navigation
    'Home': keyHome,
    'End': keyEnd,
    'Prior': keyPageUp,     // Page Up
    'Next': keyPageDown,     // Page Down
    'Up': keyUp,
    'Down': keyDown,
    'Left': keyLeft,
    'Right': keyRight,

    // Modifiers
    'Control_L': keyLeftCtrl,
    'Control_R': keyRightCtrl,
    'Shift_L': keyLeftShift,
    'Shift_R': keyRightShift,
    'Alt_L': keyLeftAlt,
    'Alt_R': keyRightAlt,
    'Super_L': keyLeftMeta,
    'Super_R': keyRightMeta,
    'Menu': keyMenu,

    // Function keys
    'F1': keyF1, 'F2': keyF2, 'F3': keyF3, 'F4': keyF4,
    'F5': keyF5, 'F6': keyF6, 'F7': keyF7, 'F8': keyF8,
    'F9': keyF9, 'F10': keyF10, 'F11': keyF11, 'F12': keyF12,

    // Symbols
    'minus': keyMinus,
    'equal': keyEqual,
    'bracketleft': keyLeftBrace,
    'bracketright': keyRightBrace,
    'semicolon': keySemicolon,
    'apostrophe': keyApostrophe,
    'grave': keyGrave,
    'backslash': keyBackslash,
    'comma': keyComma,
    'period': keyDot,
    'slash': keySlash,
  };

  /// Resolve a key name (from TOML config) to a Linux keycode.
  /// Returns null for special actions (starting with '@') or empty strings.
  static int? resolve(String keyName) {
    if (keyName.isEmpty || keyName.startsWith('@')) return null;
    return nameToKeycode[keyName];
  }

  /// Get human-readable display name for a keycode mapping.
  static String displayName(String keyAction) {
    if (keyAction.isEmpty) return '(未分配)';
    if (keyAction == '@SWITCH_SCREEN') return '切换屏幕';
    if (keyAction == 'BTN_LEFT') return '鼠标左键';
    if (keyAction == 'BTN_RIGHT') return '鼠标右键';
    if (keyAction == 'BTN_MIDDLE') return '鼠标中键';
    if (keyAction == 'Prior') return 'Page Up';
    if (keyAction == 'Next') return 'Page Down';
    return keyAction;
  }
}
