import 'package:flutter/material.dart';
import 'app_palette.dart';

/// واجهة الألوان اللي بيستخدمها كل التطبيق. القيم هنا مش ثابتة - بترجع
/// لون الثيم المفعّل حاليًا [_current]، فلما [setPalette] تتنادى (لما
/// المستخدم يغيّر الثيم) كل مكان في التطبيق بيتلوّن صح تلقائيًا من غير
/// ما نحتاج نعدّل أي شاشة تانية.
class AppColors {
  AppColors._();

  static AppPalette _current = AppPalettes.midnightGold;

  static void setPalette(AppPalette palette) => _current = palette;
  static AppPalette get currentPalette => _current;

  static Color get primary => _current.primary;
  static Color get primaryLight => _current.primaryLight;
  static Color get accentGold => _current.accentGold;
  static Color get accentGoldSoft => _current.accentGoldSoft;
  static Color get error => _current.error;
  static Color get success => _current.success;

  static Color get darkSurfaceElevated => _current.surfaceElevated;
  static Color get lightSurface => _current.surface;

  static Color get textPrimaryDark => _current.textPrimary;
  static Color get textPrimaryLight => _current.textPrimary;
  static Color get textSecondaryDark => _current.textSecondary;
  static Color get textSecondaryLight => _current.textSecondary;

  static List<Color> get heroGradientDark => _current.heroGradient;
  static List<Color> get heroGradientLight => _current.heroGradient;

  static List<Color> get goldGradient => _current.goldGradient;

  static Color glassFill(Brightness b) => _current.glassFill();
  static Color glassBorder(Brightness b) => _current.glassBorder();
}
