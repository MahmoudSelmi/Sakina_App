import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/downloads/data/download_service.dart';
import 'features/favorites/data/favorites_service.dart';
import 'features/favorites/data/ayah_favorites_service.dart';
import 'features/favorites/data/surah_favorites_service.dart';
import 'features/khatma/data/khatma_service.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/playlists/data/playlists_service.dart';
import 'features/recently_played/data/recently_played_service.dart';
import 'features/settings/data/settings_service.dart';
import 'features/settings/data/volume_boost_service.dart';
import 'features/streak/data/streak_service.dart';
import 'features/player/cubit/player_cubit.dart';
import 'features/player/data/audio_player_handler.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'firebase_options.dart';

late final AudioPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.instance.init();
  FavoritesService.instance.load();
  SurahFavoritesService.instance.load();
  AyahFavoritesService.instance.load();
  KhatmaService.instance.load();
  StreakService.instance.load();
  PlaylistsService.instance.load();
  RecentlyPlayedService.instance.load();
  DownloadService.instance.load();
  SettingsService.instance.load();
  VolumeBoostService.instance.load();

  // بنحاول نهيّئ Firebase (لو المشروع متظبط بمفاتيح حقيقية)، بس من غير ما
  // نكسر التطبيق لو لسه مفيش إعداد - عشان تسجيل الدخول يبقى اختياري
  // فعلًا ومش شرط لفتح التطبيق.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // مفيش إعداد Firebase حقيقي لسه، أو حصل خطأ في التهيئة - نكمل عادي
    // من غير مزامنة سحابية.
  }

  // بنسجل الـ handler مع نظام التشغيل عشان يظهر تحكم حقيقي في إشعار
  // التشغيل وعلى شاشة القفل. لو فشل (زي إعدادات AndroidManifest ناقصة)،
  // منسيبش التطبيق يقفل من غير ما يفتح خالص - بنكمل بمشغل عادي من غير
  // تكامل مع شاشة القفل بدل ما نكسر التطبيق كله.
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.jannataka.quran.audio',
        androidNotificationChannelName: 'جَنَّتَكَ - تشغيل الصوت',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (_) {
    audioHandler = AudioPlayerHandler();
  }

  await NotificationService.instance.init();

  runApp(const QuranPremiumApp());
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
