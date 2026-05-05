/// System tray service.
/// Manages the system tray icon and menu for background operation.

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService with TrayListener {
  VoidCallback? onShowWindow;
  VoidCallback? onToggleEnabled;
  VoidCallback? onQuit;

  bool _isEnabled = true;

  Future<void> init() async {
    trayManager.addListener(this);
    await _updateTrayIcon();
    await _updateTrayMenu();
  }

  void dispose() {
    trayManager.removeListener(this);
    trayManager.destroy();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    _updateTrayMenu();
  }

  Future<void> _updateTrayIcon() async {
    // Use a built-in icon or a simple one
    // For now we'll set the title - icon can be added later
    await trayManager.setIcon('assets/icon/tray_icon.png');
    await trayManager.setToolTip('XBMouse - Xbox Controller as Mouse');
  }

  Future<void> _updateTrayMenu() async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show',
          label: '显示窗口',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'toggle',
          label: _isEnabled ? '禁用手柄控制' : '启用手柄控制',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: '退出',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    onShowWindow?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        onShowWindow?.call();
        break;
      case 'toggle':
        onToggleEnabled?.call();
        break;
      case 'quit':
        onQuit?.call();
        break;
    }
  }
}
