import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/staggered_fade_in.dart';

/// شاشة "عن المطوّر": بتعرّف بمطور التطبيق، وبتفتح على آية قرآنية،
/// وبتدّي روابط التواصل الاجتماعي بتاعته.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: brightness == Brightness.dark
                ? AppColors.heroGradientDark
                : AppColors.heroGradientLight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
            children: [
              Row(
                children: [
                  _CircleBackButton(brightness: brightness),
                  Expanded(
                    child: Text(
                      'عن المطوّر',
                      textAlign: TextAlign.center,
                      style: AppTypography.title(brightness),
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
              SizedBox(height: 28.h),
              StaggeredFadeIn(
                index: 0,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 92.w,
                        height: 92.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: AppColors.goldGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accentGold.withValues(alpha: 0.35),
                              blurRadius: 26,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.code_rounded,
                          size: 42.sp,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text('تم التطوير بواسطة',
                          style: AppTypography.body(brightness)),
                      SizedBox(height: 4.h),
                      Text(
                        'Mahmoud Selmi',
                        style: AppTypography.headline(brightness).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              StaggeredFadeIn(
                index: 1,
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.glassFill(brightness),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: AppColors.glassBorder(brightness)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: AppColors.accentGoldSoft,
                        size: 26.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'وَقُلْ رَبِّ زِدْنِي عِلْمًا',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                          color: brightness == Brightness.dark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '[سورة طه - الآية: 114]',
                        style: AppTypography.caption(brightness).copyWith(
                          color: AppColors.accentGoldSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              StaggeredFadeIn(
                index: 2,
                child:
                    Text('تابعني على', style: AppTypography.title(brightness)),
              ),
              SizedBox(height: 14.h),
              StaggeredFadeIn(
                index: 3,
                child: _SocialTile(
                  brightness: brightness,
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF25D366),
                  title: 'واتساب',
                  subtitle: 'تواصل معايا مباشرة',
                  onTap: () => _open(
                    'https://api.whatsapp.com/send/?phone=201098494030&text&type=phone_number&app_absent=0',
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              StaggeredFadeIn(
                index: 4,
                child: _SocialTile(
                  brightness: brightness,
                  icon: Icons.business_center_rounded,
                  iconColor: const Color(0xFF0A66C2),
                  title: 'لينكدإن',
                  subtitle: 'صفحتي المهنية',
                  onTap: () => _open(
                    'https://www.linkedin.com/in/mahmoud-selmi-862162335',
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              StaggeredFadeIn(
                index: 5,
                child: _SocialTile(
                  brightness: brightness,
                  icon: Icons.data_object_rounded,
                  iconColor: brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  title: 'جيت هاب',
                  subtitle: 'مشاريعي وأكوادي',
                  onTap: () => _open('https://github.com/MahmoudSelmi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final Brightness brightness;

  const _CircleBackButton({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill(brightness),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Icon(Icons.arrow_forward_rounded, size: 20.sp),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final Brightness brightness;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SocialTile({
    required this.brightness,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassFill(brightness),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.body(brightness).copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                    Text(subtitle, style: AppTypography.caption(brightness)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: AppColors.primary, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}
