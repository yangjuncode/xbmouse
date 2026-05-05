/// XBMouse - Xbox Controller as Mouse for Linux
/// Main application entry point.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'theme/app_theme.dart';
import 'services/uinput_service.dart';
import 'services/gamepad_service.dart';
import 'services/mouse_service.dart';
import 'services/keyboard_service.dart';
import 'services/config_service.dart';
import 'services/screen_service.dart';
import 'services/tray_service.dart';
import 'pages/home_page.dart';
import 'pages/mouse_settings_page.dart';
import 'pages/key_mapping_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(700, 500),
    center: true,
    title: 'XBMouse',
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Create services
  final uinputService = UinputService();
  final gamepadService = GamepadService();
  final configService = ConfigService();
  final screenService = ScreenService(uinputService);
  final mouseService = MouseService(uinputService, gamepadService, screenService);
  final keyboardService = KeyboardService(uinputService, gamepadService, screenService);
  final trayService = TrayService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gamepadService),
        ChangeNotifierProvider.value(value: configService),
        ChangeNotifierProvider.value(value: screenService),
        ChangeNotifierProvider.value(value: mouseService),
        ChangeNotifierProvider.value(value: keyboardService),
        Provider.value(value: uinputService),
        Provider.value(value: trayService),
      ],
      child: const XBMouseApp(),
    ),
  );
}

class XBMouseApp extends StatefulWidget {
  const XBMouseApp({super.key});

  @override
  State<XBMouseApp> createState() => _XBMouseAppState();
}

class _XBMouseAppState extends State<XBMouseApp> with WindowListener {
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final configService = context.read<ConfigService>();
    final uinputService = context.read<UinputService>();
    final gamepadService = context.read<GamepadService>();
    final mouseService = context.read<MouseService>();
    final keyboardService = context.read<KeyboardService>();
    final screenService = context.read<ScreenService>();
    final trayService = context.read<TrayService>();

    // Load config
    await configService.load();

    // Initialize uinput virtual devices
    final uinputReady = await uinputService.init();
    if (!uinputReady) {
      print('WARNING: Failed to initialize uinput. '
          'Make sure you have write access to /dev/uinput.');
    }

    // Get screen info
    await screenService.refreshScreenInfo();

    // Apply config to services
    mouseService.updateConfig(configService.mouseConfig);
    keyboardService.updateMappings(configService.buttonMappings);

    // Start gamepad listening
    await gamepadService.startListening();

    // Auto-start if configured
    if (configService.appConfig.startEnabled) {
      mouseService.start();
      keyboardService.start();
    }

    // Initialize system tray
    try {
      await trayService.init();
      trayService.onShowWindow = () async {
        await windowManager.show();
        await windowManager.focus();
      };
      trayService.onToggleEnabled = () {
        if (mouseService.isEnabled) {
          mouseService.stop();
          keyboardService.stop();
        } else {
          mouseService.start();
          keyboardService.start();
        }
        trayService.setEnabled(mouseService.isEnabled);
      };
      trayService.onQuit = () async {
        mouseService.stop();
        keyboardService.stop();
        gamepadService.stopListening();
        await uinputService.dispose();
        trayService.dispose();
        await windowManager.destroy();
      };
    } catch (e) {
      print('System tray initialization failed: $e');
    }

    // Auto-minimize if configured
    if (configService.appConfig.startMinimized) {
      await windowManager.hide();
    }
  }

  @override
  void onWindowClose() async {
    // Minimize to tray instead of closing
    await windowManager.hide();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XBMouse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Row(
          children: [
            // Navigation Rail
            NavigationRail(
              selectedIndex: _currentPageIndex,
              onDestinationSelected: (index) {
                setState(() => _currentPageIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.xboxGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.gamepad,
                        color: AppTheme.xboxGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'XBMouse',
                      style: TextStyle(
                        color: AppTheme.xboxGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('主页'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.mouse_outlined),
                  selectedIcon: Icon(Icons.mouse),
                  label: Text('鼠标'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.keyboard_outlined),
                  selectedIcon: Icon(Icons.keyboard),
                  label: Text('按键'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Page content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildPage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentPageIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const MouseSettingsPage();
      case 2:
        return const KeyMappingPage();
      default:
        return const HomePage();
    }
  }
}
