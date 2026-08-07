import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../../shared/widgets/theme_picker_sheet.dart';
import '../../about/presentation/about_screen.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/sign_in_screen.dart';
import '../../downloads/presentation/downloads_screen.dart';
import '../../khatma/presentation/khatma_screen.dart';
import '../../playlists/presentation/playlists_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// شاشة "البروفايل" - المكان الثابت لكل حاجة شخصية: تسجيل الدخول
/// الاختياري، الثيم، التحميلات، الإعدادات، وختمتك - وتحت في مكانه الثابت
/// معلومات المطوّر.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: brightness == Brightness.dark
                    ? AppColors.heroGradientDark
                    : AppColors.heroGradientLight,
              ),
            ),
          ),
          // توهج ذهبي هادي خلف الهيدر بيتنفّس ببطء، عشان الشاشة تحس إنها
          // حية مش سطح ساكن.
          Positioned(
            top: -80.h,
            right: -60.w,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final v = 0.18 + (_glowController.value * 0.12);
                return Container(
                  width: 260.w,
                  height: 260.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentGold.withValues(alpha: v),
                        Colors.transparent
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 40.h),
              children: [
                Row(
                  children: [
                    _circleButton(
                      brightness,
                      Icons.arrow_forward_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(width: 12.w),
                    Text('البروفايل',
                        style: AppTypography.headline(brightness)),
                  ],
                ),
                SizedBox(height: 24.h),
                StaggeredFadeIn(
                    index: 0, child: _AccountHero(brightness: brightness)),
                SizedBox(height: 28.h),
                StaggeredFadeIn(
                    index: 1, child: _sectionLabel(brightness, 'بياناتك')),
                SizedBox(height: 12.h),
                StaggeredFadeIn(
                  index: 2,
                  child: _ProfileTile(
                    icon: Icons.palette_rounded,
                    iconColor: const Color(0xFFCB7BD8),
                    label: 'الثيم',
                    subtitle: 'اختار شكل التطبيق اللي يناسبك',
                    brightness: brightness,
                    onTap: () => ThemePickerSheet.show(context),
                  ),
                ),
                StaggeredFadeIn(
                  index: 3,
                  child: _ProfileTile(
                    icon: Icons.download_for_offline_rounded,
                    iconColor: const Color(0xFF2FAE85),
                    label: 'تحميلاتي',
                    subtitle: 'السور المتاحة من غير نت',
                    brightness: brightness,
                    onTap: () => Navigator.of(context)
                        .push(fadeScaleRoute(const DownloadsScreen())),
                  ),
                ),
                StaggeredFadeIn(
                  index: 4,
                  child: _ProfileTile(
                    icon: Icons.queue_music_rounded,
                    iconColor: const Color(0xFF6C8AE4),
                    label: 'قوائمي',
                    subtitle: 'قوائم التشغيل اللي عملتها',
                    brightness: brightness,
                    onTap: () => Navigator.of(context)
                        .push(fadeScaleRoute(const PlaylistsScreen())),
                  ),
                ),
                StaggeredFadeIn(
                  index: 5,
                  child: _ProfileTile(
                    icon: Icons.auto_stories_rounded,
                    iconColor: AppColors.accentGold,
                    label: 'ختمتي',
                    subtitle: 'تابع تقدّمك في ختم القرآن',
                    brightness: brightness,
                    onTap: () => Navigator.of(context)
                        .push(fadeScaleRoute(const KhatmaScreen())),
                  ),
                ),
                StaggeredFadeIn(
                  index: 6,
                  child: _ProfileTile(
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFFE49A6C),
                    label: 'الإعدادات',
                    subtitle: 'السرعة، مؤقت النوم، والتحميل',
                    brightness: brightness,
                    onTap: () => Navigator.of(context)
                        .push(fadeScaleRoute(const SettingsScreen())),
                  ),
                ),
                SizedBox(height: 20.h),
                StaggeredFadeIn(
                    index: 7, child: _sectionLabel(brightness, 'عن التطبيق')),
                SizedBox(height: 12.h),
                StaggeredFadeIn(
                  index: 8,
                  child: _ProfileTile(
                    icon: Icons.person_rounded,
                    iconColor: AppColors.primary,
                    label: 'عن المطوّر',
                    subtitle: 'تواصل ومصادر التطبيق',
                    brightness: brightness,
                    onTap: () => Navigator.of(context)
                        .push(fadeScaleRoute(const AboutScreen())),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(Brightness brightness, IconData icon,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill(brightness),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Icon(icon, size: 20.sp),
      ),
    );
  }

  Widget _sectionLabel(Brightness brightness, String text) {
    return Text(
      text,
      style: AppTypography.caption(brightness).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// كارت البطل فوق الشاشة - بيوري صورة رمزية متوهجة واسم/إيميل المستخدم لو
/// مسجّل، أو دعوة لطيفة لتسجيل الدخول لو لسه ضيف.
class _AccountHero extends StatelessWidget {
  final Brightness brightness;

  const _AccountHero({required this.brightness});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isAvailable) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AuthService.instance.isRestoringSession,
      builder: (context, restoring, _) {
        if (restoring) {
          return Container(
            height: 120.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.glassFill(brightness),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder(brightness)),
            ),
            child: SizedBox(
              width: 22.w,
              height: 22.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.accentGold),
              ),
            ),
          );
        }

        return ValueListenableBuilder<User?>(
          valueListenable: AuthService.instance.currentUser,
          builder: (context, user, __) {
            final isSignedIn = user != null;

            return Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSignedIn
                      ? [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.primaryLight.withValues(alpha: 0.10)
                        ]
                      : [
                          AppColors.glassFill(brightness),
                          AppColors.glassFill(brightness)
                        ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isSignedIn
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.glassBorder(brightness),
                  width: 1.2,
                ),
              ),
              child: isSignedIn
                  ? Row(
                      children: [
                        Container(
                          width: 58.w,
                          height: 58.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                LinearGradient(colors: AppColors.goldGradient),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.accentGold.withValues(alpha: 0.4),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.black87, size: 28),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 14.sp, color: AppColors.success),
                                  SizedBox(width: 4.w),
                                  Text('بياناتك متزامنة',
                                      style: AppTypography.caption(brightness)),
                                ],
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                user.email ?? '',
                                style: AppTypography.body(brightness)
                                    .copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => AuthService.instance.signOut(),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.error),
                          child: const Text('خروج'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentGold
                                    .withValues(alpha: 0.16),
                              ),
                              child: Icon(Icons.cloud_off_rounded,
                                  color: AppColors.accentGoldSoft, size: 20.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'مش مسجّل دخول',
                                style: AppTypography.body(brightness)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'تسجيل الدخول اختياري - بيخليك تسترجع بياناتك (المفضلة والقوائم) من أي جهاز',
                          style: AppTypography.caption(brightness),
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => Navigator.of(context).push(
                                    fadeScaleRoute(const SignInScreen(
                                        mode: SignInMode.signIn))),
                                child: const Text('تسجيل دخول'),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.of(context).push(
                                    fadeScaleRoute(const SignInScreen(
                                        mode: SignInMode.signUp))),
                                child: const Text('حساب جديد'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final Brightness brightness;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(icon, size: 19.sp, color: iconColor),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: AppTypography.body(brightness)
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(subtitle, style: AppTypography.caption(brightness)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: AppColors.primary, size: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
