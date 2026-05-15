/// Mouse settings page - sensitivity, acceleration, deadzone controls.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/mouse_service.dart';
import '../models/config_model.dart';
import '../theme/app_theme.dart';

class MouseSettingsPage extends StatelessWidget {
  final ScrollController? scrollController;
  const MouseSettingsPage({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConfigService, MouseService>(
      builder: (context, config, mouse, _) {
        final mouseConfig = config.mouseConfig;

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '鼠标设置',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '调整摇杆控制鼠标的行为参数',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              _buildSliderCard(
                context,
                icon: Icons.speed,
                title: '灵敏度',
                subtitle: '基础鼠标移动速度',
                value: mouseConfig.sensitivity,
                min: 0.1,
                max: 5.0,
                divisions: 49,
                displayValue: mouseConfig.sensitivity.toStringAsFixed(1),
                onChanged: (val) {
                  final newConfig = mouseConfig.copyWith(sensitivity: val);
                  config.updateMouseConfig(newConfig);
                  mouse.updateConfig(newConfig);
                },
              ),
              const SizedBox(height: 16),

              _buildSliderCard(
                context,
                icon: Icons.trending_up,
                title: '加速曲线',
                subtitle: '1.0=线性，2.0=二次方，越大越需要推满才快',
                value: mouseConfig.acceleration,
                min: 1.0,
                max: 4.0,
                divisions: 30,
                displayValue: mouseConfig.acceleration.toStringAsFixed(1),
                onChanged: (val) {
                  final newConfig = mouseConfig.copyWith(acceleration: val);
                  config.updateMouseConfig(newConfig);
                  mouse.updateConfig(newConfig);
                },
              ),
              const SizedBox(height: 16),

              _buildSliderCard(
                context,
                icon: Icons.filter_center_focus,
                title: '死区',
                subtitle: '忽略摇杆微小漂移的阈值',
                value: mouseConfig.deadzone,
                min: 0.0,
                max: 0.5,
                divisions: 50,
                displayValue: mouseConfig.deadzone.toStringAsFixed(2),
                onChanged: (val) {
                  final newConfig = mouseConfig.copyWith(deadzone: val);
                  config.updateMouseConfig(newConfig);
                  mouse.updateConfig(newConfig);
                },
              ),

              // Right stick fine-positioning (single-screen mode only)
              if (!mouseConfig.dualScreen) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gamepad, color: AppTheme.accentOrange, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '单屏模式摇杆说明',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  Text(
                                    '左摇杆：正常速度大范围移动 · 右摇杆：慢速精确定位',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSliderCard(
                  context,
                  icon: Icons.ads_click,
                  title: '右摇杆精确灵敏度',
                  subtitle: '单屏模式下右摇杆的速度倍率（相对于左摇杆）',
                  value: mouseConfig.rightStickSensitivity,
                  min: 0.05,
                  max: 1.0,
                  divisions: 19,
                  displayValue: '${(mouseConfig.rightStickSensitivity * 100).round()}%',
                  onChanged: (val) {
                    final newConfig = mouseConfig.copyWith(rightStickSensitivity: val);
                    config.updateMouseConfig(newConfig);
                    mouse.updateConfig(newConfig);
                  },
                ),
              ],

              const SizedBox(height: 32),

              _buildAccelerationPreview(context, mouseConfig),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.xboxGreen, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(subtitle, style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayValue,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.xboxGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  /// Visual preview of the acceleration curve.
  Widget _buildAccelerationPreview(BuildContext context, MouseConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppTheme.xboxGreen, size: 22),
                const SizedBox(width: 12),
                Text(
                  '加速曲线预览',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _AccelerationCurvePainter(
                  acceleration: config.acceleration,
                  deadzone: config.deadzone,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('摇杆输入 →', style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
                Text('← 鼠标速度', style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccelerationCurvePainter extends CustomPainter {
  final double acceleration;
  final double deadzone;

  _AccelerationCurvePainter({required this.acceleration, required this.deadzone});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    // Draw grid
    for (int i = 0; i <= 4; i++) {
      double x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw deadzone region
    final deadzonePaint = Paint()
      ..color = AppTheme.accentOrange.withValues(alpha: 0.1);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * deadzone, size.height),
      deadzonePaint,
    );

    // Draw curve
    final curvePaint = Paint()
      ..color = AppTheme.xboxGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool started = false;

    for (int i = 0; i <= 100; i++) {
      double input = i / 100.0;
      double output;

      if (input < deadzone) {
        output = 0;
      } else {
        double normalized = (input - deadzone) / (1.0 - deadzone);
        output = _pow(normalized, acceleration);
      }

      double x = size.width * input;
      double y = size.height * (1.0 - output);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, curvePaint);

    // Draw linear reference line
    final refPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      refPaint,
    );
  }

  double _pow(double base, double exponent) {
    if (base <= 0) return 0;
    return base == 1 ? 1 : _expApprox(exponent * _logApprox(base));
  }

  // Simple approximations to avoid dart:math import in painter
  double _expApprox(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  double _logApprox(double x) {
    if (x <= 0) return -100;
    double result = 0;
    double y = (x - 1) / (x + 1);
    double y2 = y * y;
    double term = y;
    for (int i = 0; i < 20; i++) {
      result += term / (2 * i + 1);
      term *= y2;
    }
    return 2 * result;
  }

  @override
  bool shouldRepaint(covariant _AccelerationCurvePainter oldDelegate) {
    return oldDelegate.acceleration != acceleration || oldDelegate.deadzone != deadzone;
  }
}
