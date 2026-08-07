import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran_premium/shared/widgets/NotificationService.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/ambient/data/ambient_sound_service.dart';
import 'features/auth/data/auth_service.dart';
import 'features/downloads/data/download_service.dart';
import 'features/favorites/data/favorites_service.dart';
import 'features/favorites/data/ayah_favorites_service.dart';
import 'features/favorites/data/surah_favorites_service.dart';
import 'features/khatma/data/khatma_service.dart';
import 'features/playlists/data/playlists_service.dart';
import 'features/recently_played/data/recently_played_service.dart';
import 'features/settings/data/settings_service.dart';
import 'features/settings/data/volume_boost_service.dart';
import 'features/streak/data/streak_service.dart';
import 'features/player/cubit/player_cubit.dart';
import 'features/player/data/audio_player_handler.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'firebase_options.dart';

late AudioPlayerHandler audioHandler;

/// بيلف أي خطوة تهيئة في try/catch وبيكمّل عادي لو حصل خطأ، بدل ما وقوع
/// خطوة واحدة يمنع التطبيق كله من الفتح. كل خطوة هنا لازم تفضل "اختيارية"
/// - لو فشلت، التطبيق يشتغل بأقل إمكانيات بدل ما يقفل خالص.
Future<void> _safely(String label, Future<void> Function() task) async {
  try {
    await task();
  } catch (error, stack) {
    debugPrint('تهيئة "$label" فشلت وهنكمل من غيرها: $error');
    debugPrintStack(stackTrace: stack);
  }
}

Future<void> main() async {
  // بيمسك أي خطأ غير متوقع في أي مكان بالتطبيق ويطبعه في اللوج بدل ما
  // يقفل التطبيق فجأة من غير أي تفسير، وبيبعته لـ Crashlytics لو فايربيز
  // شغال عشان تعرف لو حصل كراش عند مستخدم حقيقي بعد النشر.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('خطأ غير متوقع: ${details.exceptionAsString()}');
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (_) {
      // فايربيز مش شغال لسه - تجاهل بهدوء.
    }
  };

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _safely('التخزين المحلي', () => LocalStorage.instance.init());
    await _safely(
        'المفضلة (قراء)', () async => FavoritesService.instance.load());
    await _safely(
        'المفضلة (سور)', () async => SurahFavoritesService.instance.load());
    await _safely(
        'المفضلة (آيات)', () async => AyahFavoritesService.instance.load());
    await _safely('الختمة', () async => KhatmaService.instance.load());
    await _safely('السلسلة اليومية', () async => StreakService.instance.load());
    await _safely(
        'قوائم التشغيل', () async => PlaylistsService.instance.load());
    await _safely(
        'آخر استماع', () async => RecentlyPlayedService.instance.load());
    await _safely('التحميلات', () async => DownloadService.instance.load());
    await _safely('الإعدادات', () async => SettingsService.instance.load());
    await _safely(
        'مستوى الصوت', () async => VolumeBoostService.instance.load());
    await _safely(
        'صوت الطبيعة', () async => AmbientSoundService.instance.load());

    // فايربيز اختياري بالكامل - أي فشل هنا (زي عدم وجود مفاتيح حقيقية
    // لسه) منعزله تمامًا عن باقي التطبيق.
    await _safely('فايربيز', () async {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      AuthService.instance.init();
    });

    // لو فايربيز فشل، لازم لسه نقفل شاشة التحميل بتاعة حالة الجلسة عشان
    // البروفايل ميفضلش عالق في وضع "بيحمّل" للأبد.
    if (!AuthService.instance.isAvailable) {
      AuthService.instance.isRestoringSession.value = false;
    }

    // تسجيل المشغل مع نظام التشغيل (شاشة القفل + الإشعار) - لو فشل (زي
    // إعدادات AndroidManifest ناقصة)، بنكمّل بمشغل عادي من غير ما نقفل
    // التطبيق.
    // audioHandler = AudioPlayerHandler();
    // await _safely('التكامل مع شاشة القفل', () async {
    //   audioHandler = await AudioService.init(
    //     builder: () => AudioPlayerHandler(),
    //     config: const AudioServiceConfig(
    //       androidNotificationChannelId: 'com.jannataka.quran.audio',
    //       androidNotificationChannelName: 'جَنَّتَكَ - تشغيل الصوت',
    //       androidNotificationOngoing: true,
    //       androidStopForegroundOnPause: true,
    //     ),
    //   );
    // });
    audioHandler = AudioPlayerHandler();

    await _safely('إشعارات التذكير', () => NotificationService.instance.init());

    runApp(const QuranPremiumApp());
  }, (error, stack) {
    debugPrint('خطأ غير ملتقط: $error');
    debugPrintStack(stackTrace: stack);
  });
}

class QuranPremiumApp extends StatelessWidget {
  const QuranPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<PlayerCubit>(create: (_) => PlayerCubit(audioHandler)),
          ],
          child: ValueListenableBuilder<AppThemeVariant>(
            valueListenable: ThemeController.instance,
            builder: (context, variant, _) {
              final palette = AppPalettes.of(variant);
              return MaterialApp(
                title: 'جَنَّتَكَ',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.forPalette(palette),
                locale: const Locale('ar'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('ar')],
                home: const SplashScreen(),
              );
            },
          ),
        );
      },
    );
  }
}
