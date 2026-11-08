import 'package:flutter/material.dart';
import 'package:flutter_proj/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static ThemeData light({bool useBrandFont = false}) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      splashFactory: NoSplash.splashFactory,
    );
    final family = useBrandFont ? GoogleFonts.notoSansKr().fontFamily : null;
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: family,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
