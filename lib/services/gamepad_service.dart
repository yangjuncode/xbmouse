// Gamepad input service using the gamepads package.
// Listens for Xbox controller events and exposes them as streams.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';
import '../models/gamepad_state.dart';

class GamepadService extends ChangeNotifier {
  StreamSubscription<NormalizedGamepadEvent>? _subscription;
  Timer? _refreshTimer;
  final GamepadState state = GamepadState();
  bool _listening = false;

  bool get isListening => _listening;
  bool get isConnected => state.connected;

  /// Start listening to gamepad events.
  Future<void> startListening() async {
    if (_listening) return;
    _listening = true;

    await _refreshConnectedGamepads();
    _startRefreshTimer();
    _subscription = Gamepads.normalizedEvents.listen(_handleEvent);
    notifyListeners();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_listening || state.connected) {
        _refreshTimer?.cancel();
        _refreshTimer = null;
        return;
      }

      final changed = await _refreshConnectedGamepads();
      if (changed) {
        notifyListeners();
      }
    });
  }

  Future<bool> _refreshConnectedGamepads() async {
    try {
      final gamepads = await Gamepads.list();
      final connected = gamepads.where((gamepad) {
        return !_isVirtualGamepadId(gamepad.id) &&
            !_isVirtualGamepadId(gamepad.name);
      }).toList();

      if (connected.isEmpty) {
        return false;
      }

      final gamepad = connected.first;
      state.connected = true;
      state.gamepadInfo = GamepadInfo(id: gamepad.id, name: gamepad.name);
      return true;
    } catch (_) {
      // Keep waiting for live events if enumeration fails.
      return false;
    }
  }

  bool _isVirtualGamepadId(String value) {
    return value.contains('1234:5678') ||
        value.contains('1234:5679') ||
        value.contains('XBMouse');
  }

  /// Stop listening to gamepad events.
  void stopListening() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    _subscription = null;
    _refreshTimer = null;
    _listening = false;
    state.reset();
    notifyListeners();
  }

  void _handleEvent(NormalizedGamepadEvent event) {
    // Ignore our own virtual mouse/keyboard devices
    if (_isVirtualGamepadId(event.gamepadId)) {
      return;
    }

    // Mark as connected when we receive any event
    if (!state.connected) {
      state.connected = true;
      state.gamepadInfo = GamepadInfo(
        id: event.gamepadId,
        name: event.gamepadId,
      );
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }

    // Map the key/axis from the event
    handleNormalizedEvent(event);
    notifyListeners();
  }

  @visibleForTesting
  void handleNormalizedEvent(NormalizedGamepadEvent event) {
    final value = event.value.clamp(-1.0, 1.0).toDouble();
    final axis = event.axis;
    if (axis != null) {
      switch (axis) {
        case GamepadAxis.leftStickX:
          state.leftStickX = value;
          break;
        case GamepadAxis.leftStickY:
          state.leftStickY = -value;
          break;
        case GamepadAxis.rightStickX:
          state.rightStickX = value;
          break;
        case GamepadAxis.rightStickY:
          state.rightStickY = -value;
          break;
        case GamepadAxis.leftTrigger:
          state.leftTrigger = event.value.clamp(0.0, 1.0).toDouble();
          break;
        case GamepadAxis.rightTrigger:
          state.rightTrigger = event.value.clamp(0.0, 1.0).toDouble();
          break;
      }
      return;
    }

    final pressed = event.value > 0.5;
    switch (event.button) {
      case GamepadButton.a:
        state.buttonA = pressed;
        break;
      case GamepadButton.b:
        state.buttonB = pressed;
        break;
      case GamepadButton.x:
        state.buttonX = pressed;
        break;
      case GamepadButton.y:
        state.buttonY = pressed;
        break;
      case GamepadButton.leftBumper:
        state.leftBumper = pressed;
        break;
      case GamepadButton.rightBumper:
        state.rightBumper = pressed;
        break;
      case GamepadButton.back:
        state.buttonBack = pressed;
        break;
      case GamepadButton.start:
        state.buttonStart = pressed;
        break;
      case GamepadButton.leftStick:
        state.leftStickButton = pressed;
        break;
      case GamepadButton.rightStick:
        state.rightStickButton = pressed;
        break;
      case GamepadButton.dpadUp:
        state.dpadUp = pressed;
        break;
      case GamepadButton.dpadDown:
        state.dpadDown = pressed;
        break;
      case GamepadButton.dpadLeft:
        state.dpadLeft = pressed;
        break;
      case GamepadButton.dpadRight:
        state.dpadRight = pressed;
        break;
      case GamepadButton.leftTrigger:
        state.leftTrigger = pressed ? 1.0 : 0.0;
        break;
      case GamepadButton.rightTrigger:
        state.rightTrigger = pressed ? 1.0 : 0.0;
        break;
      case GamepadButton.home:
      case GamepadButton.touchpad:
      case null:
        break;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
