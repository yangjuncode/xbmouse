/// TOML configuration service.
/// Reads/writes XBMouse config from ~/.config/xbmouse/config.toml

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:toml/toml.dart';
import '../models/config_model.dart';

class ConfigService extends ChangeNotifier {
  XBMouseConfig _config = XBMouseConfig();
  String? _configPath;

  XBMouseConfig get config => _config;
  MouseConfig get mouseConfig => _config.mouse;
  ButtonMappings get buttonMappings => _config.buttons;
  AppConfig get appConfig => _config.app;

  /// Get the config file path.
  String get configPath {
    if (_configPath != null) return _configPath!;

    final home = Platform.environment['HOME'] ?? '/tmp';
    _configPath = '$home/.config/xbmouse/config.toml';
    return _configPath!;
  }

  /// Load configuration from TOML file, or create defaults.
  Future<void> load() async {
    final file = File(configPath);

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final doc = TomlDocument.parse(content);
        final map = doc.toMap();
        _config = XBMouseConfig.fromMap(map);
        print('Config loaded from: $configPath');
      } catch (e) {
        print('Error loading config, using defaults: $e');
        _config = XBMouseConfig();
      }
    } else {
      print('No config file found, creating defaults at: $configPath');
      _config = XBMouseConfig();
      await save();
    }

    notifyListeners();
  }

  /// Save current configuration to TOML file.
  Future<void> save() async {
    final file = File(configPath);

    // Ensure directory exists
    await file.parent.create(recursive: true);

    final content = _generateToml();
    await file.writeAsString(content);
    print('Config saved to: $configPath');
  }

  /// Update mouse configuration.
  void updateMouseConfig(MouseConfig config) {
    _config.mouse = config;
    notifyListeners();
    save();
  }

  /// Update a single button mapping.
  void updateButtonMapping(String buttonName, String keyAction) {
    _config.buttons.setMapping(buttonName, keyAction);
    notifyListeners();
    save();
  }

  /// Update all button mappings.
  void updateButtonMappings(ButtonMappings mappings) {
    _config.buttons = mappings;
    notifyListeners();
    save();
  }

  /// Update app configuration.
  void updateAppConfig(AppConfig config) {
    _config.app = config;
    notifyListeners();
    save();
  }

  /// Generate TOML string from current config.
  String _generateToml() {
    final mouse = _config.mouse;
    final buttons = _config.buttons;
    final app = _config.app;

    return '''[mouse]
sensitivity = ${mouse.sensitivity}
acceleration = ${mouse.acceleration}
deadzone = ${mouse.deadzone}
dual_screen = ${mouse.dualScreen}
right_stick_sensitivity = ${mouse.rightStickSensitivity}

[buttons]
a = "${buttons.a}"
b = "${buttons.b}"
x = "${buttons.x}"
y = "${buttons.y}"
lb = "${buttons.lb}"
rb = "${buttons.rb}"
start = "${buttons.start}"
back = "${buttons.back}"
lstick = "${buttons.lstick}"
rstick = "${buttons.rstick}"

[dpad]
up = "${buttons.dpadUp}"
down = "${buttons.dpadDown}"
left = "${buttons.dpadLeft}"
right = "${buttons.dpadRight}"

[triggers]
lt = "${buttons.lt}"
rt = "${buttons.rt}"

[app]
start_enabled = ${app.startEnabled}
start_minimized = ${app.startMinimized}
''';
  }

  /// Export config to a specific file path.
  Future<void> exportTo(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(_generateToml());
  }

  /// Import config from a specific file path.
  Future<bool> importFrom(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final doc = TomlDocument.parse(content);
      final map = doc.toMap();
      _config = XBMouseConfig.fromMap(map);
      await save();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error importing config: $e');
      return false;
    }
  }
}
