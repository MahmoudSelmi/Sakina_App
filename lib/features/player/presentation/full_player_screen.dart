import 'dart:math' as math;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/now_playing_visuals.dart';
import '../../downloads/data/download_service.dart';
import '../../favorites/data/favorites_service.dart';
import '../cubit/player_cubit.dart';
import '../cubit/player_state.dart';
import '../data/queue_item.dart';
import 'queue_sheet.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  // لسحب الشاشة لتحت وقفلها، زي أي مشغل احترافي.
  double _dragExtent = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: Stack(
        children: [
          // خلفية متحركة ببطء - بتدي إحساس "الشاشة حية" زي Now Playing
          // في اسبوتيفاي، بدل الخلفية الثابتة.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                final t = _bgController.value * 2 * math.pi;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:
                          Alignment(math.cos(t) * 0.6, -1 + math.sin(t) * 0.3),
                      end: Alignment(-math.cos(t) * 0.6, 1 - math.sin(t) * 0.3),
                      colors: brightness == Brightness.dark
                          ? AppColors.heroGradientDark
                          : AppColors.heroGradientLight,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                final height = MediaQuery.of(context).size.height;
                setState(() {
                  _dragging = true;
                  _dragExtent =
                      (_dragExtent + details.delta.dy / height).clamp(0.0, 1.0);
                });
              },
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (_dragExtent > 0.22 || velocity > 700) {
                  Navigator.of(context).maybePop();
                  return;
                }
                setState(() {
                  _dragging = false;
                  _dragExtent = 0;
                });
              },
              child: AnimatedSlide(
                offset: Offset(0, _dragExtent),
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: 1 - (_dragExtent * 0.7),
                  duration: _dragging
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  child: BlocBuilder<PlayerCubit, PlayerState>(
                    builder: (context, state) {
                      final item = state.currentItem;
                      if (item == null) {
                        return const Center(child: Text('مفيش تشغيل حاليًا'));
                      }

                      final progress = state.duration.inMilliseconds == 0
                          ? 0.0
                          : state.position.inMilliseconds /
                              state.duration.inMilliseconds;

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _GlassIconButton(
                                  icon: Icons.keyboard_arrow_down_rounded,
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (state.isPlaying) ...[
                                      EqualizerBars(
                                        isPlaying: state.isPlaying,
                                        height: 12,
                                        color: AppColors.accentGoldSoft,
                                      ),
                                      SizedBox(width: 8.w),
                                    ],
                                    Text('قيد التشغيل',
                                        style:
                                            AppTypography.caption(brightness)),
                                  ],
                                ),
                                _GlassIconButton(
                                  icon: Icons.queue_music_rounded,
                                  onTap: () => QueueSheet.show(context),
                                ),
                              ],
                            ),
                            const Spacer(),
                            NowPlayingArt(
                              reciterId: item.reciterId,
                              letter: item.reciterName.isNotEmpty
                                  ? item.reciterName[0]
                                  : '؟',
                              size: 264.w,
                              isPlaying: state.isPlaying,
                              heroTag: 'reciter-avatar-${item.reciterId}',
                            ),
                            const Spacer(),
                            Text(item.surahArabicName,
                                style: AppTypography.displayLarge(brightness)),
                            SizedBox(height: 6.h),
                            Text(item.reciterName,
                                style: AppTypography.body(brightness)),
                            SizedBox(height: 24.h),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                activeColor: AppColors.primary,
                                inactiveColor:
                                    AppColors.glassBorder(brightness),
                                onChanged: (value) {
                                  final target = state.duration * value;
                                  context.read<PlayerCubit>().seek(target);
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(state.position),
                                    style: AppTypography.caption(brightness)),
                                Text(_formatDuration(state.duration),
                                    style: AppTypography.caption(brightness)),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _GlassIconButton(
                                  icon: Icons.shuffle_rounded,
                                  size: 40,
                                  iconColor:
                                      state.shuffle ? AppColors.primary : null,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context.read<PlayerCubit>().toggleShuffle();
                                  },
                                ),
                                _GlassIconButton(
                                  icon: Icons.skip_previous_rounded,
                                  size: 48,
                                  iconSize: 26,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.read<PlayerCubit>().playPrevious();
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    context
                                        .read<PlayerCubit>()
                                        .togglePlayPause();
                                  },
                                  child: Container(
                                    width: 68.w,
                                    height: 68.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primaryLight,
                                          AppColors.primary
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      state.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 36.sp,
                                    ),
                                  ),
                                ),
                                _GlassIconButton(
                                  icon: Icons.skip_next_rounded,
                                  size: 48,
                                  iconSize: 26,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.read<PlayerCubit>().playNext();
                                  },
                                ),
                                _GlassIconButton(
                                  icon: state.repeatMode == RepeatMode.one
                                      ? Icons.repeat_one_rounded
                                      : Icons.repeat_rounded,
                                  size: 40,
                                  iconColor: state.repeatMode == RepeatMode.off
                                      ? null
                                      : AppColors.primary,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    context
                                        .read<PlayerCubit>()
                                        .cycleRepeatMode();
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _bottomAction(context, Icons.speed_rounded,
                                    '${state.speed}x', () {
                                  _showSpeedSheet(context);
                                }),
                                _bottomAction(context, Icons.bedtime_rounded,
                                    'مؤقت النوم', () {
                                  _showSleepTimerSheet(context);
                                }),
                                _FavoriteBottomAction(
                                    reciterId: item.reciterId),
                                _DownloadBottomAction(item: item),
                              ],
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final brightness = Theme.of(context).brightness;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.label(brightness)),
          ],
        ),
      ),
    );
  }

  void _showSpeedSheet(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) {
            return ListTile(
              title: Text('$speed x'),
              onTap: () {
                cubit.setSpeed(speed);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context) {
    final cubit = context.read<PlayerCubit>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [5, 10, 15, 30, 45, 60].map((minutes) {
            return ListTile(
              title: Text('$minutes دقيقة'),
              onTap: () {
                cubit.setSleepTimer(Duration(minutes: minutes));
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double? iconSize;
  final Color? iconColor;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.w,
        height: size.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill(brightness),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Icon(icon, size: (iconSize ?? size * 0.5).sp, color: iconColor),
      ),
    );
  }
}

class _FavoriteBottomAction extends StatelessWidget {
  final int reciterId;

  const _FavoriteBottomAction({required this.reciterId});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ValueListenableBuilder<Set<int>>(
      valueListenable: FavoritesService.instance.favorites,
      builder: (context, favorites, _) {
        final isFav = favorites.contains(reciterId);
        return InkWell(
          onTap: () => FavoritesService.instance.toggle(reciterId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 22,
                  color: isFav ? AppColors.error : null,
                ),
                const SizedBox(height: 4),
                Text('مفضلة', style: AppTypography.label(brightness)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DownloadBottomAction extends StatelessWidget {
  final QueueItem item;

  const _DownloadBottomAction({required this.item});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ValueListenableBuilder<Map<String, DownloadState>>(
      valueListenable: DownloadService.instance.states,
      builder: (context, states, _) {
        final downloaded = DownloadService.instance.isDownloaded(item.key);
        final state = states[item.key] ?? const DownloadState();

        if (state.isDownloading) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    value: state.progress > 0 ? state.progress : null,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('جاري التحميل', style: AppTypography.label(brightness)),
              ],
            ),
          );
        }

        return InkWell(
          onTap: () => downloaded
              ? DownloadService.instance.deleteDownload(item.key)
              : DownloadService.instance.download(item.key, item.audioUrl),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Icon(
                  downloaded
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                  size: 22,
                  color: downloaded ? AppColors.success : null,
                ),
                const SizedBox(height: 4),
                Text(downloaded ? 'محمّلة' : 'تحميل',
                    style: AppTypography.label(brightness)),
              ],
            ),
          ),
        );
      },
    );
  }
}
