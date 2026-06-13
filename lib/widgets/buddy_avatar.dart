import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BuddyMood { idle, reading, happy }

/// A lightweight, dependency-free character for the "AI Story Buddy": a friendly
/// robot face built from shapes, with a gently spinning blue gear that breaks
/// into a big smile (and a happy bounce) on a correct answer.
class BuddyAvatar extends StatefulWidget {
  const BuddyAvatar({super.key, this.mood = BuddyMood.idle, this.size = 160});

  final BuddyMood mood;
  final double size;

  @override
  State<BuddyAvatar> createState() => _BuddyAvatarState();
}

class _BuddyAvatarState extends State<BuddyAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _gear = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
    lowerBound: 0.95,
    upperBound: 1.07,
    value: 1.0,
  );

  bool get _happy => widget.mood == BuddyMood.happy;

  @override
  void didUpdateWidget(covariant BuddyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_happy && oldWidget.mood != BuddyMood.happy) {
      _bounce
        ..reset()
        ..repeat(reverse: true);
    } else if (!_happy) {
      _bounce
        ..stop()
        ..value = 1.0;
    }
    // The gear spins faster while reading aloud.
    final reading = widget.mood == BuddyMood.reading;
    _gear.duration = Duration(seconds: reading ? 3 : 6);
  }

  @override
  void dispose() {
    _gear.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return ScaleTransition(
      scale: _bounce,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.30,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Eye(happy: _happy, size: size),
                  SizedBox(width: size * 0.16),
                  _Eye(happy: _happy, size: size),
                ],
              ),
            ),
            Positioned(
              top: size * 0.54,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _happy ? size * 0.34 : size * 0.22,
                height: _happy ? size * 0.18 : size * 0.055,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(size * 0.03),
                    bottom: Radius.circular(_happy ? size * 0.16 : size * 0.03),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size * 0.09,
              child: RotationTransition(
                turns: _gear,
                child: Icon(Icons.settings,
                    size: size * 0.17, color: AppColors.gear),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye({required this.happy, required this.size});

  final bool happy;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (happy) {
      // A "dome" shape reads as a cheerful, closed eye.
      return Container(
        width: size * 0.16,
        height: size * 0.09,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(size * 0.16)),
        ),
      );
    }
    return Container(
      width: size * 0.13,
      height: size * 0.13,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.06,
        height: size * 0.06,
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
