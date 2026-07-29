import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/arabic_text.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../about/presentation/about_screen.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../favorites/data/favorites_service.dart';
import '../../favorites/data/surah_favorites_service.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/data/queue_item.dart';
import '../../player/presentation/mini_player.dart';
import '../../recently_played/data/recently_played_service.dart';
import '../../reciters/data/models/reciter_model.dart';
import '../../reciters/domain/repositories/reciters_repository.dart';
import '../../reciters/presentation/reciter_detail_screen.dart';
import '../../surahs/presentation/surah_browse_screen.dart';

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
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _searchFocused = false;
  _HomeTab _tab = _HomeTab.all;

  @override
  void initState() {
    super.initState();
    _recitersFuture = widget.repository.getReciters();
    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => _query = _searchController.text.trim());
      });
    });
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
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

  Widget _buildContent(BuildContext context, Brightness brightness,
      List<ReciterModel> reciters) {
    final popular = reciters.take(12).toList();

    return ValueListenableBuilder<Set<int>>(
      valueListenable: FavoritesService.instance.favorites,
      builder: (context, favoriteIds, _) {
        final filtered = reciters.where((r) {
          final matchesQuery = ArabicText.contains(r.name, _query);
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
                      Row(
                        children: [
                          const Expanded(child: AppLogo()),
                          _SurahBrowseButton(
                              brightness: brightness, reciters: reciters),
                          SizedBox(width: 8.w),
                          _ProfileButton(brightness: brightness),
                          SizedBox(width: 8.w),
                          _ThemeToggleButton(brightness: brightness),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text('استكمل رحلتك مع القرآن',
                          style: AppTypography.body(brightness)),
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
                child: ValueListenableBuilder<List<QueueItem>>(
                  valueListenable: RecentlyPlayedService.instance.items,
                  builder: (context, recent, _) {
                    if (recent.isEmpty) return const SizedBox.shrink();
                    final items = recent.take(10).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StaggeredFadeIn(
                          index: 1,
                          child: _sectionTitle(brightness, 'استكمل الاستماع'),
                        ),
                        SizedBox(
                          height: 96.h,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => SizedBox(width: 12.w),
                            itemBuilder: (context, index) => StaggeredFadeIn(
                              index: index + 2,
                              direction: Axis.horizontal,
                              child: _ContinueListeningCard(item: items[index]),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: ValueListenableBuilder<Map<String, QueueItem>>(
                  valueListenable: SurahFavoritesService.instance.favorites,
                  builder: (context, favMap, _) {
                    if (favMap.isEmpty) return const SizedBox.shrink();
                    final items = favMap.values.toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StaggeredFadeIn(
                          index: 1,
                          child: _sectionTitle(brightness, 'سورك المفضلة'),
                        ),
                        SizedBox(
                          height: 96.h,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => SizedBox(width: 12.w),
                            itemBuilder: (context, index) => StaggeredFadeIn(
                              index: index + 2,
                              direction: Axis.horizontal,
                              child: _ContinueListeningCard(
                                  item: items[index], isFavoriteCard: true),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: StaggeredFadeIn(
                    index: 1, child: _sectionTitle(brightness, 'قراء مميزون')),
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
                child: StaggeredFadeIn(
                    index: 2, child: _sectionTitle(brightness, 'كل القراء')),
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
                          color: brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
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
    final secondary = brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _searchFocused
              ? AppColors.primaryLight
              : AppColors.glassBorder(brightness),
          width: _searchFocused ? 1.4 : 1,
        ),
        boxShadow: _searchFocused
            ? [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: _searchFocused ? AppColors.primaryLight : secondary,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              style: AppTypography.body(brightness),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'دور على قارئ بالاسم...',
                hintStyle:
                    AppTypography.body(brightness).copyWith(color: secondary),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondary.withValues(alpha: 0.15),
                ),
                child: Icon(Icons.close_rounded, color: secondary, size: 15.sp),
              ),
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
          Icon(
            Icons.wifi_off_rounded,
            size: 48.sp,
            color: brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          SizedBox(height: 12.h),
          Text('في مشكلة في الاتصال', style: AppTypography.body(brightness)),
          SizedBox(height: 12.h),
          ElevatedButton(
              onPressed: _refresh, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

/// زرار "تصفح بالسورة" - بيودّي على شاشة اختيار السورة الأول ثم القارئ.
class _SurahBrowseButton extends StatelessWidget {
  final Brightness brightness;
  final List<ReciterModel> reciters;

  const _SurahBrowseButton({required this.brightness, required this.reciters});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(fadeScaleRoute(SurahBrowseScreen(reciters: reciters))),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill(brightness),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Icon(
          Icons.menu_book_rounded,
          size: 19.sp,
          color: AppColors.accentGoldSoft,
        ),
      ),
    );
  }
}

/// زرار البروفايل - بيودّي على شاشة "عن المطوّر".
class _ProfileButton extends StatelessWidget {
  final Brightness brightness;

  const _ProfileButton({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).push(fadeScaleRoute(const AboutScreen())),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill(brightness),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Icon(
          Icons.person_rounded,
          size: 20.sp,
          color: brightness == Brightness.dark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

/// زرار تبديل الوضع الليلي/النهاري، بأيقونة بتتغير بحركة ناعمة.
class _ThemeToggleButton extends StatelessWidget {
  final Brightness brightness;

  const _ThemeToggleButton({required this.brightness});

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => ThemeController.instance.toggle(),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill(brightness),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark),
              size: 20.sp,
              color: isDark ? AppColors.accentGoldSoft : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// كارت مصغّر بيتستخدم في شريطي "استكمل الاستماع" و"سورك المفضلة" - بيعرض
/// السورة والقارئ وبيشغّلها فورًا لما تدوس عليه.
class _ContinueListeningCard extends StatelessWidget {
  final QueueItem item;
  final bool isFavoriteCard;

  const _ContinueListeningCard(
      {required this.item, this.isFavoriteCard = false});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: () => context.read<PlayerCubit>().playSingle(item),
      child: Container(
        width: 220.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.glassFill(brightness),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Row(
          children: [
            ReciterAvatar(
              reciterId: item.reciterId,
              letter: item.reciterName.isNotEmpty ? item.reciterName[0] : '؟',
              size: 52.w,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.surahArabicName,
                    style: AppTypography.body(brightness)
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.reciterName,
                    style: AppTypography.caption(brightness),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isFavoriteCard
                  ? Icons.favorite_rounded
                  : Icons.play_circle_fill_rounded,
              color: isFavoriteCard ? AppColors.error : AppColors.primary,
              size: 22.sp,
            ),
          ],
        ),
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
    Navigator.of(context)
        .push(fadeScaleRoute(ReciterDetailScreen(reciter: widget.reciter)));
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
                style: AppTypography.caption(brightness)
                    .copyWith(fontWeight: FontWeight.w600),
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
                child:
                    Text(reciter.name, style: AppTypography.body(brightness)),
              ),
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
                      color: isFav
                          ? AppColors.error
                          : (brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                      size: 20.sp,
                    ),
                  );
                },
              ),
              Icon(Icons.chevron_left_rounded,
                  color: AppColors.primary, size: 24.sp),
            ],
          ),
        ),
      ),
    );
  }
}
