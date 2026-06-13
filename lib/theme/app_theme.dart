import 'package:flutter/material.dart';

/// Central design tokens for AI Story Buddy.
///
/// The palette and typography come straight from the design "Style Guidance"
/// notes: primary #6F2BC2, deep #36165E, Poppins type, joyful + warm tone for
/// children aged 6-10.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6F2BC2);
  static const Color primaryDark = Color(0xFF36165E);
  static const Color accent = Color(0xFFFFC542);
  static const Color background = Color(0xFFF7F5FC);
  static const Color card = Colors.white;
  static const Color textStrong = Color(0xFF231942);
  static const Color textSoft = Color(0xFF6B6485);
  static const Color success = Color(0xFF2BB673);
  static const Color wrong = Color(0xFFE57373);
  static const Color outline = Color(0xFFE6E1F2);

  /// Pip's bright blue chest gear from the story.
  static const Color gear = Color(0xFF2F80ED);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(surface: AppColors.background),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textStrong,
        displayColor: AppColors.textStrong,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.primaryDark,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
