import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/surah_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../downloads/data/download_service.dart';
import '../../favorites/data/favorites_service.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/cubit/player_state.dart';
import '../../player/data/queue_item.dart';
import '../../player/presentation/mini_player.dart';
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
        .map((s) => QueueItem.fromReciter(
            reciter: widget.reciter, moshaf: moshaf, surahNumber: s))
        .toList();
    final startIndex = queue.indexWhere((q) => q.surahNumber == surahNumber);
    context
        .read<PlayerCubit>()
        .playQueue(queue, startIndex: startIndex < 0 ? 0 : startIndex);
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
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                        const Spacer(),
                        ValueListenableBuilder<Set<int>>(
                          valueListenable: FavoritesService.instance.favorites,
                          builder: (context, favorites, _) {
                            final isFav = favorites.contains(reciter.id);
                            return IconButton(
                              onPressed: () =>
                                  FavoritesService.instance.toggle(reciter.id),
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav ? AppColors.error : null,
                              ),
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
                            onTap: () =>
                                setState(() => _selectedMoshafIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.glassFill(brightness),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.glassBorder(brightness),
                                ),
                              ),
                              child: Text(
                                m.name,
                                style: AppTypography.label(brightness).copyWith(
                                  color: selected ? Colors.white : null,
                                ),
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
                        child: Text('لا توجد سور متاحة لهذه الرواية',
                            style: AppTypography.body(brightness)),
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

  QueueItem get _item => QueueItem.fromReciter(
      reciter: reciter, moshaf: moshaf, surahNumber: surahNumber);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surah = SurahData.byNumber(surahNumber);
    final item = _item;

    return BlocBuilder<PlayerCubit, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.currentItem != curr.currentItem ||
          prev.isPlaying != curr.isPlaying,
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
                      style: AppTypography.body(brightness).copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent ? AppColors.primary : null,
                      ),
                    ),
                  ),
                  _DownloadButton(item: item),
                  SizedBox(width: 4.w),
                  Icon(
                    isCurrent && playerState.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 26.sp,
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
            icon: Icon(Icons.download_done_rounded,
                color: AppColors.success, size: 20.sp),
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
          onPressed: () =>
              DownloadService.instance.download(item.key, item.audioUrl),
          icon: Icon(Icons.download_rounded, size: 20.sp),
          tooltip: 'تحميل للاستماع بدون نت',
        );
      },
    );
  }
}
