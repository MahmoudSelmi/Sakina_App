import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F7A5C);
  static const Color primaryLight = Color(0xFF2FAE85);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentGoldSoft = Color(0xFFE8C766);

  static const Color darkBg = Color(0xFF0A0E10);
  static const Color darkSurface = Color(0xFF14191B);
  static const Color darkSurfaceElevated = Color(0xFF1C2224);
  static const Color darkCard = Color(0xFF1A2022);

  static const Color lightBg = Color(0xFFF7F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1EFE9);

  static const Color textPrimaryDark = Color(0xFFF5F5F0);
  static const Color textSecondaryDark = Color(0xFFA3ACA9);
  static const Color textPrimaryLight = Color(0xFF14191B);
  static const Color textSecondaryLight = Color(0xFF5C6663);

  static const Color error = Color(0xFFE0574B);
  static const Color success = Color(0xFF3BA776);

  static const List<Color> heroGradientDark = [
    Color(0xFF0F2B22),
    Color(0xFF0A0E10),
  ];

  static const List<Color> heroGradientLight = [
    Color(0xFFE7F3EC),
    Color(0xFFF7F6F2),
  ];

  static const List<Color> goldGradient = [accentGoldSoft, accentGold];

  static Color glassFill(Brightness b) =>
      (b == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.06);

  static Color glassBorder(Brightness b) =>
      (b == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.10);
}
