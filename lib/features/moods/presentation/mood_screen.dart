import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/mood_playlist_builder.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../player/cubit/player_cubit.dart';
import '../../reciters/data/models/reciter_model.dart';

/// شاشة "أجواء" واحدة (نوم/مذاكرة/شغل/جيم) - بتعرض القائمة المختارة
/// وتشغّلها كلها بضغطة واحدة.
class MoodScreen extends StatelessWidget {
  final Mood mood;
  final List<ReciterModel> reciters;

  const MoodScreen({super.key, required this.mood, required this.reciters});

  @override
  Widget build(BuildContext context) {
    final info = MoodCatalog.all[mood]!;
    final items = MoodPlaylistBuilder.build(mood, reciters);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: info.gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              StaggeredFadeIn(
                index: 0,
                child: Column(
                  children: [
                    Container(
                      width: 84.w,
                      height: 84.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                      ),
                      child: Icon(info.icon, color: Colors.white, size: 38.sp),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      info.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Text(
                        info.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              if (items.isNotEmpty)
                StaggeredFadeIn(
                  index: 1,
                  child: GestureDetector(
                    onTap: () => context.read<PlayerCubit>().playQueue(items, startIndex: 0),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: info.gradient.first, size: 22.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'ابدأ الاستماع',
                            style: TextStyle(
                              color: info.gradient.first,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: brightness == Brightness.dark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: items.isEmpty
                      ? Center(
                          child: Text('مفيش تسجيلات متاحة دلوقتي', style: AppTypography.body(brightness)),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8.h),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return StaggeredFadeIn(
                              index: index + 2,
                              stepDelay: const Duration(milliseconds: 20),
                              child: Material(
                                color: AppColors.glassFill(brightness),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () =>
                                      context.read<PlayerCubit>().playQueue(items, startIndex: index),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                                    child: Row(
                                      children: [
                                        ReciterAvatar(
                                          reciterId: item.reciterId,
                                          letter:
                                              item.reciterName.isNotEmpty ? item.reciterName[0] : '؟',
                                          size: 42.w,
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.surahArabicName,
                                                  style: AppTypography.body(brightness)),
                                              Text(item.reciterName,
                                                  style: AppTypography.caption(brightness)),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.play_circle_fill_rounded,
                                            color: AppColors.primary, size: 22.sp),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
