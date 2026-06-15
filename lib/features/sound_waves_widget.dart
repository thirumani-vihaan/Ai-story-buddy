import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SoundWavesWidget extends StatefulWidget {
  const SoundWavesWidget({super.key, required this.animate});

  final bool animate;

  @override
  State<SoundWavesWidget> createState() => _SoundWavesWidgetState();
}

class _SoundWavesWidgetState extends State<SoundWavesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SoundWavesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && oldWidget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return CustomPaint(
            painter: _SoundWavesPainter(value: value),
            child: child,
          );
        },
      ),
    );
  }
}

class _SoundWavesPainter extends CustomPainter {
  _SoundWavesPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.18);
    final waveCount = 5;
    final barWidth = size.width / (waveCount * 2 - 1);
    for (var index = 0; index < waveCount; index++) {
      final phase = value * 2 * pi + index * 0.8;
      final normalized = (sin(phase) + 1) / 2;
      final height = lerpDouble(size.height * 0.25, size.height * 0.95, normalized)!;
      final dx = index * barWidth * 2;
      final rect = Rect.fromLTWH(dx, size.height - height, barWidth, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavesPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
