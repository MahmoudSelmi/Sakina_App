import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/data/queue_item.dart';
import '../data/download_service.dart';

/// شاشة "التحميلات" - بتعرض كل السور المحمّلة للاستماع من غير نت، مع
/// إمكانية تشغيلها كلها كقائمة واحدة أو حذف أي واحدة منها.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

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
          child: ValueListenableBuilder<List<QueueItem>>(
            valueListenable: DownloadService.instance.downloadedItems,
            builder: (context, items, _) {
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                    child: Row(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تحميلاتي', style: AppTypography.title(brightness)),
                              Text(
                                items.isEmpty ? 'مفيش تحميلات لسه' : '${items.length} سورة محمّلة',
                                style: AppTypography.caption(brightness),
                              ),
                            ],
                          ),
                        ),
                        if (items.isNotEmpty)
                          GestureDetector(
                            onTap: () => context.read<PlayerCubit>().playQueue(items, startIndex: 0),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [AppColors.primaryLight, AppColors.primary]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 4.w),
                                  Text('تشغيل الكل',
                                      style: AppTypography.label(brightness)
                                          .copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download_for_offline_rounded,
                                    size: 44.sp,
                                    color: brightness == Brightness.dark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                                SizedBox(height: 10.h),
                                Text('حمّل أي سورة عشان تسمعها من غير نت',
                                    style: AppTypography.body(brightness)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => SizedBox(height: 8.h),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return StaggeredFadeIn(
                                index: index,
                                stepDelay: const Duration(milliseconds: 20),
                                child: _DownloadTile(item: item, allItems: items, index: index),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final QueueItem item;
  final List<QueueItem> allItems;
  final int index;

  const _DownloadTile({required this.item, required this.allItems, required this.index});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Material(
      color: AppColors.glassFill(brightness),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<PlayerCubit>().playQueue(allItems, startIndex: index),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              ReciterAvatar(
                reciterId: item.reciterId,
                letter: item.reciterName.isNotEmpty ? item.reciterName[0] : '؟',
                size: 44.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.surahArabicName, style: AppTypography.body(brightness)),
                    Text(item.reciterName, style: AppTypography.caption(brightness)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => DownloadService.instance.deleteDownload(item.key),
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
