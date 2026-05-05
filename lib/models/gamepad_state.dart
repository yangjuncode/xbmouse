/// Gamepad state tracking model.

/// Represents a connected gamepad.
class GamepadInfo {
  final String id;
  final String name;

  GamepadInfo({required this.id, required this.name});
}

/// Real-time gamepad axis and button state.
class GamepadState {
  // Connection
  bool connected = false;
  GamepadInfo? gamepadInfo;

  // Left stick axes (-1.0 to 1.0)
  double leftStickX = 0.0;
  double leftStickY = 0.0;

  // Right stick axes (-1.0 to 1.0)
  double rightStickX = 0.0;
  double rightStickY = 0.0;

  // Triggers (0.0 to 1.0)
  double leftTrigger = 0.0;
  double rightTrigger = 0.0;

  // Face buttons
  bool buttonA = false;
  bool buttonB = false;
  bool buttonX = false;
  bool buttonY = false;

  // Bumpers
  bool leftBumper = false;
  bool rightBumper = false;

  // Menu buttons
  bool buttonStart = false;
  bool buttonBack = false;

  // Stick clicks
  bool leftStickButton = false;
  bool rightStickButton = false;

  // D-pad
  bool dpadUp = false;
  bool dpadDown = false;
  bool dpadLeft = false;
  bool dpadRight = false;

  void reset() {
    connected = false;
    gamepadInfo = null;
    leftStickX = 0.0;
    leftStickY = 0.0;
    rightStickX = 0.0;
    rightStickY = 0.0;
    leftTrigger = 0.0;
    rightTrigger = 0.0;
    buttonA = false;
    buttonB = false;
    buttonX = false;
    buttonY = false;
    leftBumper = false;
    rightBumper = false;
    buttonStart = false;
    buttonBack = false;
    leftStickButton = false;
    rightStickButton = false;
    dpadUp = false;
    dpadDown = false;
    dpadLeft = false;
    dpadRight = false;
  }
}

/// Screen information from native layer.
class ScreenInfo {
  final int index;
  final int x;
  final int y;
  final int width;
  final int height;
  final bool isPrimary;

  ScreenInfo({
    required this.index,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.isPrimary,
  });

  int get centerX => x + width ~/ 2;
  int get centerY => y + height ~/ 2;

  factory ScreenInfo.fromMap(Map<dynamic, dynamic> map) => ScreenInfo(
    index: map['index'] as int? ?? 0,
    x: map['x'] as int? ?? 0,
    y: map['y'] as int? ?? 0,
    width: map['width'] as int? ?? 1920,
    height: map['height'] as int? ?? 1080,
    isPrimary: map['isPrimary'] as bool? ?? false,
  );
}
