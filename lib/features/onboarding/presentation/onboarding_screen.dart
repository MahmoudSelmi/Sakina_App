import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../reciters/data/datasources/reciters_remote_data_source.dart';
import '../../reciters/data/repositories/reciters_repository_impl.dart';
import '../../home/presentation/home_screen.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardPage({required this.icon, required this.title, required this.body});
}

/// جولة تعريفية سريعة بتتعرض أول مرة بس، بتعرّف المستخدم بأهم حاجات
/// التطبيق (تصفح، أجواء، قوائم، وضع قراءة..) قبل ما يدخل على الرئيسية.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.mosque_rounded,
      title: 'أهلًا بيك في جَنَّتَكَ',
      body: 'مكتبة تلاوات كاملة من أشهر القراء، بتصميم هادي ومريح للاستماع اليومي',
    ),
    _OnboardPage(
      icon: Icons.menu_book_rounded,
      title: 'تصفح زي ما يناسبك',
      body: 'ادخل على القارئ اللي تحبه، أو دوّر بالسورة نفسها تلاقي كل القراء اللي سجلوها',
    ),
    _OnboardPage(
      icon: Icons.self_improvement_rounded,
      title: 'أجواء تناسب وقتك',
      body: 'وقت نوم، مذاكرة، شغل، أو جيم - كل وقت له تلاوة مناسبة له تلقائيًا',
    ),
    _OnboardPage(
      icon: Icons.queue_music_rounded,
      title: 'اعمل مكتبتك الخاصة',
      body: 'قوائم تشغيل، تحميل للاستماع من غير نت، ومتابعة ختمتك أول بأول',
    ),
  ];

  void _finish() async {
    await LocalStorage.instance.setBool(StorageKeys.hasSeenOnboarding, true);
    if (!mounted) return;
    final repository = RecitersRepositoryImpl(RecitersRemoteDataSourceImpl());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(repository: repository)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLast = _index == _pages.length - 1;

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
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text('تخطي', style: AppTypography.caption(brightness)),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 110.w,
                            height: 110.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: AppColors.goldGradient),
                            ),
                            child: Icon(page.icon, size: 48.sp, color: Colors.black87),
                          ),
                          SizedBox(height: 32.h),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.headline(brightness),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: AppTypography.body(brightness),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: active ? 22.w : 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.glassBorder(brightness),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.all(24.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(isLast ? 'يلا نبدأ' : 'التالي'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
