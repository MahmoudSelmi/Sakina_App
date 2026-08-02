import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/ambient/data/ambient_sound_service.dart';

/// شيت اختيار صوت الطبيعة اللي بيتشغّل هادي ورا التلاوة - بدون أي موسيقى
/// خالص، بس نسيج صوتي زي مطر أو هبوب رياح خفيفة، مع إمكانية تقفله تمامًا.
class AmbientSoundSheet extends StatelessWidget {
  final bool mainIsPlaying;

  const AmbientSoundSheet({super.key, required this.mainIsPlaying});

  static void show(BuildContext context, {required bool mainIsPlaying}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AmbientSoundSheet(mainIsPlaying: mainIsPlaying),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa_rounded,
                    color: AppColors.accentGoldSoft, size: 20.sp),
                SizedBox(width: 8.w),
                Text('صوت طبيعة في الخلفية',
                    style: AppTypography.title(brightness)),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'نسيج صوتي هادي بس (مطر أو رياح خفيفة) - من غير أي موسيقى خالص',
              style: AppTypography.caption(brightness),
            ),
            SizedBox(height: 16.h),
            ValueListenableBuilder<AmbientSound>(
              valueListenable: AmbientSoundService.instance.selected,
              builder: (context, selected, _) {
                return Column(
                  children: AmbientSoundCatalog.options.map((option) {
                    final isSelected = option.sound == selected;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Material(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AppColors.glassFill(brightness),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await AmbientSoundService.instance
                                .setSound(option.sound);
                            await AmbientSoundService.instance
                                .syncWithPlayback(mainIsPlaying);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 12.h),
                            child: Row(
                              children: [
                                Icon(
                                  option.sound == AmbientSound.rain
                                      ? Icons.water_drop_rounded
                                      : option.sound == AmbientSound.windLeaves
                                          ? Icons.air_rounded
                                          : Icons.volume_off_rounded,
                                  size: 18.sp,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.accentGoldSoft,
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(option.label,
                                      style: AppTypography.body(brightness)),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color: AppColors.primary, size: 18.sp),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            ValueListenableBuilder<AmbientSound>(
              valueListenable: AmbientSoundService.instance.selected,
              builder: (context, selected, _) {
                if (selected == AmbientSound.none) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder<double>(
                  valueListenable: AmbientSoundService.instance.volume,
                  builder: (context, vol, __) {
                    return Row(
                      children: [
                        Icon(Icons.volume_down_rounded,
                            size: 18.sp, color: AppColors.accentGoldSoft),
                        Expanded(
                          child: Slider(
                            value: vol,
                            onChanged: (v) =>
                                AmbientSoundService.instance.setVolume(v),
                          ),
                        ),
                        Icon(Icons.volume_up_rounded,
                            size: 18.sp, color: AppColors.accentGoldSoft),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
