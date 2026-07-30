import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_premium/features/playlists/data/playlist_model.dart';
import 'package:quran_premium/features/playlists/data/playlists_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/data/queue_item.dart';

/// شاشة تفاصيل قائمة تشغيل واحدة - عرض السور اللي فيها، تشغيلها كلها،
/// أو حذف أي سورة منها.
class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  Future<void> _rename(BuildContext context, Playlist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final brightness = Theme.of(context).brightness;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        title: Text('إعادة تسمية', style: AppTypography.title(brightness)),
        content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTypography.body(brightness)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await PlaylistsService.instance.renamePlaylist(playlistId, name);
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
          child: ValueListenableBuilder<List<Playlist>>(
            valueListenable: PlaylistsService.instance.playlists,
            builder: (context, lists, _) {
              final playlist = lists.firstWhere(
                (p) => p.id == playlistId,
                orElse: () => Playlist(
                    id: playlistId,
                    name: 'قائمة',
                    createdAt: 0,
                    items: const []),
              );

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
                              border: Border.all(
                                  color: AppColors.glassBorder(brightness)),
                            ),
                            child:
                                Icon(Icons.arrow_forward_rounded, size: 20.sp),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(playlist.name,
                                  style: AppTypography.title(brightness)),
                              Text('${playlist.items.length} سورة',
                                  style: AppTypography.caption(brightness)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _rename(context, playlist),
                          icon: Icon(Icons.edit_rounded,
                              size: 19.sp, color: AppColors.accentGoldSoft),
                        ),
                        IconButton(
                          onPressed: () async {
                            await PlaylistsService.instance
                                .deletePlaylist(playlistId);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 20.sp, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  if (playlist.items.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => context
                              .read<PlayerCubit>()
                              .playQueue(playlist.items, startIndex: 0),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 9.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppColors.primaryLight,
                                AppColors.primary
                              ]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 4.w),
                                Text('تشغيل القائمة',
                                    style: AppTypography.label(brightness)
                                        .copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: playlist.items.isEmpty
                        ? Center(
                            child: Text('القائمة فاضية لسه',
                                style: AppTypography.body(brightness)),
                          )
                        : ReorderableListView.builder(
                            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                            itemCount: playlist.items.length,
                            onReorder: (oldIndex, newIndex) {
                              PlaylistsService.instance
                                  .reorderItems(playlistId, oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final item = playlist.items[index];
                              return Padding(
                                key: ValueKey(item.key),
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: _PlaylistTrackTile(
                                  item: item,
                                  playlistId: playlistId,
                                  allItems: playlist.items,
                                  index: index,
                                ),
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

class _PlaylistTrackTile extends StatelessWidget {
  final QueueItem item;
  final String playlistId;
  final List<QueueItem> allItems;
  final int index;

  const _PlaylistTrackTile({
    required this.item,
    required this.playlistId,
    required this.allItems,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Material(
      color: AppColors.glassFill(brightness),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            context.read<PlayerCubit>().playQueue(allItems, startIndex: index),
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
                    Text(item.surahArabicName,
                        style: AppTypography.body(brightness)),
                    Text(item.reciterName,
                        style: AppTypography.caption(brightness)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () =>
                    PlaylistsService.instance.removeItem(playlistId, item),
                icon: Icon(Icons.close_rounded,
                    size: 18.sp,
                    color: brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
