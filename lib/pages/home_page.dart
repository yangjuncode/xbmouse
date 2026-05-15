/// Home page - main dashboard showing gamepad status and controls.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamepad_service.dart';
import '../services/mouse_service.dart';
import '../services/keyboard_service.dart';
import '../services/config_service.dart';
import '../services/screen_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  final ScrollController? scrollController;
  const HomePage({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer4<GamepadService, MouseService, KeyboardService, ConfigService>(
      builder: (context, gamepad, mouse, keyboard, config, _) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context, gamepad, mouse, keyboard),
              const SizedBox(height: 24),
              _buildControlCard(context, mouse, keyboard, config),
              const SizedBox(height: 24),
              _buildGamepadVisualizer(context, gamepad),
              const SizedBox(height: 24),
              _buildScreenInfoCard(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, GamepadService gamepad,
      MouseService mouse, KeyboardService keyboard) {
    final isConnected = gamepad.isConnected;
    final isActive = mouse.isEnabled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? AppTheme.xboxGreen : AppTheme.accentOrange,
                    boxShadow: [
                      BoxShadow(
                        color: (isConnected ? AppTheme.xboxGreen : AppTheme.accentOrange)
                            .withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isConnected ? '手柄已连接' : '等待手柄连接...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isConnected && gamepad.state.gamepadInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'ID: ${gamepad.state.gamepadInfo!.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip(
                  context,
                  icon: Icons.mouse,
                  label: '鼠标',
                  active: isActive,
                ),
                const SizedBox(width: 12),
                _buildStatusChip(
                  context,
                  icon: Icons.keyboard,
                  label: '快捷键',
                  active: keyboard.isEnabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.xboxGreen.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppTheme.xboxGreen : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16,
            color: active ? AppTheme.xboxGreen : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? AppTheme.xboxGreen : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard(BuildContext context, MouseService mouse,
      KeyboardService keyboard, ConfigService config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '控制面板',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSwitchTile(
              context,
              icon: Icons.mouse,
              title: '鼠标模拟',
              subtitle: '摇杆控制鼠标移动，扳机键点击',
              value: mouse.isEnabled,
              onChanged: (val) {
                if (val) {
                  mouse.start();
                  keyboard.start();
                } else {
                  mouse.stop();
                  keyboard.stop();
                }
              },
            ),
            const Divider(height: 32),
            _buildSwitchTile(
              context,
              icon: Icons.monitor,
              title: '双屏模式',
              subtitle: '左摇杆控制屏幕1，右摇杆控制屏幕2',
              value: config.mouseConfig.dualScreen,
              onChanged: (val) {
                final newConfig = config.mouseConfig.copyWith(dualScreen: val);
                config.updateMouseConfig(newConfig);
                mouse.updateConfig(newConfig);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.xboxGreen, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildGamepadVisualizer(BuildContext context, GamepadService gamepad) {
    if (!gamepad.isConnected) return const SizedBox.shrink();

    final state = gamepad.state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '手柄状态',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStickVisual(
                    context, '左摇杆',
                    state.leftStickX, state.leftStickY,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildStickVisual(
                    context, '右摇杆',
                    state.rightStickX, state.rightStickY,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildButtonIndicator('A', state.buttonA),
                _buildButtonIndicator('B', state.buttonB),
                _buildButtonIndicator('X', state.buttonX),
                _buildButtonIndicator('Y', state.buttonY),
                _buildButtonIndicator('LB', state.leftBumper),
                _buildButtonIndicator('RB', state.rightBumper),
                _buildButtonIndicator('Start', state.buttonStart),
                _buildButtonIndicator('Back', state.buttonBack),
                _buildButtonIndicator('↑', state.dpadUp),
                _buildButtonIndicator('↓', state.dpadDown),
                _buildButtonIndicator('←', state.dpadLeft),
                _buildButtonIndicator('→', state.dpadRight),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTriggerBar(context, 'LT', state.leftTrigger),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTriggerBar(context, 'RT', state.rightTrigger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickVisual(BuildContext context, String label, double x, double y) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceElevated,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 50 + x * 35 - 8,
                top: 50 + y * 35 - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.xboxGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.xboxGreen.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildButtonIndicator(String label, bool pressed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: pressed
            ? AppTheme.xboxGreen.withValues(alpha: 0.3)
            : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pressed ? AppTheme.xboxGreen : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: pressed ? AppTheme.xboxGreen : AppTheme.textSecondary,
          fontWeight: pressed ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTriggerBar(BuildContext context, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.surfaceElevated,
            color: AppTheme.xboxGreen,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenInfoCard(BuildContext context) {
    return Consumer<ScreenService>(
      builder: (context, screen, _) {
        if (screen.screens.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '显示器信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => screen.refreshScreenInfo(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('刷新'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...screen.screens.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.index == screen.currentScreenIndex
                              ? AppTheme.xboxGreen
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '屏幕 ${s.index + 1}: ${s.width}×${s.height}',
                        style: TextStyle(
                          color: s.index == screen.currentScreenIndex
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                      if (s.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.xboxGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '主屏',
                            style: TextStyle(
                              color: AppTheme.xboxGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }
}
