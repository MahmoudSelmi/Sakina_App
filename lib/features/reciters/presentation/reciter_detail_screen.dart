import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/surah_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/moshaf_style.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../downloads/data/download_service.dart';
import '../../favorites/data/favorites_service.dart';
import '../../favorites/data/surah_favorites_service.dart';
import '../../playlists/presentation/add_to_playlist_sheet.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/cubit/player_state.dart';
import '../../player/data/queue_item.dart';
import '../../player/presentation/mini_player.dart';
import '../../settings/data/settings_service.dart';
import '../data/models/moshaf_model.dart';
import '../data/models/reciter_model.dart';

class ReciterDetailScreen extends StatefulWidget {
  final ReciterModel reciter;

  const ReciterDetailScreen({super.key, required this.reciter});

  @override
  State<ReciterDetailScreen> createState() => _ReciterDetailScreenState();
}

class _ReciterDetailScreenState extends State<ReciterDetailScreen> {
  late int _selectedMoshafIndex;

  @override
  void initState() {
    super.initState();
    _selectedMoshafIndex = 0;
  }

  MoshafModel? get _selectedMoshaf {
    if (widget.reciter.moshaf.isEmpty) return null;
    return widget.reciter.moshaf[_selectedMoshafIndex];
  }

  void _playFrom(int surahNumber) {
    final moshaf = _selectedMoshaf;
    if (moshaf == null) return;
    final queue = moshaf.surahList
        .map((s) => QueueItem.fromReciter(reciter: widget.reciter, moshaf: moshaf, surahNumber: s))
        .toList();
    final startIndex = queue.indexWhere((q) => q.surahNumber == surahNumber);
    context.read<PlayerCubit>().playQueue(queue, startIndex: startIndex < 0 ? 0 : startIndex);
  }

  void _shareReciter() {
    Share.share('استمع لتلاوات ${widget.reciter.name} على تطبيق جَنَّتَكَ 🌙');
  }

  Future<void> _downloadAllSurahs(BuildContext context) async {
    final moshaf = _selectedMoshaf;
    if (moshaf == null) return;

    final allowed = await SettingsService.instance.canDownloadNow();
    if (!allowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التحميل مفعّل على الواي فاي بس دلوقتي - وصّل واي فاي وجرّب تاني')),
        );
      }
      return;
    }

    final items = moshaf.surahList
        .map((s) => QueueItem.fromReciter(reciter: widget.reciter, moshaf: moshaf, surahNumber: s))
        .where((item) => !DownloadService.instance.isDownloaded(item.key))
        .toList();

    if (items.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('كل السور محمّلة عندك بالفعل')));
      }
      return;
    }

    final progress = ValueNotifier<int>(0);
    bool cancelled = false;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('جاري تحميل كل السور...'),
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (context, done, _) => Text('اتحمّل $done من ${items.length}'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.of(dialogContext).pop();
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    for (final item in items) {
      if (cancelled) break;
      await DownloadService.instance.download(item);
      progress.value++;
    }

    if (!cancelled && context.mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('اتحمّلت ${items.length} سورة بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final reciter = widget.reciter;
    final moshaf = _selectedMoshaf;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                    child: Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_forward_rounded,
                          brightness: brightness,
                          semanticLabel: 'رجوع',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        _CircleIconButton(
                          icon: Icons.ios_share_rounded,
                          brightness: brightness,
                          semanticLabel: 'مشاركة',
                          onTap: _shareReciter,
                        ),
                        SizedBox(width: 8.w),
                        _CircleIconButton(
                          icon: Icons.download_for_offline_rounded,
                          brightness: brightness,
                          semanticLabel: 'تحميل كل السور',
                          onTap: () => _downloadAllSurahs(context),
                        ),
                        SizedBox(width: 8.w),
                        ValueListenableBuilder<Set<int>>(
                          valueListenable: FavoritesService.instance.favorites,
                          builder: (context, favorites, _) {
                            final isFav = favorites.contains(reciter.id);
                            return _CircleIconButton(
                              icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              brightness: brightness,
                              iconColor: isFav ? AppColors.error : null,
                              semanticLabel: isFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                              onTap: () => FavoritesService.instance.toggle(reciter.id),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      ReciterAvatar(
                        reciterId: reciter.id,
                        letter: reciter.letter,
                        size: 118.w,
                        ring: true,
                        heroTag: 'reciter-avatar-${reciter.id}',
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        reciter.name,
                        style: AppTypography.headline(brightness),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        moshaf != null
                            ? '${moshaf.surahTotal} سورة متاحة'
                            : 'لا توجد تلاوات متاحة حاليًا',
                        style: AppTypography.caption(brightness),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
                if (reciter.moshaf.length > 1)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 42.h,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: reciter.moshaf.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, index) {
                          final selected = index == _selectedMoshafIndex;
                          final m = reciter.moshaf[index];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMoshafIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: selected
                                    ?  LinearGradient(colors: [
                                        AppColors.primaryLight,
                                        AppColors.primary,
                                      ])
                                    : null,
                                color: selected ? null : AppColors.glassFill(brightness),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.glassBorder(brightness),
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.28),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    MoshafStyle.iconFor(m.name),
                                    size: 15.sp,
                                    color: selected ? Colors.white : AppColors.accentGoldSoft,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    m.name,
                                    style: AppTypography.label(brightness).copyWith(
                                      color: selected ? Colors.white : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                if (moshaf == null || moshaf.surahList.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Center(
                        child: Text('لا توجد سور متاحة لهذه الرواية', style: AppTypography.body(brightness)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 130.h),
                    sliver: SliverList.separated(
                      itemCount: moshaf.surahList.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemBuilder: (context, index) {
                        final surahNumber = moshaf.surahList[index];
                        return StaggeredFadeIn(
                          index: index,
                          stepDelay: const Duration(milliseconds: 18),
                          child: _SurahRow(
                            reciter: reciter,
                            moshaf: moshaf,
                            surahNumber: surahNumber,
                            onTap: () => _playFrom(surahNumber),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const Positioned(left: 0, right: 0, bottom: 8, child: MiniPlayer()),
          ],
        ),
      ),
    );
  }
}

/// زرار دائري بخلفية زجاجية، بديل أنيق لأيقونات AppBar التقليدية.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Brightness brightness;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? semanticLabel;

  const _CircleIconButton({
    required this.icon,
    required this.brightness,
    required this.onTap,
    this.iconColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glassFill(brightness),
            border: Border.all(color: AppColors.glassBorder(brightness)),
          ),
          child: Icon(icon, size: 20.sp, color: iconColor),
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  final ReciterModel reciter;
  final MoshafModel moshaf;
  final int surahNumber;
  final VoidCallback onTap;

  const _SurahRow({
    required this.reciter,
    required this.moshaf,
    required this.surahNumber,
    required this.onTap,
  });

  QueueItem get _item => QueueItem.fromReciter(reciter: reciter, moshaf: moshaf, surahNumber: surahNumber);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surah = SurahData.byNumber(surahNumber);
    final item = _item;

    return BlocBuilder<PlayerCubit, PlayerState>(
      buildWhen: (prev, curr) => prev.currentItem != curr.currentItem || prev.isPlaying != curr.isPlaying,
      builder: (context, playerState) {
        final isCurrent = playerState.currentItem == item;

        return Material(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.glassFill(brightness),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      '$surahNumber',
                      style: AppTypography.caption(brightness).copyWith(
                        color: isCurrent ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      surah.arabicName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(brightness).copyWith(
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent ? AppColors.primary : null,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<Map<String, QueueItem>>(
                    valueListenable: SurahFavoritesService.instance.favorites,
                    builder: (context, favs, _) {
                      final isFav = favs.containsKey(item.key);
                      return GestureDetector(
                        onTap: () => SurahFavoritesService.instance.toggle(item),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.error : AppColors.accentGoldSoft,
                            size: 18.sp,
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () => AddToPlaylistSheet.show(context, item),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Icon(
                        Icons.playlist_add_rounded,
                        color: AppColors.accentGoldSoft,
                        size: 19.sp,
                      ),
                    ),
                  ),
                  _DownloadButton(item: item),
                  SizedBox(width: 4.w),
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isCurrent
                            ? [AppColors.primaryLight, AppColors.primary]
                            : [
                                AppColors.primary.withValues(alpha: 0.16),
                                AppColors.primary.withValues(alpha: 0.16),
                              ],
                      ),
                    ),
                    child: Icon(
                      isCurrent && playerState.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: isCurrent ? Colors.white : AppColors.primary,
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final QueueItem item;

  const _DownloadButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, DownloadState>>(
      valueListenable: DownloadService.instance.states,
      builder: (context, states, _) {
        final downloaded = DownloadService.instance.isDownloaded(item.key);
        final state = states[item.key] ?? const DownloadState();

        if (downloaded) {
          return IconButton(
            onPressed: () => DownloadService.instance.deleteDownload(item.key),
            icon: Icon(Icons.download_done_rounded, color: AppColors.success, size: 20.sp),
            tooltip: 'محمّلة - اضغط للحذف',
          );
        }

        if (state.isDownloading) {
          return SizedBox(
            width: 36.w,
            height: 36.w,
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                value: state.progress > 0 ? state.progress : null,
                color: AppColors.primary,
              ),
            ),
          );
        }

        return IconButton(
          onPressed: () => DownloadService.instance.download(item),
          icon: Icon(Icons.download_rounded, size: 20.sp),
          tooltip: 'تحميل للاستماع بدون نت',
        );
      },
    );
  }
}
