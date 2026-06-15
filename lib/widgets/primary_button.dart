import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large, friendly, rounded button used across the app.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.primary,
    this.foreground = Colors.white,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color foreground;

  /// When true, shows a spinner and ignores taps (e.g. while audio prepares).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          disabledForegroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
              ),
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
