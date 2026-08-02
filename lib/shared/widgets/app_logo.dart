import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// شعار التطبيق: أيقونة محراب/هلال متدرجة + اسم "جَنَّتَكَ" بخط متدرج ذهبي.
/// المفروض تتكرر كعلامة تجارية موحّدة في أعلى الشاشة الرئيسية.
class AppLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showWordmark;

  const AppLogo({
    super.key,
    this.iconSize = 34,
    this.fontSize = 24,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    // بنقرا الثيم هنا (حتى من غير ما نستخدم القيمة) عشان الودجت يتربط
    // بالثيم الحالي ويتجدد لوحده لما المستخدم يغيّر الثيم، حتى لو كان
    // مستخدم كـ const جوه شاشة تانية.
    Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize.w,
          height: iconSize.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: AppColors.goldGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.mosque_rounded,
              size: iconSize.w * 0.56,
              color: Colors.black.withValues(alpha: 0.82),
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: 10.w),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: AppColors.goldGradient,
            ).createShader(bounds),
            child: Text(
              'جَنَّتَكَ',
              style: GoogleFonts.amiri(
                fontSize: fontSize.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
