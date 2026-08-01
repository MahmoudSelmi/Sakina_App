import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/page_transitions.dart';
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
/// معلومات المطوّر (مش بتتغيّر بتغيير حساب المستخدم).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  GestureDetector(
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
                  ),
                  SizedBox(width: 12.w),
                  Text('البروفايل', style: AppTypography.title(brightness)),
                ],
              ),
              SizedBox(height: 22.h),
              _AccountSection(brightness: brightness),
              SizedBox(height: 24.h),
              _sectionLabel(brightness, 'بياناتك'),
              SizedBox(height: 10.h),
              _ProfileTile(
                icon: Icons.palette_rounded,
                label: 'الثيم',
                brightness: brightness,
                onTap: () => ThemePickerSheet.show(context),
              ),
              _ProfileTile(
                icon: Icons.download_for_offline_rounded,
                label: 'تحميلاتي',
                brightness: brightness,
                onTap: () => Navigator.of(context).push(fadeScaleRoute(const DownloadsScreen())),
              ),
              _ProfileTile(
                icon: Icons.queue_music_rounded,
                label: 'قوائمي',
                brightness: brightness,
                onTap: () => Navigator.of(context).push(fadeScaleRoute(const PlaylistsScreen())),
              ),
              _ProfileTile(
                icon: Icons.auto_stories_rounded,
                label: 'ختمتي',
                brightness: brightness,
                onTap: () => Navigator.of(context).push(fadeScaleRoute(const KhatmaScreen())),
              ),
              _ProfileTile(
                icon: Icons.tune_rounded,
                label: 'الإعدادات',
                brightness: brightness,
                onTap: () => Navigator.of(context).push(fadeScaleRoute(const SettingsScreen())),
              ),
              SizedBox(height: 24.h),
              _sectionLabel(brightness, 'عن التطبيق'),
              SizedBox(height: 10.h),
              _ProfileTile(
                icon: Icons.person_rounded,
                label: 'عن المطوّر',
                brightness: brightness,
                onTap: () => Navigator.of(context).push(fadeScaleRoute(const AboutScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(Brightness brightness, String text) {
    return Text(text, style: AppTypography.caption(brightness).copyWith(fontWeight: FontWeight.w700));
  }
}

class _AccountSection extends StatelessWidget {
  final Brightness brightness;

  const _AccountSection({required this.brightness});

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isAvailable) {
      // فايربيز لسه مش متظبط - منعرضش واجهة تسجيل دخول أصلًا عشان منلخبطش
      // المستخدم بحاجة مش شغالة.
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<User?>(
      valueListenable: AuthService.instance.currentUser,
      builder: (context, user, _) {
        if (user != null) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.glassFill(brightness),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.glassBorder(brightness)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: AppColors.goldGradient),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.black87),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مسجّل دخول', style: AppTypography.caption(brightness)),
                      Text(user.email ?? '', style: AppTypography.body(brightness)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => AuthService.instance.signOut(),
                  child: const Text('خروج'),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder(brightness)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مش مسجّل دخول', style: AppTypography.body(brightness).copyWith(fontWeight: FontWeight.w700)),
              SizedBox(height: 4.h),
              Text(
                'التسجيل اختياري تمامًا - بس لو عملته، بياناتك (المفضلة والقوائم) هتتزامن على أي جهاز تسجّل دخول بيه',
                style: AppTypography.caption(brightness),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context)
                          .push(fadeScaleRoute(const SignInScreen(mode: SignInMode.signIn))),
                      child: const Text('تسجيل دخول'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context)
                          .push(fadeScaleRoute(const SignInScreen(mode: SignInMode.signUp))),
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
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Brightness brightness;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            child: Row(
              children: [
                Icon(icon, size: 19.sp, color: AppColors.accentGoldSoft),
                SizedBox(width: 12.w),
                Expanded(child: Text(label, style: AppTypography.body(brightness))),
                Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
