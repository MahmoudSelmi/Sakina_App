import 'package:flutter/material.dart';
import '../storage/local_storage.dart';

/// بيتحكم في وضع الثيم (فاتح/غامق/تلقائي) وبيحفظ اختيار المستخدم محليًا
/// عشان يفضل شغال حتى لو قفل التطبيق وفتحه تاني.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(_load());

  static final ThemeController instance = ThemeController._();

  static ThemeMode _load() {
    final raw = LocalStorage.instance.getString(StorageKeys.themeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  bool get isDark => value == ThemeMode.dark;

  void toggle() => set(isDark ? ThemeMode.light : ThemeMode.dark);

  void set(ThemeMode mode) {
    value = mode;
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    LocalStorage.instance.setString(StorageKeys.themeMode, raw);
  }
}
