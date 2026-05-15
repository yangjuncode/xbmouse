/// Mouse simulation service.
/// Converts gamepad stick input to mouse movement with deadzone,
/// acceleration curve, and multi-screen support.

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/config_model.dart';
import 'uinput_service.dart';
import 'gamepad_service.dart';
import 'screen_service.dart';

class MouseService extends ChangeNotifier {
  final UinputService _uinput;
  final GamepadService _gamepad;
  final ScreenService _screen;

  MouseConfig _config = MouseConfig();
  bool _enabled = false;
  bool _dualScreenMode = false;
  Timer? _moveTimer;

  // Track which stick was last active for dual-screen mode
  int _lastActiveStick = -1; // -1=none, 0=left, 1=right

  MouseService(this._uinput, this._gamepad, this._screen);

  bool get isEnabled => _enabled;

  void updateConfig(MouseConfig config) {
    _config = config;
    _dualScreenMode = config.dualScreen;
    notifyListeners();
  }

  /// Start the mouse movement polling loop.
  void start() {
    if (_enabled) return;
    _enabled = true;

    // ~60fps update loop
    _moveTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _updateMousePosition(),
    );

    notifyListeners();
  }

  /// Stop the mouse movement polling loop.
  void stop() {
    _moveTimer?.cancel();
    _moveTimer = null;
    _enabled = false;
    _lastActiveStick = -1;
    notifyListeners();
  }

  void _updateMousePosition() {
    if (!_enabled || !_gamepad.isConnected) return;

    final state = _gamepad.state;

    // Get stick values
    double leftX = state.leftStickX;
    double leftY = state.leftStickY;
    double rightX = state.rightStickX;
    double rightY = state.rightStickY;

    // Apply deadzone
    leftX = _applyDeadzone(leftX);
    leftY = _applyDeadzone(leftY);
    rightX = _applyDeadzone(rightX);
    rightY = _applyDeadzone(rightY);

    bool leftActive = leftX != 0 || leftY != 0;
    bool rightActive = rightX != 0 || rightY != 0;

    if (_dualScreenMode) {
      // Dual-screen mode: each stick controls a different screen
      _handleDualScreenMode(leftX, leftY, rightX, rightY, leftActive, rightActive);
    } else {
      // Single-screen mode:
      //   Left stick  → normal speed (for large movements)
      //   Right stick → slow speed via rightStickSensitivity (for fine positioning)
      if (leftActive) {
        _emitMouseMove(leftX, leftY, sensitivityMultiplier: 1.0);
      }
      if (rightActive) {
        _emitMouseMove(rightX, rightY, sensitivityMultiplier: _config.rightStickSensitivity);
      }
    }
  }

  void _handleDualScreenMode(
    double leftX, double leftY,
    double rightX, double rightY,
    bool leftActive, bool rightActive,
  ) {
    if (leftActive && !rightActive) {
      // Left stick active - switch to screen 0 if needed
      if (_lastActiveStick != 0) {
        _lastActiveStick = 0;
        final targetScreen = _screen.getScreenForStick(true);
        _screen.switchToScreen(targetScreen);
      }
      _emitMouseMove(leftX, leftY);
    } else if (rightActive && !leftActive) {
      // Right stick active - switch to screen 1 if needed
      if (_lastActiveStick != 1) {
        _lastActiveStick = 1;
        final targetScreen = _screen.getScreenForStick(false);
        _screen.switchToScreen(targetScreen);
      }
      _emitMouseMove(rightX, rightY);
    } else if (leftActive && rightActive) {
      // Both active - prefer the most recently activated one
      if (_lastActiveStick == 0) {
        _emitMouseMove(leftX, leftY);
      } else {
        _emitMouseMove(rightX, rightY);
      }
    }
  }

  /// Apply deadzone to an axis value.
  double _applyDeadzone(double value) {
    if (value.abs() < _config.deadzone) return 0.0;
    // Rescale so movement starts from 0 after deadzone
    double sign = value > 0 ? 1.0 : -1.0;
    return sign * (value.abs() - _config.deadzone) / (1.0 - _config.deadzone);
  }

  /// Apply acceleration curve and emit mouse movement.
  /// [sensitivityMultiplier] scales the final speed; use values < 1.0 for slower movement.
  void _emitMouseMove(double x, double y, {double sensitivityMultiplier = 1.0}) {
    // Calculate magnitude
    double magnitude = sqrt(x * x + y * y).clamp(0.0, 1.0);

    // Apply acceleration curve: output = input^acceleration
    double accelerated = pow(magnitude, _config.acceleration).toDouble();

    // Calculate direction
    double angle = atan2(y, x);

    // Scale by sensitivity (base speed in pixels per frame) and the per-stick multiplier
    double baseSpeed = 20.0 * _config.sensitivity * sensitivityMultiplier;
    double speed = accelerated * baseSpeed;

    int dx = (speed * cos(angle)).round();
    int dy = (speed * sin(angle)).round();

    if (dx != 0 || dy != 0) {
      _uinput.moveMouse(dx, dy);
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
