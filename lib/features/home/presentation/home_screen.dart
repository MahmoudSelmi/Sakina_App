import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../favorites/data/favorites_service.dart';
import '../../player/presentation/mini_player.dart';
import '../../reciters/data/models/reciter_model.dart';
import '../../reciters/domain/repositories/reciters_repository.dart';
import '../../reciters/presentation/reciter_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final RecitersRepository repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeTab { all, favorites }

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ReciterModel>> _recitersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _HomeTab _tab = _HomeTab.all;

  @override
  void initState() {
    super.initState();
    _recitersFuture = widget.repository.getReciters();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final popular = reciters.take(12).toList();

    return ValueListenableBuilder<Set<int>>(
      valueListenable: FavoritesService.instance.favorites,
      builder: (context, favoriteIds, _) {
        final filtered = reciters.where((r) {
          final matchesQuery = _query.isEmpty || r.name.contains(_query);
          final matchesTab = _tab == _HomeTab.all || favoriteIds.contains(r.id);
          return matchesQuery && matchesTab;
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
              sliver: SliverToBoxAdapter(
                child: StaggeredFadeIn(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('السلام عليكم 👋', style: AppTypography.headline(brightness)),
                      SizedBox(height: 4.h),
                      Text('استكمل رحلتك مع القرآن', style: AppTypography.body(brightness)),
                      SizedBox(height: 18.h),
                      _buildSearchBar(brightness),
                      SizedBox(height: 16.h),
                      _buildTabSwitch(brightness, favoriteIds.length),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
            if (_tab == _HomeTab.all && _query.isEmpty) ...[
              SliverToBoxAdapter(
                child: StaggeredFadeIn(index: 1, child: _sectionTitle(brightness, 'قراء مميزون')),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 168.h,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    scrollDirection: Axis.horizontal,
                    itemCount: popular.length,
                    separatorBuilder: (_, __) => SizedBox(width: 14.w),
                    itemBuilder: (context, index) => StaggeredFadeIn(
                      index: index + 2,
                      direction: Axis.horizontal,
                      child: _ReciterFeatureCard(reciter: popular[index]),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(
                child: StaggeredFadeIn(index: 2, child: _sectionTitle(brightness, 'كل القراء')),
              ),
            ],
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          _tab == _HomeTab.favorites
                              ? Icons.favorite_border_rounded
                              : Icons.search_off_rounded,
                          size: 40.sp,
                          color: AppColors.textSecondaryDark,
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          _tab == _HomeTab.favorites
                              ? 'مفيش قراء في المفضلة لسه'
                              : 'مفيش نتايج',
                          style: AppTypography.body(brightness),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 120.h),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) => StaggeredFadeIn(
                    index: index,
                    stepDelay: const Duration(milliseconds: 25),
                    child: _ReciterListTile(reciter: filtered[index]),
                  ),
                ),
              ),
          ],
        );
      },
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder(brightness)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textSecondaryDark, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTypography.body(brightness),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'دور على قارئ',
                hintStyle: AppTypography.body(brightness).copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: Icon(Icons.close_rounded, color: AppColors.textSecondaryDark, size: 18.sp),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSwitch(Brightness brightness, int favoritesCount) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder(brightness)),
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton(brightness, 'الكل', _HomeTab.all)),
          Expanded(
            child: _tabButton(
              brightness,
              favoritesCount > 0 ? 'المفضلة ($favoritesCount)' : 'المفضلة',
              _HomeTab.favorites,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(Brightness brightness, String label, _HomeTab tab) {
    final selected = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.body(brightness).copyWith(
            color: selected ? Colors.white : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
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

/// كارت القارئ في سلايدر "قراء مميزون" - فيه حركة ضغط بسيطة (scale) بتدي
/// إحساس تفاعلي حقيقي.
class _ReciterFeatureCard extends StatefulWidget {
  final ReciterModel reciter;

  const _ReciterFeatureCard({required this.reciter});

  @override
  State<_ReciterFeatureCard> createState() => _ReciterFeatureCardState();
}

class _ReciterFeatureCardState extends State<_ReciterFeatureCard> {
  double _scale = 1.0;

  void _open(BuildContext context) {
    Navigator.of(context).push(fadeScaleRoute(ReciterDetailScreen(reciter: widget.reciter)));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final reciter = widget.reciter;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTap: () => _open(context),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 118.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.glassBorder(brightness)),
          ),
          child: Column(
            children: [
              ReciterAvatar(
                reciterId: reciter.id,
                letter: reciter.letter,
                size: 66.w,
                ring: true,
              ),
              SizedBox(height: 10.h),
              Text(
                reciter.name,
                style: AppTypography.caption(brightness).copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف القارئ في القائمة الرئيسية، مع زرار مفضلة سريع.
class _ReciterListTile extends StatelessWidget {
  final ReciterModel reciter;

  const _ReciterListTile({required this.reciter});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Material(
      color: AppColors.glassFill(brightness),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(fadeScaleRoute(ReciterDetailScreen(reciter: reciter))),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              ReciterAvatar(
                reciterId: reciter.id,
                letter: reciter.letter,
                size: 44.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(reciter.name, style: AppTypography.body(brightness)),
              ),
              ValueListenableBuilder<Set<int>>(
                valueListenable: FavoritesService.instance.favorites,
                builder: (context, favorites, _) {
                  final isFav = favorites.contains(reciter.id);
                  return IconButton(
                    onPressed: () => FavoritesService.instance.toggle(reciter.id),
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.error : AppColors.textSecondaryDark,
                      size: 20.sp,
                    ),
                  );
                },
              ),
              Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 24.sp),
            ],
          ),
        ),
      ),
    );
  }
}
