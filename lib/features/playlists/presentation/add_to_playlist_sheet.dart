import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_premium/features/playlists/data/playlist_model.dart';
import 'package:quran_premium/features/playlists/data/playlists_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../player/data/queue_item.dart';

/// شيت بيفتح من أي مكان في التطبيق (وهو بيسمع أو من قائمة سور) عشان
/// يضيف السورة الحالية لأي قائمة تشغيل عنده، أو يعمل قائمة جديدة على طول.
class AddToPlaylistSheet extends StatelessWidget {
  final QueueItem item;

  const AddToPlaylistSheet({super.key, required this.item});

  static void show(BuildContext context, QueueItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(item: item),
    );
  }

  Future<void> _createAndAdd(BuildContext context) async {
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
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final playlist = await PlaylistsService.instance.createPlaylist(name);
    await PlaylistsService.instance.addItem(playlist.id, item);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
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
              Text('إضافة إلى قائمة', style: AppTypography.title(brightness)),
              SizedBox(height: 6.h),
              Text(item.surahArabicName,
                  style: AppTypography.caption(brightness)),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Material(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _createAndAdd(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 14.w),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_rounded,
                              color: AppColors.primary),
                          SizedBox(width: 10.w),
                          Text('قائمة جديدة',
                              style: AppTypography.body(brightness).copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: ValueListenableBuilder<List<Playlist>>(
                  valueListenable: PlaylistsService.instance.playlists,
                  builder: (context, lists, _) {
                    if (lists.isEmpty) {
                      return Center(
                        child: Text('لسه معملتش قوائم',
                            style: AppTypography.body(brightness)),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final playlist = lists[index];
                        final has = playlist.items.contains(item);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.glassFill(brightness),
                            ),
                            child: Icon(Icons.queue_music_rounded,
                                size: 18.sp, color: AppColors.accentGoldSoft),
                          ),
                          title: Text(playlist.name,
                              style: AppTypography.body(brightness)),
                          subtitle: Text('${playlist.items.length} سورة',
                              style: AppTypography.caption(brightness)),
                          trailing: Icon(
                            has
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: has
                                ? AppColors.success
                                : AppColors.accentGoldSoft,
                          ),
                          onTap: () {
                            if (has) {
                              PlaylistsService.instance
                                  .removeItem(playlist.id, item);
                            } else {
                              PlaylistsService.instance
                                  .addItem(playlist.id, item);
                            }
                          },
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
