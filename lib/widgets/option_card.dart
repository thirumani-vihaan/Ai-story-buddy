import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum OptionState { idle, wrong, correct, disabled }

/// A single tappable quiz answer. Looks like a rounded card with a radio on the
/// right; it turns green when correct, softly red when wrong, and **shakes**
/// (with a decaying horizontal wobble) each time it's chosen incorrectly.
class OptionCard extends StatefulWidget {
  const OptionCard({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.shouldShake = false,
    this.shakeTick = 0,
  });

  final String label;
  final OptionState state;
  final VoidCallback? onTap;

  /// Whether this card is the one that should react to a wrong answer.
  final bool shouldShake;

  /// Increments on every wrong attempt; a change re-triggers the shake.
  final int shakeTick;

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant OptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && widget.shakeTick != oldWidget.shakeTick) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // A decaying sine wave gives a natural "no, try again" wobble.
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 4) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    late final Color border;
    Color background = AppColors.card;
    late final Widget trailing;

    switch (widget.state) {
      case OptionState.correct:
        border = AppColors.success;
        background = AppColors.success.withValues(alpha: 0.08);
        trailing = const Icon(Icons.check_circle, color: AppColors.success);
        break;
      case OptionState.wrong:
        border = AppColors.wrong;
        background = AppColors.wrong.withValues(alpha: 0.07);
        trailing = const Icon(Icons.refresh_rounded, color: AppColors.wrong);
        break;
      case OptionState.disabled:
        border = AppColors.outline;
        trailing = const _Radio();
        break;
      case OptionState.idle:
        border = AppColors.outline;
        trailing = const _Radio();
        break;
    }

    final dimmed = widget.state == OptionState.disabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 2),
            ),
            child: Opacity(
              opacity: dimmed ? 0.55 : 1,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: 2),
      ),
    );
  }
}
