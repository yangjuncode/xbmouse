/// Keyboard shortcut service.
/// Maps gamepad button presses to keyboard/mouse actions.

import 'package:flutter/foundation.dart';
import '../models/config_model.dart';
import 'uinput_service.dart';
import 'gamepad_service.dart';
import 'screen_service.dart';

class KeyboardService extends ChangeNotifier {
  final UinputService _uinput;
  final GamepadService _gamepad;
  final ScreenService _screen;

  ButtonMappings _mappings = ButtonMappings();
  bool _enabled = false;

  // Track button states for edge detection (press/release)
  final Map<String, bool> _previousStates = {};

  KeyboardService(this._uinput, this._gamepad, this._screen);

  bool get isEnabled => _enabled;

  void updateMappings(ButtonMappings mappings) {
    _mappings = mappings;
  }

  /// Start processing button events.
  void start() {
    if (_enabled) return;
    _enabled = true;

    _gamepad.addListener(_onGamepadUpdate);
    notifyListeners();
  }

  /// Stop processing button events.
  void stop() {
    _gamepad.removeListener(_onGamepadUpdate);
    _enabled = false;
    _previousStates.clear();
    notifyListeners();
  }

  void _onGamepadUpdate() {
    if (!_enabled) return;
    final state = _gamepad.state;

    // Check each button for press/release transitions
    _checkButton('a', state.buttonA);
    _checkButton('b', state.buttonB);
    _checkButton('x', state.buttonX);
    _checkButton('y', state.buttonY);
    _checkButton('lb', state.leftBumper);
    _checkButton('rb', state.rightBumper);
    _checkButton('start', state.buttonStart);
    _checkButton('back', state.buttonBack);
    _checkButton('lstick', state.leftStickButton);
    _checkButton('rstick', state.rightStickButton);
    _checkButton('dpad_up', state.dpadUp);
    _checkButton('dpad_down', state.dpadDown);
    _checkButton('dpad_left', state.dpadLeft);
    _checkButton('dpad_right', state.dpadRight);

    // Triggers as buttons (threshold-based)
    _checkButton('lt', state.leftTrigger > 0.5);
    _checkButton('rt', state.rightTrigger > 0.5);
  }

  void _checkButton(String buttonName, bool currentState) {
    final previousState = _previousStates[buttonName] ?? false;

    if (currentState && !previousState) {
      // Button just pressed
      _onButtonDown(buttonName);
    } else if (!currentState && previousState) {
      // Button just released
      _onButtonUp(buttonName);
    }

    _previousStates[buttonName] = currentState;
  }

  void _onButtonDown(String buttonName) {
    final action = _mappings.getMapping(buttonName);
    if (action.isEmpty) return;

    // Handle special actions
    if (action == '@SWITCH_SCREEN') {
      _screen.switchToNextScreen();
      return;
    }

    // Handle mouse button actions
    if (action.startsWith('BTN_')) {
      final keycode = LinuxKeyCodes.resolve(action);
      if (keycode != null) {
        _uinput.mouseDown(keycode);
      }
      return;
    }

    // Handle keyboard actions
    // Support combo keys with '+' separator (e.g., "Control_L+c")
    if (action.contains('+')) {
      final parts = action.split('+');
      final keycodes = parts
          .map((p) => LinuxKeyCodes.resolve(p.trim()))
          .where((k) => k != null)
          .map((k) => k!)
          .toList();
      if (keycodes.isNotEmpty) {
        // Press all keys in order
        for (final kc in keycodes) {
          _uinput.keyDown(kc);
        }
      }
    } else {
      final keycode = LinuxKeyCodes.resolve(action);
      if (keycode != null) {
        _uinput.keyDown(keycode);
      }
    }
  }

  void _onButtonUp(String buttonName) {
    final action = _mappings.getMapping(buttonName);
    if (action.isEmpty || action.startsWith('@')) return;

    // Handle mouse button release
    if (action.startsWith('BTN_')) {
      final keycode = LinuxKeyCodes.resolve(action);
      if (keycode != null) {
        _uinput.mouseUp(keycode);
      }
      return;
    }

    // Handle keyboard release
    if (action.contains('+')) {
      final parts = action.split('+');
      final keycodes = parts
          .map((p) => LinuxKeyCodes.resolve(p.trim()))
          .where((k) => k != null)
          .map((k) => k!)
          .toList();
      // Release in reverse order
      for (final kc in keycodes.reversed) {
        _uinput.keyUp(kc);
      }
    } else {
      final keycode = LinuxKeyCodes.resolve(action);
      if (keycode != null) {
        _uinput.keyUp(keycode);
      }
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
