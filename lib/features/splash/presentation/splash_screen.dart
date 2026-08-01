import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../reciters/data/datasources/reciters_remote_data_source.dart';
import '../../reciters/data/repositories/reciters_repository_impl.dart';
import '../../home/presentation/home_screen.dart';

/// شاشة البداية - بتفضل ظاهرة حوالي 3 ثواني بحركة دخول فخمة (توهج + تكبير
/// + حروف الاسم بتتوضح واحد واحد) قبل ما تنتقل للشاشة الرئيسية.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _glowController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.08).chain(CurveTween(curve: Curves.easeOutBack)), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    ]).animate(_logoController);

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _wordmarkFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );

    _taglineFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _logoController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final hasSeenOnboarding =
        LocalStorage.instance.getBool(StorageKeys.hasSeenOnboarding) ?? false;

    Widget nextScreen;
    if (!hasSeenOnboarding) {
      nextScreen = const OnboardingScreen();
    } else {
      final repository = RecitersRepositoryImpl(RecitersRemoteDataSourceImpl());
      nextScreen = HomeScreen(repository: repository);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E17),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF171B2C), Color(0xFF0B0E17)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _glowController]),
                builder: (context, child) {
                  final glow = 0.35 + (_glowController.value * 0.35);
                  return Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 128.w,
                        height: 128.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: AppColors.goldGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withOpacity(glow),
                              blurRadius: 48,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mosque_rounded,
                          size: 64.sp,
                          color: Colors.black.withOpacity(0.82),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 26.h),
              FadeTransition(
                opacity: _wordmarkFade,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      LinearGradient(colors: AppColors.goldGradient).createShader(bounds),
                  child: Text(
                    'جَنَّتَكَ',
                    style: GoogleFonts.amiri(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              FadeTransition(
                opacity: _taglineFade,
                child: Text(
                  'استمع... واطمئن',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14.sp,
                    letterSpacing: 0.5,
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
