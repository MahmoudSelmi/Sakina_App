import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/settings_service.dart';

/// شاشة الإعدادات الموحّدة - سرعة التشغيل الافتراضية، مؤقت النوم
/// الافتراضي، التحميل على الواي فاي بس، ومسح كل التحميلات.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const List<int?> _sleepOptions = [null, 10, 15, 30, 45, 60];

  Future<void> _confirmClearDownloads(BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        title:
            Text('مسح كل التحميلات؟', style: AppTypography.title(brightness)),
        content: Text(
          'هيتم حذف كل السور المحمّلة من الجهاز نهائيًا.',
          style: AppTypography.body(brightness),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('مسح الكل', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SettingsService.instance.clearAllDownloads();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اتمسحت كل التحميلات')),
        );
      }
    }
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassFill(brightness),
                        border: Border.all(
                            color: AppColors.glassBorder(brightness)),
                      ),
                      child: Icon(Icons.arrow_forward_rounded, size: 20.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text('الإعدادات', style: AppTypography.title(brightness)),
                ],
              ),
              SizedBox(height: 24.h),
              _sectionLabel(brightness, 'سرعة التشغيل الافتراضية'),
              SizedBox(height: 10.h),
              ValueListenableBuilder<double>(
                valueListenable: SettingsService.instance.defaultSpeed,
                builder: (context, speed, _) {
                  return Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _speeds.map((s) {
                      final selected = s == speed;
                      return GestureDetector(
                        onTap: () =>
                            SettingsService.instance.setDefaultSpeed(s),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 9.h),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(colors: [
                                    AppColors.primaryLight,
                                    AppColors.primary
                                  ])
                                : null,
                            color: selected
                                ? null
                                : AppColors.glassFill(brightness),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.glassBorder(brightness),
                            ),
                          ),
                          child: Text(
                            '${s}x',
                            style: AppTypography.body(brightness).copyWith(
                                color: selected ? Colors.white : null),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 26.h),
              _sectionLabel(brightness, 'مؤقت النوم الافتراضي'),
              SizedBox(height: 10.h),
              ValueListenableBuilder<int?>(
                valueListenable: SettingsService.instance.defaultSleepMinutes,
                builder: (context, minutes, _) {
                  return Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _sleepOptions.map((m) {
                      final selected = m == minutes;
                      return GestureDetector(
                        onTap: () =>
                            SettingsService.instance.setDefaultSleepMinutes(m),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 9.h),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(colors: [
                                    AppColors.primaryLight,
                                    AppColors.primary
                                  ])
                                : null,
                            color: selected
                                ? null
                                : AppColors.glassFill(brightness),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.glassBorder(brightness),
                            ),
                          ),
                          child: Text(
                            m == null ? 'من غير مؤقت' : '$m دقيقة',
                            style: AppTypography.body(brightness).copyWith(
                                color: selected ? Colors.white : null),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 26.h),
              _sectionLabel(brightness, 'التحميلات'),
              SizedBox(height: 10.h),
              ValueListenableBuilder<bool>(
                valueListenable: SettingsService.instance.wifiOnlyDownload,
                builder: (context, wifiOnly, _) {
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill(brightness),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.glassBorder(brightness)),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: wifiOnly,
                      onChanged: (v) =>
                          SettingsService.instance.setWifiOnlyDownload(v),
                      activeThumbColor: AppColors.primary,
                      title: Text('التحميل على الواي فاي بس',
                          style: AppTypography.body(brightness)),
                      subtitle: Text('توفير استهلاك الإنترنت',
                          style: AppTypography.caption(brightness)),
                    ),
                  );
                },
              ),
              SizedBox(height: 10.h),
              Material(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _confirmClearDownloads(context),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded,
                            color: AppColors.error, size: 20.sp),
                        SizedBox(width: 10.w),
                        Text(
                          'مسح كل التحميلات',
                          style: AppTypography.body(brightness)
                              .copyWith(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(Brightness brightness, String text) {
    return Text(
      text,
      style: AppTypography.caption(brightness)
          .copyWith(fontWeight: FontWeight.w700),
    );
  }
}
