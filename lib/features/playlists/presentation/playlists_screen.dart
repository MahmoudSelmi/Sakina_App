import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_premium/features/playlists/data/playlist_model.dart';
import 'package:quran_premium/features/playlists/data/playlists_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import 'playlist_detail_screen.dart';

/// شاشة "قوائمي" - كل قوائم التشغيل اللي عملها المستخدم بنفسه.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  Future<void> _createPlaylist(BuildContext context) async {
    final controller = TextEditingController();
    final brightness = Theme.of(context).brightness;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        title: Text('قائمة جديدة', style: AppTypography.title(brightness)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.body(brightness),
          decoration: const InputDecoration(hintText: 'اسم القائمة...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await PlaylistsService.instance.createPlaylist(name);
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
          child: Column(
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
                          border: Border.all(
                              color: AppColors.glassBorder(brightness)),
                        ),
                        child: Icon(Icons.arrow_forward_rounded, size: 20.sp),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                        child: Text('قوائمي',
                            style: AppTypography.title(brightness))),
                    GestureDetector(
                      onTap: () => _createPlaylist(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.primaryLight,
                            AppColors.primary
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 4.w),
                            Text('جديدة',
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
                child: ValueListenableBuilder<List<Playlist>>(
                  valueListenable: PlaylistsService.instance.playlists,
                  builder: (context, lists, _) {
                    if (lists.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.queue_music_rounded,
                                size: 44.sp,
                                color: brightness == Brightness.dark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                            SizedBox(height: 10.h),
                            Text('اعمل أول قائمة تشغيل ليك',
                                style: AppTypography.body(brightness)),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                      itemCount: lists.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final playlist = lists[index];
                        return StaggeredFadeIn(
                          index: index,
                          stepDelay: const Duration(milliseconds: 20),
                          child: Material(
                            color: AppColors.glassFill(brightness),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                fadeScaleRoute(PlaylistDetailScreen(
                                    playlistId: playlist.id)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 12.h),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48.w,
                                      height: 48.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                            colors: AppColors.goldGradient),
                                      ),
                                      child: const Icon(
                                          Icons.queue_music_rounded,
                                          color: Colors.black87),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(playlist.name,
                                              style: AppTypography.body(
                                                  brightness)),
                                          Text('${playlist.items.length} سورة',
                                              style: AppTypography.caption(
                                                  brightness)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_left_rounded,
                                        color: AppColors.primary, size: 22.sp),
                                  ],
                                ),
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
        ),
      ),
    );
  }
}
