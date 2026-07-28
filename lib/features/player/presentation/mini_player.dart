import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/now_playing_visuals.dart';
import '../cubit/player_cubit.dart';
import '../cubit/player_state.dart';
import 'full_player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return BlocBuilder<PlayerCubit, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.currentItem != curr.currentItem ||
          prev.status != curr.status ||
          prev.position != curr.position ||
          prev.duration != curr.duration,
      builder: (context, state) {
        final item = state.currentItem;
        if (item == null) return const SizedBox.shrink();

        final progress = state.duration.inMilliseconds == 0
            ? 0.0
            : state.position.inMilliseconds / state.duration.inMilliseconds;

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (_, anim, __) => FadeTransition(
                opacity: anim,
                child: const FullPlayerScreen(),
              ),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: GlassCard(
              borderRadius: 20,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      NowPlayingArt(
                        reciterId: item.reciterId,
                        letter: item.reciterName.isNotEmpty ? item.reciterName[0] : '؟',
                        size: 40.w,
                        isPlaying: state.isPlaying,
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.surahArabicName,
                                    style: AppTypography.title(brightness),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (state.isPlaying) ...[
                                  SizedBox(width: 8.w),
                                  EqualizerBars(
                                    isPlaying: state.isPlaying,
                                    height: 12,
                                    color: AppColors.primaryLight,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              item.reciterName,
                              style: AppTypography.caption(brightness),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => context.read<PlayerCubit>().togglePlayPause(),
                        child: Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.primaryLight, AppColors.primary],
                            ),
                          ),
                          child: Icon(
                            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 24.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.read<PlayerCubit>().playNext(),
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: AppColors.glassBorder(brightness),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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
