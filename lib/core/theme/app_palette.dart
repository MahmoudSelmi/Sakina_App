import 'package:flutter/material.dart';

/// كل الألوان اللي بتكوّن ثيم كامل. كل ثيم من الأربعة عنده نفس المفاهيم
/// (لون أساسي، لون تمييز ذهبي، خلفية متدرجة، ألوان نصوص..) بس بقيمه
/// الخاصة، عشان يبقى متكامل وواضح بصريًا.
class AppPalette {
  final String id;
  final String label;
  final String subtitle;
  final Brightness brightness;

  final Color primary;
  final Color primaryLight;
  final Color accentGold;
  final Color accentGoldSoft;
  final Color error;
  final Color success;

  final Color bg;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;

  final List<Color> heroGradient;

  /// اللون الأساسي اللي بيتحط عليه شفافية خفيفة عشان يبان زجاجي
  /// (أبيض في الثيمات الغامقة، أسود في الفاتحة).
  final Color glassBase;

  const AppPalette({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.brightness,
    required this.primary,
    required this.primaryLight,
    required this.accentGold,
    required this.accentGoldSoft,
    required this.error,
    required this.success,
    required this.bg,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.heroGradient,
    required this.glassBase,
  });

  List<Color> get goldGradient => [accentGoldSoft, accentGold];

  Color glassFill() => glassBase.withOpacity(0.06);
  Color glassBorder() => glassBase.withOpacity(0.10);

  /// أول لونين للمعاينة الصغيرة في شاشة اختيار الثيم.
  List<Color> get previewColors => [bg, primary];
}

/// أسماء الثيمات الأربعة المتاحة.
enum AppThemeVariant { midnightGold, royalEmerald, fajr, desertSand }

class AppPalettes {
  AppPalettes._();

  /// الثيم الافتراضي - غامق بلمسة ذهبية وخضراء هادية.
  static const AppPalette midnightGold = AppPalette(
    id: 'midnightGold',
    label: 'ذهبي الليل',
    subtitle: 'الثيم الأساسي - هدوء وفخامة',
    brightness: Brightness.dark,
    primary: Color(0xFF0F7A5C),
    primaryLight: Color(0xFF2FAE85),
    accentGold: Color(0xFFD4AF37),
    accentGoldSoft: Color(0xFFE8C766),
    error: Color(0xFFE0574B),
    success: Color(0xFF3BA776),
    bg: Color(0xFF0A0E10),
    surface: Color(0xFF14191B),
    surfaceElevated: Color(0xFF1C2224),
    card: Color(0xFF1A2022),
    textPrimary: Color(0xFFF5F5F0),
    textSecondary: Color(0xFFA3ACA9),
    heroGradient: [Color(0xFF0F2B22), Color(0xFF0A0E10)],
    glassBase: Colors.white,
  );

  /// ثيم غامق تاني بروح ملكية - سماء ليلية بنفسجية وتركواز لامع.
  static const AppPalette royalEmerald = AppPalette(
    id: 'royalEmerald',
    label: 'زمردي ملكي',
    subtitle: 'ليل بنفسجي بلمعة تركوازية',
    brightness: Brightness.dark,
    primary: Color(0xFF14B8A6),
    primaryLight: Color(0xFF5EEAD4),
    accentGold: Color(0xFFCBA6DC),
    accentGoldSoft: Color(0xFFE7CFF2),
    error: Color(0xFFE0577A),
    success: Color(0xFF2FD4A8),
    bg: Color(0xFF120E1F),
    surface: Color(0xFF1A1430),
    surfaceElevated: Color(0xFF231B3D),
    card: Color(0xFF20193A),
    textPrimary: Color(0xFFF3F0FA),
    textSecondary: Color(0xFFAFA3C9),
    heroGradient: [Color(0xFF241A3F), Color(0xFF120E1F)],
    glassBase: Colors.white,
  );

  /// ثيم فاتح هادئ - كريمي بارد بلمسة خضراء زي هدوء الفجر.
  static const AppPalette fajr = AppPalette(
    id: 'fajr',
    label: 'فجر',
    subtitle: 'صفاء فاتح وهدوء الصبح',
    brightness: Brightness.light,
    primary: Color(0xFF0F7A5C),
    primaryLight: Color(0xFF2FAE85),
    accentGold: Color(0xFFD4AF37),
    accentGoldSoft: Color(0xFFE8C766),
    error: Color(0xFFE0574B),
    success: Color(0xFF3BA776),
    bg: Color(0xFFF7F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    card: Color(0xFFF1EFE9),
    textPrimary: Color(0xFF14191B),
    textSecondary: Color(0xFF5C6663),
    heroGradient: [Color(0xFFE7F3EC), Color(0xFFF7F6F2)],
    glassBase: Colors.black,
  );

  /// ثيم فاتح دافئ - رملي وتراكوتا زي دفا الصحراء.
  static const AppPalette desertSand = AppPalette(
    id: 'desertSand',
    label: 'الصحراء',
    subtitle: 'دفء رملي وتراكوتا',
    brightness: Brightness.light,
    primary: Color(0xFFB1552D),
    primaryLight: Color(0xFFD98552),
    accentGold: Color(0xFFC9962C),
    accentGoldSoft: Color(0xFFE0BB6B),
    error: Color(0xFFC1443A),
    success: Color(0xFF4C8B5A),
    bg: Color(0xFFFBF1E1),
    surface: Color(0xFFFFFDF8),
    surfaceElevated: Color(0xFFFFFDF8),
    card: Color(0xFFF3E3C8),
    textPrimary: Color(0xFF3A2A1D),
    textSecondary: Color(0xFF8A7460),
    heroGradient: [Color(0xFFF3E3C8), Color(0xFFFBF1E1)],
    glassBase: Colors.black,
  );

  static const Map<AppThemeVariant, AppPalette> all = {
    AppThemeVariant.midnightGold: midnightGold,
    AppThemeVariant.royalEmerald: royalEmerald,
    AppThemeVariant.fajr: fajr,
    AppThemeVariant.desertSand: desertSand,
  };

  static AppPalette of(AppThemeVariant variant) => all[variant]!;
}
