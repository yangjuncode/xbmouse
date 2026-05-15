/// Key mapping configuration page.
/// Allows users to view and edit gamepad button to keyboard/mouse action mappings.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/keyboard_service.dart';
import '../services/uinput_service.dart';
import '../models/config_model.dart';
import '../theme/app_theme.dart';

class KeyMappingPage extends StatelessWidget {
  final ScrollController? scrollController;
  const KeyMappingPage({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigService>(
      builder: (context, config, _) {
        final entries = config.buttonMappings.toEntryList();

        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '按键映射',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '配置手柄按钮对应的键盘/鼠标动作',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _resetToDefaults(context, config),
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('重置默认'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Group: Face buttons
              _buildSection(context, '面板按钮', entries.where(
                (e) => ['a', 'b', 'x', 'y'].contains(e.gamepadButton)).toList(),
                config),

              const SizedBox(height: 16),

              // Group: Bumpers & Triggers
              _buildSection(context, '肩键 & 扳机', entries.where(
                (e) => ['lb', 'rb', 'lt', 'rt'].contains(e.gamepadButton)).toList(),
                config),

              const SizedBox(height: 16),

              // Group: D-pad
              _buildSection(context, '方向键', entries.where(
                (e) => e.gamepadButton.startsWith('dpad')).toList(),
                config),

              const SizedBox(height: 16),

              // Group: Menu & Sticks
              _buildSection(context, '菜单 & 摇杆按压', entries.where(
                (e) => ['start', 'back', 'lstick', 'rstick'].contains(e.gamepadButton)).toList(),
                config),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title,
      List<KeyMappingEntry> entries, ConfigService config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.xboxGreen,
              ),
            ),
            const SizedBox(height: 16),
            ...entries.map((entry) => _buildMappingTile(context, entry, config)),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingTile(BuildContext context, KeyMappingEntry entry,
      ConfigService config) {
    final displayName = gamepadButtonDisplayNames[entry.gamepadButton] ?? entry.gamepadButton;
    final actionName = LinuxKeyCodes.displayName(entry.keyAction);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _showEditDialog(context, entry, config),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: entry.isSpecialAction
                        ? AppTheme.accentOrange.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    if (entry.isMouseButton)
                      const Icon(Icons.mouse, size: 14, color: AppTheme.xboxGreen)
                    else if (entry.isSpecialAction)
                      const Icon(Icons.monitor, size: 14, color: AppTheme.accentOrange)
                    else if (!entry.isDisabled)
                      const Icon(Icons.keyboard, size: 14, color: AppTheme.textSecondary),
                    if (!entry.isDisabled) const SizedBox(width: 8),
                    Text(
                      actionName,
                      style: TextStyle(
                        color: entry.isDisabled
                            ? AppTheme.textSecondary.withValues(alpha: 0.5)
                            : AppTheme.textPrimary,
                        fontFamily: entry.isSpecialAction ? null : 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, KeyMappingEntry entry,
      ConfigService config) {
    final controller = TextEditingController(text: entry.keyAction);
    final displayName = gamepadButtonDisplayNames[entry.gamepadButton] ?? entry.gamepadButton;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: Text('编辑映射 - $displayName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入键名（如 Return, Escape, Control_L+c）',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '键名或留空禁用',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '特殊值: BTN_LEFT, BTN_RIGHT, BTN_MIDDLE, @SWITCH_SCREEN',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildQuickPick(controller, 'Return'),
                _buildQuickPick(controller, 'Escape'),
                _buildQuickPick(controller, 'Tab'),
                _buildQuickPick(controller, 'BackSpace'),
                _buildQuickPick(controller, 'Space'),
                _buildQuickPick(controller, 'Prior'),
                _buildQuickPick(controller, 'Next'),
                _buildQuickPick(controller, 'Control_L'),
                _buildQuickPick(controller, 'Alt_L'),
                _buildQuickPick(controller, 'Super_L'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              config.updateButtonMapping(entry.gamepadButton, controller.text.trim());
              // Update keyboard service
              final keyboardService = context.read<KeyboardService>();
              keyboardService.updateMappings(config.buttonMappings);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPick(TextEditingController controller, String value) {
    return ActionChip(
      label: Text(value, style: const TextStyle(fontSize: 11)),
      onPressed: () => controller.text = value,
      backgroundColor: AppTheme.surfaceElevated,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    );
  }

  void _resetToDefaults(BuildContext context, ConfigService config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('重置按键映射'),
        content: const Text('确定要将所有按键映射恢复为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            onPressed: () {
              config.updateButtonMappings(ButtonMappings());
              final keyboardService = context.read<KeyboardService>();
              keyboardService.updateMappings(config.buttonMappings);
              Navigator.pop(ctx);
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}
