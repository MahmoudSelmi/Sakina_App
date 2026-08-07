import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_premium/shared/widgets/NotificationService.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/surah_data.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/utils/arabic_text.dart';
import '../../../core/utils/mood_playlist_builder.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/reassurance_banner.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/reciter_avatar.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../favorites/data/favorites_service.dart';
import '../../favorites/data/surah_favorites_service.dart';
import '../../khatma/data/khatma_service.dart';
import '../../khatma/presentation/khatma_screen.dart';
import '../../moods/presentation/mood_screen.dart';
import '../../player/cubit/player_cubit.dart';
import '../../player/cubit/player_state.dart';
import '../../player/data/queue_item.dart';
import '../../player/presentation/mini_player.dart';
import '../../playlists/data/playlist_model.dart';
import '../../playlists/data/playlists_service.dart';
import '../../playlists/presentation/playlist_detail_screen.dart';
import '../../playlists/presentation/playlists_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../recently_played/data/recently_played_service.dart';
import '../../streak/data/streak_service.dart';
import '../../reciters/data/models/reciter_model.dart';
import '../../reciters/domain/repositories/reciters_repository.dart';
import '../../reciters/presentation/reciter_detail_screen.dart';
import '../../surahs/presentation/surah_browse_screen.dart';
import '../../surahs/presentation/surah_reciters_screen.dart';

class HomeScreen extends StatefulWidget {
  final RecitersRepository repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeTab { all, favorites }

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<List<ReciterModel>> _recitersFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _searchFocused = false;
  bool _showReassurance = true;
  _HomeTab _tab = _HomeTab.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    KhatmaService.instance.onKhatmaCompleted = (count) {
      if (mounted) _showKhatmaCelebration(count);
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // لما التطبيق يروح للخلفية، نجدول تذكير لطيف بعد 24 ساعة لو ماسمعش؛
    // ولما يرجع تاني، نلغي التذكير عشان مايوصلوش وهو مستخدم بالفعل.
    if (state == AppLifecycleState.paused) {
      NotificationService.instance.scheduleComeBackReminder();
    } else if (state == AppLifecycleState.resumed) {
      NotificationService.instance.cancelComeBackReminder();
    }
  }

  void _showKhatmaCelebration(int count) {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: brightness == Brightness.dark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(colors: AppColors.goldGradient)
                      .createShader(bounds),
              child: Icon(Icons.auto_awesome_rounded,
                  size: 48.sp, color: Colors.white),
            ),
            SizedBox(height: 14.h),
            Text('بارك الله فيك! 🎉', style: AppTypography.title(brightness)),
            SizedBox(height: 8.h),
            Text(
              'خلّصت الختمة رقم $count كاملة بفضل الله',
              textAlign: TextAlign.center,
              style: AppTypography.body(brightness),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.glassFill(brightness),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'اللهم ارحمنا بالقرآن، واجعله لنا إمامًا ونورًا وهدىً ورحمة،\n'
                'اللهم ذكّرنا منه ما نُسِّينا، وعلّمنا منه ما جهلنا،\n'
                'وارزقنا تلاوته آناء الليل وأطراف النهار، واجعله لنا حجة يا رب العالمين',
                textAlign: TextAlign.center,
                style: AppTypography.caption(brightness).copyWith(height: 1.8),
              ),
            ),
            SizedBox(height: 18.h),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('الحمد لله'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    KhatmaService.instance.onKhatmaCompleted = null;
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
            ValueListenableBuilder<bool>(
              valueListenable: ConnectivityService.instance.isOnline,
              builder: (context, online, _) {
                if (online) return const SizedBox.shrink();
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8.w),
                          Text('مفيش اتصال بالإنترنت دلوقتي',
                              style: AppTypography.caption(brightness)
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_showReassurance)
              BlocBuilder<PlayerCubit, PlayerState>(
                buildWhen: (prev, curr) => prev.currentItem != curr.currentItem,
                builder: (context, playerState) {
                  final hasMiniPlayer = playerState.currentItem != null;
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: hasMiniPlayer ? 88.h : 8.h,
                    child: ReassuranceBanner(
                      onDismiss: () => setState(() => _showReassurance = false),
                    ),
                  );
                },
              ),
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
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text('استكمل رحلتك مع القرآن',
                          style: AppTypography.body(brightness)),
                      SizedBox(height: 18.h),
                      _buildSearchBar(brightness),
                      SizedBox(height: 14.h),
                      _buildQuickAccessRow(brightness, reciters),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(child: _buildKhatmaCard(brightness)),
                          SizedBox(width: 10.w),
                          _buildStreakCard(brightness),
                        ],
                      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StaggeredFadeIn(
                        index: 1,
                        child: _sectionTitle(brightness, 'أجواء تناسبك')),
                    SizedBox(
                      height: 108.h,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: Mood.values.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12.w),
                        itemBuilder: (context, index) => StaggeredFadeIn(
                          index: index + 2,
                          direction: Axis.horizontal,
                          child: _MoodCard(
                              mood: Mood.values[index], reciters: reciters),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
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
            if (_query.isNotEmpty)
              SliverToBoxAdapter(
                child:
                    _buildUnifiedSearchResults(context, brightness, reciters),
              ),
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

  /// نتايج بحث موحّدة: لو المستخدم كتب اسم سورة أو رقمها بدل اسم قارئ،
  /// أو اسم قايمة تشغيل عنده، يلاقيها هنا فوق قايمة القراء المفلترة -
  /// بدل ما يحس إنه في مكان غلط.
  Widget _buildUnifiedSearchResults(
    BuildContext context,
    Brightness brightness,
    List<ReciterModel> reciters,
  ) {
    final matchingSurahs = SurahData.all
        .where((s) =>
            s.number.toString() == _query ||
            ArabicText.contains(s.arabicName, _query))
        .take(5)
        .toList();

    return ValueListenableBuilder<List<Playlist>>(
      valueListenable: PlaylistsService.instance.playlists,
      builder: (context, playlists, _) {
        final matchingPlaylists = playlists
            .where((p) => ArabicText.contains(p.name, _query))
            .take(5)
            .toList();

        if (matchingSurahs.isEmpty && matchingPlaylists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (matchingSurahs.isNotEmpty) ...[
              _sectionTitle(brightness, 'سور مطابقة'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: matchingSurahs.map((surah) {
                    final count = reciters
                        .where((r) =>
                            r.moshaf.any((m) => m.hasSurah(surah.number)))
                        .length;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Material(
                        color: AppColors.glassFill(brightness),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: count == 0
                              ? null
                              : () => Navigator.of(context).push(fadeScaleRoute(
                                    SurahRecitersScreen(
                                      surahNumber: surah.number,
                                      surahName: surah.arabicName,
                                      reciters: reciters,
                                    ),
                                  )),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 11.h),
                            child: Row(
                              children: [
                                Icon(Icons.menu_book_rounded,
                                    size: 17.sp,
                                    color: AppColors.accentGoldSoft),
                                SizedBox(width: 10.w),
                                Expanded(
                                    child: Text(surah.arabicName,
                                        style: AppTypography.body(brightness))),
                                Text('$count قارئ',
                                    style: AppTypography.caption(brightness)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 12.h),
            ],
            if (matchingPlaylists.isNotEmpty) ...[
              _sectionTitle(brightness, 'قوائمك المطابقة'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: matchingPlaylists.map((playlist) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Material(
                        color: AppColors.glassFill(brightness),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(
                            fadeScaleRoute(
                                PlaylistDetailScreen(playlistId: playlist.id)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 11.h),
                            child: Row(
                              children: [
                                Icon(Icons.queue_music_rounded,
                                    size: 17.sp,
                                    color: AppColors.accentGoldSoft),
                                SizedBox(width: 10.w),
                                Expanded(
                                    child: Text(playlist.name,
                                        style: AppTypography.body(brightness))),
                                Text('${playlist.items.length} سورة',
                                    style: AppTypography.caption(brightness)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 12.h),
            ],
            _sectionTitle(brightness, 'القراء'),
          ],
        );
      },
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

  Widget _buildQuickAccessRow(
      Brightness brightness, List<ReciterModel> reciters) {
    final chips = [
      (
        icon: Icons.queue_music_rounded,
        label: 'قوائمي',
        onTap: () =>
            Navigator.of(context).push(fadeScaleRoute(const PlaylistsScreen())),
      ),
      (
        icon: Icons.self_improvement_rounded,
        label: 'أجواء',
        onTap: () {
          final hour = DateTime.now().hour;
          final suggested = (hour >= 21 || hour < 6) ? Mood.sleep : Mood.work;
          Navigator.of(context).push(
              fadeScaleRoute(MoodScreen(mood: suggested, reciters: reciters)));
        },
      ),
    ];

    return Row(
      children: [
        for (final chip in chips) ...[
          Expanded(
            child: GestureDetector(
              onTap: chip.onTap,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.glassFill(brightness),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder(brightness)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(chip.icon,
                        size: 18.sp, color: AppColors.accentGoldSoft),
                    SizedBox(height: 4.h),
                    Text(chip.label, style: AppTypography.caption(brightness)),
                  ],
                ),
              ),
            ),
          ),
          if (chip != chips.last) SizedBox(width: 10.w),
        ],
      ],
    );
  }

  Widget _buildKhatmaCard(Brightness brightness) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: KhatmaService.instance.completedSurahs,
      builder: (context, completed, _) {
        final progress = completed.length / KhatmaService.totalSurahs;
        return GestureDetector(
          onTap: () =>
              Navigator.of(context).push(fadeScaleRoute(const KhatmaScreen())),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.glassFill(brightness),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder(brightness)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40.w,
                  height: 40.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 40.w,
                        height: 40.w,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: AppColors.glassBorder(brightness),
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.accentGold),
                        ),
                      ),
                      Icon(Icons.auto_stories_rounded,
                          size: 16.sp, color: AppColors.accentGoldSoft),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ختمتي',
                          style: AppTypography.body(brightness)
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        '${completed.length} من ${KhatmaService.totalSurahs} سورة',
                        style: AppTypography.caption(brightness),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: AppColors.primary, size: 22.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakCard(Brightness brightness) {
    return ValueListenableBuilder<int>(
      valueListenable: StreakService.instance.currentStreak,
      builder: (context, streak, _) {
        return Container(
          width: 84.w,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder(brightness)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(streak > 0 ? '🔥' : '💤', style: TextStyle(fontSize: 22.sp)),
              SizedBox(height: 4.h),
              Text(
                '$streak',
                style: AppTypography.title(brightness)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              Text('يوم متواصل',
                  style: AppTypography.caption(brightness),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      },
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
    return Semantics(
      button: true,
      label: 'تصفح بالسورة',
      child: GestureDetector(
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
      ),
    );
  }
}

/// زرار البروفايل - بيودّي على شاشة البروفايل (الثيم، التحميلات،
/// الإعدادات، ختمتك، وعن المطوّر - كل حاجة شخصية في مكان واحد).
class _ProfileButton extends StatelessWidget {
  final Brightness brightness;

  const _ProfileButton({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'البروفايل',
      child: GestureDetector(
        onTap: () =>
            Navigator.of(context).push(fadeScaleRoute(const ProfileScreen())),
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
      ),
    );
  }
}

/// كارت مصغّر بيتستخدم في شريطي "استكمل الاستماع" و"سورك المفضلة" - بيعرض
/// السورة والقارئ وبيشغّلها فورًا لما تدوس عليه.
/// كارت "أجواء" (نوم/مذاكرة/شغل/جيم) في الشاشة الرئيسية - كل كارت بلونه
/// المميز، بيودّي على قائمة تشغيل جاهزة تناسب الأجواء دي.
class _MoodCard extends StatelessWidget {
  final Mood mood;
  final List<ReciterModel> reciters;

  const _MoodCard({required this.mood, required this.reciters});

  @override
  Widget build(BuildContext context) {
    final info = MoodCatalog.all[mood]!;

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(fadeScaleRoute(MoodScreen(mood: mood, reciters: reciters))),
      child: Container(
        width: 128.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: info.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(info.icon, color: Colors.white, size: 26.sp),
            Text(
              info.title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
