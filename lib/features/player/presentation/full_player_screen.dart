import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../cubit/player_cubit.dart';
import '../cubit/player_state.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 32),
                        ),
                        Text('قيد التشغيل',
                            style: AppTypography.caption(brightness)),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 280.w,
                      height: 280.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: AppColors.goldGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.25),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          size: 96, color: Colors.black87),
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
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.glassBorder(brightness),
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
                        IconButton(
                          onPressed: () =>
                              context.read<PlayerCubit>().toggleShuffle(),
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color: state.shuffle ? AppColors.primary : null,
                          ),
                        ),
                        IconButton(
                          iconSize: 36,
                          onPressed: () =>
                              context.read<PlayerCubit>().playPrevious(),
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.read<PlayerCubit>().togglePlayPause(),
                          child: Container(
                            width: 68.w,
                            height: 68.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
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
                        IconButton(
                          iconSize: 36,
                          onPressed: () =>
                              context.read<PlayerCubit>().playNext(),
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<PlayerCubit>().cycleRepeatMode(),
                          icon: Icon(
                            state.repeatMode == RepeatMode.one
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            color: state.repeatMode == RepeatMode.off
                                ? null
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _bottomAction(
                            context, Icons.speed_rounded, '${state.speed}x',
                            () {
                          _showSpeedSheet(context);
                        }),
                        _bottomAction(
                            context, Icons.bedtime_rounded, 'مؤقت النوم', () {
                          _showSleepTimerSheet(context);
                        }),
                        _bottomAction(context, Icons.favorite_border_rounded,
                            'مفضلة', () {}),
                        _bottomAction(
                            context, Icons.download_rounded, 'تحميل', () {}),
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
