/// Configuration data models for XBMouse.
/// Supports serialization to/from TOML format.

/// Mouse configuration parameters.
class MouseConfig {
  double sensitivity;
  double acceleration;
  double deadzone;
  bool dualScreen;
  /// 单屏模式下右摇杆相对灵敏度倍数（相对于 sensitivity），用于精确定位。
  /// 例如 0.2 表示右摇杆速度为左摇杆的 20%。
  double rightStickSensitivity;

  MouseConfig({
    this.sensitivity = 1.0,
    this.acceleration = 2.0,
    this.deadzone = 0.15,
    this.dualScreen = false,
    this.rightStickSensitivity = 0.1,
  });

  MouseConfig copyWith({
    double? sensitivity,
    double? acceleration,
    double? deadzone,
    bool? dualScreen,
    double? rightStickSensitivity,
  }) {
    return MouseConfig(
      sensitivity: sensitivity ?? this.sensitivity,
      acceleration: acceleration ?? this.acceleration,
      deadzone: deadzone ?? this.deadzone,
      dualScreen: dualScreen ?? this.dualScreen,
      rightStickSensitivity: rightStickSensitivity ?? this.rightStickSensitivity,
    );
  }

  Map<String, dynamic> toMap() => {
    'sensitivity': sensitivity,
    'acceleration': acceleration,
    'deadzone': deadzone,
    'dual_screen': dualScreen,
    'right_stick_sensitivity': rightStickSensitivity,
  };

  factory MouseConfig.fromMap(Map<String, dynamic> map) => MouseConfig(
    sensitivity: (map['sensitivity'] as num?)?.toDouble() ?? 1.0,
    acceleration: (map['acceleration'] as num?)?.toDouble() ?? 2.0,
    deadzone: (map['deadzone'] as num?)?.toDouble() ?? 0.15,
    dualScreen: map['dual_screen'] as bool? ?? false,
    rightStickSensitivity: (map['right_stick_sensitivity'] as num?)?.toDouble() ?? 0.1,
  );
}

/// Single button-to-key mapping entry.
class KeyMappingEntry {
  final String gamepadButton;
  String keyAction; // Key name, "BTN_LEFT", "@SWITCH_SCREEN", etc.

  KeyMappingEntry({
    required this.gamepadButton,
    required this.keyAction,
  });

  /// Check if this is a mouse button action
  bool get isMouseButton => keyAction.startsWith('BTN_');

  /// Check if this is a special action
  bool get isSpecialAction => keyAction.startsWith('@');

  /// Check if this mapping is disabled
  bool get isDisabled => keyAction.isEmpty;
}

/// Collection of all button mappings.
class ButtonMappings {
  // Face buttons
  String a;
  String b;
  String x;
  String y;

  // Bumpers
  String lb;
  String rb;

  // Menu buttons
  String start;
  String back;

  // Stick clicks
  String lstick;
  String rstick;

  // D-pad
  String dpadUp;
  String dpadDown;
  String dpadLeft;
  String dpadRight;

  // Triggers
  String lt;
  String rt;

  ButtonMappings({
    this.a = 'Return',
    this.b = 'Escape',
    this.x = 'BackSpace',
    this.y = 'Tab',
    this.lb = 'Control_L',
    this.rb = 'Control_L+w',
    this.start = 'Super_L',
    this.back = 'Menu',
    this.lstick = 'BTN_MIDDLE',
    this.rstick = '',
    this.dpadUp = 'Prior',
    this.dpadDown = 'Next',
    this.dpadLeft = '@SWITCH_SCREEN',
    this.dpadRight = '',
    this.lt = 'BTN_LEFT',
    this.rt = 'BTN_RIGHT',
  });

  /// Get mapping by gamepad button name
  String getMapping(String buttonName) {
    switch (buttonName) {
      case 'a': return a;
      case 'b': return b;
      case 'x': return x;
      case 'y': return y;
      case 'lb': return lb;
      case 'rb': return rb;
      case 'start': return start;
      case 'back': return back;
      case 'lstick': return lstick;
      case 'rstick': return rstick;
      case 'dpad_up': return dpadUp;
      case 'dpad_down': return dpadDown;
      case 'dpad_left': return dpadLeft;
      case 'dpad_right': return dpadRight;
      case 'lt': return lt;
      case 'rt': return rt;
      default: return '';
    }
  }

  /// Set mapping by gamepad button name
  void setMapping(String buttonName, String keyAction) {
    switch (buttonName) {
      case 'a': a = keyAction; break;
      case 'b': b = keyAction; break;
      case 'x': x = keyAction; break;
      case 'y': y = keyAction; break;
      case 'lb': lb = keyAction; break;
      case 'rb': rb = keyAction; break;
      case 'start': start = keyAction; break;
      case 'back': back = keyAction; break;
      case 'lstick': lstick = keyAction; break;
      case 'rstick': rstick = keyAction; break;
      case 'dpad_up': dpadUp = keyAction; break;
      case 'dpad_down': dpadDown = keyAction; break;
      case 'dpad_left': dpadLeft = keyAction; break;
      case 'dpad_right': dpadRight = keyAction; break;
      case 'lt': lt = keyAction; break;
      case 'rt': rt = keyAction; break;
    }
  }

  Map<String, String> toButtonsMap() => {
    'a': a, 'b': b, 'x': x, 'y': y,
    'lb': lb, 'rb': rb,
    'start': start, 'back': back,
    'lstick': lstick, 'rstick': rstick,
  };

  Map<String, String> toDpadMap() => {
    'up': dpadUp, 'down': dpadDown,
    'left': dpadLeft, 'right': dpadRight,
  };

  Map<String, String> toTriggersMap() => {
    'lt': lt, 'rt': rt,
  };

  factory ButtonMappings.fromMaps({
    Map<String, dynamic>? buttons,
    Map<String, dynamic>? dpad,
    Map<String, dynamic>? triggers,
  }) {
    return ButtonMappings(
      a: buttons?['a'] as String? ?? 'Return',
      b: buttons?['b'] as String? ?? 'Escape',
      x: buttons?['x'] as String? ?? 'BackSpace',
      y: buttons?['y'] as String? ?? 'Tab',
      lb: buttons?['lb'] as String? ?? 'Control_L',
      rb: buttons?['rb'] as String? ?? 'Control_L+w',
      start: buttons?['start'] as String? ?? 'Super_L',
      back: buttons?['back'] as String? ?? 'Menu',
      lstick: buttons?['lstick'] as String? ?? 'BTN_MIDDLE',
      rstick: buttons?['rstick'] as String? ?? '',
      dpadUp: dpad?['up'] as String? ?? 'Prior',
      dpadDown: dpad?['down'] as String? ?? 'Next',
      dpadLeft: dpad?['left'] as String? ?? '@SWITCH_SCREEN',
      dpadRight: dpad?['right'] as String? ?? '',
      lt: triggers?['lt'] as String? ?? 'BTN_LEFT',
      rt: triggers?['rt'] as String? ?? 'BTN_RIGHT',
    );
  }

  /// Get all entries as a flat list for UI display
  List<KeyMappingEntry> toEntryList() => [
    KeyMappingEntry(gamepadButton: 'a', keyAction: a),
    KeyMappingEntry(gamepadButton: 'b', keyAction: b),
    KeyMappingEntry(gamepadButton: 'x', keyAction: x),
    KeyMappingEntry(gamepadButton: 'y', keyAction: y),
    KeyMappingEntry(gamepadButton: 'lb', keyAction: lb),
    KeyMappingEntry(gamepadButton: 'rb', keyAction: rb),
    KeyMappingEntry(gamepadButton: 'start', keyAction: start),
    KeyMappingEntry(gamepadButton: 'back', keyAction: back),
    KeyMappingEntry(gamepadButton: 'lstick', keyAction: lstick),
    KeyMappingEntry(gamepadButton: 'rstick', keyAction: rstick),
    KeyMappingEntry(gamepadButton: 'dpad_up', keyAction: dpadUp),
    KeyMappingEntry(gamepadButton: 'dpad_down', keyAction: dpadDown),
    KeyMappingEntry(gamepadButton: 'dpad_left', keyAction: dpadLeft),
    KeyMappingEntry(gamepadButton: 'dpad_right', keyAction: dpadRight),
    KeyMappingEntry(gamepadButton: 'lt', keyAction: lt),
    KeyMappingEntry(gamepadButton: 'rt', keyAction: rt),
  ];
}

/// Application-level config.
class AppConfig {
  bool startEnabled;
  bool startMinimized;

  AppConfig({
    this.startEnabled = true,
    this.startMinimized = false,
  });

  Map<String, dynamic> toMap() => {
    'start_enabled': startEnabled,
    'start_minimized': startMinimized,
  };

  factory AppConfig.fromMap(Map<String, dynamic> map) => AppConfig(
    startEnabled: map['start_enabled'] as bool? ?? true,
    startMinimized: map['start_minimized'] as bool? ?? false,
  );
}

/// Root configuration combining all sections.
class XBMouseConfig {
  MouseConfig mouse;
  ButtonMappings buttons;
  AppConfig app;

  XBMouseConfig({
    MouseConfig? mouse,
    ButtonMappings? buttons,
    AppConfig? app,
  })  : mouse = mouse ?? MouseConfig(),
        buttons = buttons ?? ButtonMappings(),
        app = app ?? AppConfig();

  factory XBMouseConfig.fromMap(Map<String, dynamic> map) {
    return XBMouseConfig(
      mouse: MouseConfig.fromMap(
        (map['mouse'] as Map<String, dynamic>?) ?? {},
      ),
      buttons: ButtonMappings.fromMaps(
        buttons: (map['buttons'] as Map<String, dynamic>?),
        dpad: (map['dpad'] as Map<String, dynamic>?),
        triggers: (map['triggers'] as Map<String, dynamic>?),
      ),
      app: AppConfig.fromMap(
        (map['app'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

/// Human-readable display names for gamepad buttons.
const Map<String, String> gamepadButtonDisplayNames = {
  'a': 'A',
  'b': 'B',
  'x': 'X',
  'y': 'Y',
  'lb': 'LB (Left Bumper)',
  'rb': 'RB (Right Bumper)',
  'start': 'Start',
  'back': 'Back/Select',
  'lstick': 'Left Stick Press',
  'rstick': 'Right Stick Press',
  'dpad_up': 'D-Pad Up',
  'dpad_down': 'D-Pad Down',
  'dpad_left': 'D-Pad Left',
  'dpad_right': 'D-Pad Right',
  'lt': 'LT (Left Trigger)',
  'rt': 'RT (Right Trigger)',
};
