import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _base(Color color) =>
      GoogleFonts.ibmPlexSansArabic(color: color);

  static TextStyle displayLarge(Brightness b) => _base(_p(b)).copyWith(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle headline(Brightness b) => _base(_p(b)).copyWith(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle title(Brightness b) => _base(_p(b)).copyWith(
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle body(Brightness b) => _base(_p(b)).copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle caption(Brightness b) => _base(_s(b)).copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );

  static TextStyle label(Brightness b) => _base(_s(b)).copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );

  static TextStyle quranic(Brightness b) => GoogleFonts.amiri(
        color: _p(b),
        fontSize: 26.sp,
        fontWeight: FontWeight.w500,
        height: 1.9,
      );

  static Color _p(Brightness b) =>
      b == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  static Color _s(Brightness b) =>
      b == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
}
