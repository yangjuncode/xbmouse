/// Gamepad input service using the gamepads package.
/// Listens for Xbox controller events and exposes them as streams.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';
import '../models/gamepad_state.dart';

class GamepadService extends ChangeNotifier {
  StreamSubscription<GamepadEvent>? _rawSubscription;
  final GamepadState state = GamepadState();
  bool _listening = false;

  bool get isListening => _listening;
  bool get isConnected => state.connected;

  /// Start listening to gamepad events.
  void startListening() {
    if (_listening) return;
    _listening = true;

    _rawSubscription = Gamepads.events.listen(_handleEvent);
    notifyListeners();
  }

  /// Stop listening to gamepad events.
  void stopListening() {
    _rawSubscription?.cancel();
    _rawSubscription = null;
    _listening = false;
    state.reset();
    notifyListeners();
  }

  void _handleEvent(GamepadEvent event) {
    // Mark as connected when we receive any event
    if (!state.connected) {
      state.connected = true;
      state.gamepadInfo = GamepadInfo(
        id: event.gamepadId,
        name: event.gamepadId,
      );
    }

    // Map the key/axis from the event
    _processEvent(event);
    notifyListeners();
  }

  void _processEvent(GamepadEvent event) {
    final key = event.key;
    final value = event.value;

    // Axes - normalized values from gamepads package
    // Axis values are typically 0.0 to 1.0 for the raw API
    switch (key) {
      // Left stick
      case 'leftStickX':
      case '0':  // Raw axis 0
        state.leftStickX = _normalizeAxis(value);
        break;
      case 'leftStickY':
      case '1':  // Raw axis 1
        state.leftStickY = _normalizeAxis(value);
        break;

      // Right stick
      case 'rightStickX':
      case '2':  // Raw axis 2
      case '3':  // Some controllers use axis 3
        state.rightStickX = _normalizeAxis(value);
        break;
      case 'rightStickY':
      case '3':  // Raw axis 3
      case '4':  // Some controllers use axis 4
        state.rightStickY = _normalizeAxis(value);
        break;

      // Left trigger
      case 'leftTrigger':
      case '5':  // Some report as axis 5
        state.leftTrigger = _normalizeTrigger(value);
        break;

      // Right trigger
      case 'rightTrigger':
      case '4':  // Some report as axis 4
        state.rightTrigger = _normalizeTrigger(value);
        break;

      // Face buttons
      case 'a':
      case '0_button':
        state.buttonA = value > 0.5;
        break;
      case 'b':
      case '1_button':
        state.buttonB = value > 0.5;
        break;
      case 'x':
      case '2_button':
      case '3_button':
        state.buttonX = value > 0.5;
        break;
      case 'y':
      case '3_button':
      case '4_button':
        state.buttonY = value > 0.5;
        break;

      // Bumpers
      case 'leftBumper':
      case '4_button':
      case '6_button':
        state.leftBumper = value > 0.5;
        break;
      case 'rightBumper':
      case '5_button':
      case '7_button':
        state.rightBumper = value > 0.5;
        break;

      // Menu buttons
      case 'start':
      case '7_button':
      case '9_button':
        state.buttonStart = value > 0.5;
        break;
      case 'back':
      case '6_button':
      case '8_button':
        state.buttonBack = value > 0.5;
        break;

      // Stick buttons
      case 'leftStickButton':
      case '9_button':
      case '10_button':
        state.leftStickButton = value > 0.5;
        break;
      case 'rightStickButton':
      case '10_button':
      case '11_button':
        state.rightStickButton = value > 0.5;
        break;

      // D-pad (may come as axes or buttons)
      case 'dpadUp':
      case '12_button':
        state.dpadUp = value > 0.5;
        break;
      case 'dpadDown':
      case '13_button':
        state.dpadDown = value > 0.5;
        break;
      case 'dpadLeft':
      case '14_button':
        state.dpadLeft = value > 0.5;
        break;
      case 'dpadRight':
      case '15_button':
        state.dpadRight = value > 0.5;
        break;

      // D-pad as axes (HAT)
      case '6':  // HAT X axis
        state.dpadLeft = value < -0.5;
        state.dpadRight = value > 0.5;
        break;
      case '7':  // HAT Y axis
        state.dpadUp = value < -0.5;
        state.dpadDown = value > 0.5;
        break;
    }
  }

  /// Normalize axis value from gamepads (0.0-1.0 range) to -1.0..1.0
  double _normalizeAxis(double value) {
    // gamepads package reports raw values
    // For axes, the raw value needs mapping depending on the platform
    // On Linux with evdev, axes are typically 0-65535, normalized by gamepads to 0.0-1.0
    // We need to convert to -1.0 to 1.0
    return (value * 2.0 - 1.0).clamp(-1.0, 1.0);
  }

  /// Normalize trigger from 0.0-1.0 range
  double _normalizeTrigger(double value) {
    return value.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
