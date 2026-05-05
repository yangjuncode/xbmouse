/// Screen management service.
/// Handles multi-monitor detection and cursor positioning across screens.

import 'package:flutter/foundation.dart';
import '../models/gamepad_state.dart';
import 'uinput_service.dart';

class ScreenService extends ChangeNotifier {
  final UinputService _uinput;

  List<ScreenInfo> _screens = [];
  int _currentScreenIndex = 0;

  ScreenService(this._uinput);

  List<ScreenInfo> get screens => _screens;
  int get currentScreenIndex => _currentScreenIndex;
  int get screenCount => _screens.length;

  ScreenInfo? get currentScreen =>
      _screens.isNotEmpty && _currentScreenIndex < _screens.length
          ? _screens[_currentScreenIndex]
          : null;

  /// Refresh screen layout information from native layer.
  Future<void> refreshScreenInfo() async {
    final rawScreens = await _uinput.getScreenInfo();
    _screens = rawScreens
        .map((m) => ScreenInfo.fromMap(m))
        .toList();

    // Sort by x position (left to right)
    _screens.sort((a, b) => a.x.compareTo(b.x));

    if (_currentScreenIndex >= _screens.length) {
      _currentScreenIndex = 0;
    }

    notifyListeners();
  }

  /// Switch mouse cursor to the next screen center (circular).
  Future<void> switchToNextScreen() async {
    if (_screens.length <= 1) return;

    _currentScreenIndex = (_currentScreenIndex + 1) % _screens.length;
    final screen = _screens[_currentScreenIndex];

    await _uinput.moveMouseAbsolute(screen.centerX, screen.centerY);
    notifyListeners();
  }

  /// Switch mouse cursor to a specific screen by index.
  Future<void> switchToScreen(int index) async {
    if (index < 0 || index >= _screens.length) return;

    _currentScreenIndex = index;
    final screen = _screens[_currentScreenIndex];

    await _uinput.moveMouseAbsolute(screen.centerX, screen.centerY);
    notifyListeners();
  }

  /// Get the screen index for a given stick (for dual-screen mode).
  /// Left stick = screen 0, Right stick = screen 1 (or last screen).
  int getScreenForStick(bool isLeftStick) {
    if (_screens.length < 2) return 0;
    return isLeftStick ? 0 : _screens.length - 1;
  }
}
