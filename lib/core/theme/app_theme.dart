import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  static ThemeData forPalette(AppPalette palette) {
    final isDark = palette.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      scaffoldBackgroundColor: palette.bg,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
        primary: palette.primary,
        onPrimary: Colors.white,
        secondary: palette.accentGold,
        onSecondary: Colors.black,
        error: palette.error,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashColor: palette.primary.withOpacity(0.08),
      highlightColor: palette.primary.withOpacity(0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        thickness: 1,
      ),
    );
  }
}
