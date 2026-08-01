import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/surah_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/khatma_service.dart';

/// شاشة "ختمتي" - بتوريك كل الـ 114 سورة، وأنهي منهم استمعتلها كاملة في
/// الدورة الحالية، مع عداد لعدد الختمات اللي خلّصتها قبل كده.
class KhatmaScreen extends StatelessWidget {
  const KhatmaScreen({super.key});

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
          child: ValueListenableBuilder<Set<int>>(
            valueListenable: KhatmaService.instance.completedSurahs,
            builder: (context, completed, _) {
              return ValueListenableBuilder<int>(
                valueListenable: KhatmaService.instance.khatmaCount,
                builder: (context, khatmaCount, __) {
                  final progress = completed.length / KhatmaService.totalSurahs;

                  return ListView(
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
                          Text('ختمتي', style: AppTypography.title(brightness)),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill(brightness),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.glassBorder(brightness)),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 110.w,
                              height: 110.w,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 110.w,
                                    height: 110.w,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 8,
                                      backgroundColor: AppColors.glassBorder(brightness),
                                      valueColor: AlwaysStoppedAnimation(AppColors.accentGold),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${completed.length}',
                                        style: AppTypography.headline(brightness)
                                            .copyWith(fontWeight: FontWeight.w800),
                                      ),
                                      Text('من ${KhatmaService.totalSurahs}',
                                          style: AppTypography.caption(brightness)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              khatmaCount == 0
                                  ? 'أول ختمة ليك جاية قريب - كمّل الاستماع'
                                  : 'خلّصت $khatmaCount ختمة كاملة، ما شاء الله',
                              textAlign: TextAlign.center,
                              style: AppTypography.body(brightness),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text('السور', style: AppTypography.title(brightness)),
                      SizedBox(height: 12.h),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: SurahData.all.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8.h,
                          crossAxisSpacing: 8.w,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final surah = SurahData.all[index];
                          final done = completed.contains(surah.number);
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: done ? LinearGradient(colors: AppColors.goldGradient) : null,
                              color: done ? null : AppColors.glassFill(brightness),
                              border: Border.all(
                                color: done ? AppColors.accentGold : AppColors.glassBorder(brightness),
                              ),
                            ),
                            child: Text(
                              '${surah.number}',
                              style: TextStyle(
                                color: done
                                    ? Colors.black87
                                    : (brightness == Brightness.dark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                fontSize: 11.sp,
                                fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
