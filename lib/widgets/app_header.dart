import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared top bar: a little brand mark, the app name, and an account button.
///
/// Pass [leading] (for example a back button on the quiz) to override the
/// start slot; otherwise just the brand mark and title are shown.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.leading});

  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? 16 : 4,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_stories_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'AI Story Buddy',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Account',
          icon: const Icon(Icons.account_circle_outlined,
              color: AppColors.primary),
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Hi, friend! 👋')),
              );
          },
        ),
      ],
    );
  }
}
