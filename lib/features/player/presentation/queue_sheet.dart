import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../cubit/player_cubit.dart';
import '../cubit/player_state.dart';

/// شاشة "قائمة الانتظار" - بتفتح كـ bottom sheet قابل للسحب، وبتعرض كل
/// السور الجاية في نفس قائمة التشغيل الحالية، مع تمييز السورة الشغالة
/// دلوقتي وإمكانية الدوس على أي سورة تانية عشان تنط ليها على طول.
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder(brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 14.h),
              Text('قائمة الانتظار', style: AppTypography.title(brightness)),
              SizedBox(height: 8.h),
              Expanded(
                child: BlocBuilder<PlayerCubit, PlayerState>(
                  builder: (context, state) {
                    if (state.queue.isEmpty) {
                      return Center(
                        child: Text('القائمة فاضية',
                            style: AppTypography.body(brightness)),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                      itemCount: state.queue.length,
                      itemBuilder: (context, index) {
                        final item = state.queue[index];
                        final isCurrent = index == state.currentIndex;
                        return Material(
                          color: isCurrent
                              ? AppColors.primary.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              context
                                  .read<PlayerCubit>()
                                  .jumpToQueueIndex(index);
                              Navigator.of(context).pop();
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8.h, horizontal: 8.w),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28.w,
                                    child: isCurrent
                                        ? Icon(Icons.graphic_eq_rounded,
                                            color: AppColors.primary,
                                            size: 18.sp)
                                        : Text(
                                            '${index + 1}',
                                            style: AppTypography.caption(
                                                brightness),
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                  SizedBox(width: 10.w),
                                  ReciterAvatar(
                                    reciterId: item.reciterId,
                                    letter: item.reciterName.isNotEmpty
                                        ? item.reciterName[0]
                                        : '؟',
                                    size: 40.w,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.surahArabicName,
                                          style: AppTypography.body(brightness)
                                              .copyWith(
                                            fontWeight: isCurrent
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: isCurrent
                                                ? AppColors.primary
                                                : null,
                                          ),
                                        ),
                                        Text(item.reciterName,
                                            style: AppTypography.caption(
                                                brightness)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
