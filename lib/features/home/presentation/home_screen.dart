import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../player/presentation/mini_player.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/data/queue_item.dart';
import '../../reciters/data/models/reciter_model.dart';
import '../../reciters/domain/repositories/reciters_repository.dart';

class HomeScreen extends StatefulWidget {
  final RecitersRepository repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ReciterModel>> _recitersFuture;

  @override
  void initState() {
    super.initState();
    _recitersFuture = widget.repository.getReciters();
  }

  Future<void> _refresh() async {
    setState(() {
      _recitersFuture = widget.repository.getReciters(forceRefresh: true);
    });
    await _recitersFuture;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<ReciterModel>>(
                future: _recitersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeleton(brightness);
                  }
                  if (snapshot.hasError) {
                    return _buildError(brightness);
                  }
                  final reciters = snapshot.data ?? [];
                  return _buildContent(context, brightness, reciters);
                },
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 8, child: MiniPlayer()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Brightness brightness, List<ReciterModel> reciters) {
    final popular = reciters.take(10).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السلام عليكم 👋', style: AppTypography.headline(brightness)),
                SizedBox(height: 4.h),
                Text('استكمل رحلتك مع القرآن', style: AppTypography.body(brightness)),
                SizedBox(height: 20.h),
                _buildSearchBar(brightness),
                SizedBox(height: 28.h),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _sectionTitle(brightness, 'قراء مميزون'),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 150.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (_, __) => SizedBox(width: 14.w),
              itemBuilder: (context, index) => _reciterCard(context, brightness, popular[index]),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        SliverToBoxAdapter(
          child: _sectionTitle(brightness, 'كل القراء'),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 120.h),
          sliver: SliverList.separated(
            itemCount: reciters.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) => _reciterListTile(context, brightness, reciters[index]),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(Brightness brightness, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      child: Text(title, style: AppTypography.title(brightness)),
    );
  }

  Widget _buildSearchBar(Brightness brightness) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder(brightness)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textSecondaryDark, size: 20.sp),
          SizedBox(width: 10.w),
          Text('دور على قارئ أو سورة', style: AppTypography.body(brightness)),
        ],
      ),
    );
  }

  Widget _reciterCard(BuildContext context, Brightness brightness, ReciterModel reciter) {
    return GestureDetector(
      onTap: () => _playFirstSurah(context, reciter),
      child: Container(
        width: 110.w,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.glassFill(brightness),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Column(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.goldGradient),
              ),
              alignment: Alignment.center,
              child: Text(
                reciter.letter,
                style: AppTypography.title(Brightness.dark).copyWith(color: Colors.black87),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              reciter.name,
              style: AppTypography.caption(brightness),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reciterListTile(BuildContext context, Brightness brightness, ReciterModel reciter) {
    return Material(
      color: AppColors.glassFill(brightness),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _playFirstSurah(context, reciter),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(reciter.letter, style: AppTypography.body(brightness)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(reciter.name, style: AppTypography.body(brightness)),
              ),
              Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 24.sp),
            ],
          ),
        ),
      ),
    );
  }

  void _playFirstSurah(BuildContext context, ReciterModel reciter) {
    final moshaf = reciter.defaultMoshaf;
    if (moshaf == null || moshaf.surahList.isEmpty) return;

    final firstSurah = moshaf.surahList.first;
    final queue = moshaf.surahList
        .map((s) => QueueItem.fromReciter(reciter: reciter, moshaf: moshaf, surahNumber: s))
        .toList();

    final startIndex = queue.indexWhere((q) => q.surahNumber == firstSurah);
    context.read<PlayerCubit>().playQueue(queue, startIndex: startIndex);
  }

  Widget _buildSkeleton(Brightness brightness) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Shimmer.fromColors(
          baseColor: AppColors.glassFill(brightness),
          highlightColor: AppColors.glassBorder(brightness),
          child: Container(
            height: 64.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(Brightness brightness) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48.sp, color: AppColors.textSecondaryDark),
          SizedBox(height: 12.h),
          Text('في مشكلة في الاتصال', style: AppTypography.body(brightness)),
          SizedBox(height: 12.h),
          ElevatedButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
