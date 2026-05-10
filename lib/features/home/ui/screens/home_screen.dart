import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakina_app/features/home/logic/audio_player_cubit.dart';
import 'package:sakina_app/features/home/logic/player_state.dart';
import '../../../../core/theming/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient لعمق التصميم
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), ColorsManager.mainDark],
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildSheikhsSection(context),
              _buildSectionTitle('المقاطع الشائعة'),
              _buildSurahList(context),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _buildBottomSpotifyPlayer(context),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 50.h, 24.w, 20.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك،',
                  style: TextStyle(
                    color: ColorsManager.textGrey,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  'محمود السلمي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ColorsManager.accentGold,
              ),
              child: CircleAvatar(
                radius: 22.r,
                backgroundColor: ColorsManager.surfaceLight,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheikhsSection(BuildContext context) {
    final sheikhs = [
      {
        'name': 'المنشاوي',
        'img': 'https://i.ibb.co/L8mYf5M/menshawi.jpg',
        'url': 'https://www.youtube.com/watch?v=N_vGv8-D0pY',
      },
      {
        'name': 'الحصري',
        'img': 'https://i.ibb.co/pX7XyYy/hussary.jpg',
        'url': 'https://www.youtube.com/watch?v=eYf9z_O9VfI',
      },
      {
        'name': 'عبد الباسط',
        'img': 'https://i.ibb.co/vY5XyYy/basit.jpg',
        'url': 'https://www.youtube.com/watch?v=P2rY7mC_z0s',
      },
    ];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: sheikhs.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => context.read<PlayerCubit>().playStream(
                sheikhs[index]['url']!,
                sheikhs[index]['name']!,
                'تلاوة مختارة',
                sheikhs[index]['img']!,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ColorsManager.accentGold.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40.r,
                        backgroundImage: NetworkImage(sheikhs[index]['img']!),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      sheikhs[index]['name']!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 30.h, 24.w, 15.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'عرض الكل',
              style: TextStyle(
                color: ColorsManager.accentGold,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahList(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildSurahItem(
          context,
          'سورة البقرة',
          'الشيخ المنشاوي',
          'https://i.ibb.co/L8mYf5M/menshawi.jpg',
        ),
        childCount: 8,
      ),
    );
  }

  Widget _buildSurahItem(
    BuildContext context,
    String title,
    String sheikh,
    String img,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: InkWell(
        onTap: () => context.read<PlayerCubit>().playStream(
          'https://www.youtube.com/watch?v=N_vGv8-D0pY',
          title,
          sheikh,
          img,
        ),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: ColorsManager.surfaceLight.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  img,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      sheikh,
                      style: TextStyle(
                        color: ColorsManager.textGrey,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: ColorsManager.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSpotifyPlayer(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (state is! PlayerReady) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {
              /* هنا تفتح صفحة الـ Full Player */
            },
            child: Container(
              height: 75.h,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: ColorsManager.surfaceLight,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundImage: NetworkImage(state.imgUrl),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          state.sheikhName,
                          style: TextStyle(
                            color: ColorsManager.textGrey,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => context.read<PlayerCubit>().togglePlay(),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: ColorsManager.textGrey,
                      size: 20,
                    ),
                    onPressed: () => context.read<PlayerCubit>().stop(),
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
