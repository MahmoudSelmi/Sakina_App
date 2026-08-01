import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/moshaf_style.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../favorites/data/surah_favorites_service.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/data/queue_item.dart';
import '../../reciters/data/models/reciter_model.dart';
import '../../reciters/data/models/moshaf_model.dart';

class _Entry {
  final ReciterModel reciter;
  final MoshafModel moshaf;
  const _Entry(this.reciter, this.moshaf);
}

/// شاشة بتعرض كل القراء (وكل رواية عندهم) اللي سجلوا سورة معينة، عشان
/// المستخدم يختار مين يسمعها بصوته.
class SurahRecitersScreen extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final List<ReciterModel> reciters;

  const SurahRecitersScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.reciters,
  });

  List<_Entry> get _entries {
    final list = <_Entry>[];
    for (final r in reciters) {
      for (final m in r.moshaf) {
        if (m.hasSurah(surahNumber)) list.add(_Entry(r, m));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final entries = _entries;

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
                          Text('سورة $surahName', style: AppTypography.title(brightness)),
                          Text('${entries.length} تسجيل متاح', style: AppTypography.caption(brightness)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final item = QueueItem.fromReciter(
                      reciter: entry.reciter,
                      moshaf: entry.moshaf,
                      surahNumber: surahNumber,
                    );
                    return StaggeredFadeIn(
                      index: index,
                      stepDelay: const Duration(milliseconds: 20),
                      child: _EntryTile(reciter: entry.reciter, moshaf: entry.moshaf, item: item),
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

class _EntryTile extends StatelessWidget {
  final ReciterModel reciter;
  final MoshafModel moshaf;
  final QueueItem item;

  const _EntryTile({required this.reciter, required this.moshaf, required this.item});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Material(
      color: AppColors.glassFill(brightness),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<PlayerCubit>().playSingle(item),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              ReciterAvatar(reciterId: reciter.id, letter: reciter.letter, size: 44.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reciter.name, style: AppTypography.body(brightness)),
                    Row(
                      children: [
                        Icon(
                          MoshafStyle.iconFor(moshaf.name),
                          size: 13.sp,
                          color: AppColors.accentGoldSoft,
                        ),
                        SizedBox(width: 4.w),
                        Text(moshaf.name, style: AppTypography.caption(brightness)),
                      ],
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<Map<String, QueueItem>>(
                valueListenable: SurahFavoritesService.instance.favorites,
                builder: (context, favs, _) {
                  final isFav = favs.containsKey(item.key);
                  return IconButton(
                    onPressed: () => SurahFavoritesService.instance.toggle(item),
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.error : AppColors.accentGoldSoft,
                      size: 19.sp,
                    ),
                  );
                },
              ),
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
                ),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
