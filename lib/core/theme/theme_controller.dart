import 'package:flutter/material.dart';
import '../storage/local_storage.dart';
import 'app_colors.dart';
import 'app_palette.dart';

/// بيتحكم في اختيار المستخدم من بين الثيمات الأربعة، وبيحفظ اختياره
/// محليًا عشان يفضل شغال حتى لو قفل التطبيق وفتحه تاني.
class ThemeController extends ValueNotifier<AppThemeVariant> {
  ThemeController._() : super(_load()) {
    AppColors.setPalette(AppPalettes.of(value));
  }

  static final ThemeController instance = ThemeController._();

  static AppThemeVariant _load() {
    final raw = LocalStorage.instance.getString(StorageKeys.themeMode);
    return AppThemeVariant.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => AppThemeVariant.midnightGold,
    );
  }

  AppPalette get palette => AppPalettes.of(value);

  void setVariant(AppThemeVariant variant) {
    value = variant;
    AppColors.setPalette(AppPalettes.of(variant));
    LocalStorage.instance.setString(StorageKeys.themeMode, variant.name);
  }
}
