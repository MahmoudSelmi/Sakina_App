import 'package:flutter/material.dart';

/// بيرجع أيقونة مناسبة لاسم الرواية/الطريقة (تجويد - ترتيل - تعليمي - مجود..)
/// عشان كل قسم عند الشيخ يبان بشكل عصري ومميز بدل نص عادي بس.
class MoshafStyle {
  MoshafStyle._();

  static IconData iconFor(String name) {
    final n = name.trim();
    if (n.contains('تجويد')) return Icons.auto_awesome_rounded;
    if (n.contains('ترتيل')) return Icons.spa_rounded;
    if (n.contains('تعليم') || n.contains('معلم')) return Icons.school_rounded;
    if (n.contains('مجود')) return Icons.workspace_premium_rounded;
    if (n.contains('حدر') || n.contains('سريع')) return Icons.speed_rounded;
    if (n.contains('حفص')) return Icons.menu_book_rounded;
    if (n.contains('ورش')) return Icons.book_rounded;
    if (n.contains('قصر') || n.contains('مختصر')) return Icons.timer_rounded;
    return Icons.graphic_eq_rounded;
  }
}
