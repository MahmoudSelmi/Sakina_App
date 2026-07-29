import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/downloads/data/download_service.dart';
import 'features/favorites/data/favorites_service.dart';
import 'features/favorites/data/surah_favorites_service.dart';
import 'features/recently_played/data/recently_played_service.dart';
import 'features/reciters/data/datasources/reciters_remote_data_source.dart';
import 'features/reciters/data/repositories/reciters_repository_impl.dart';
import 'features/reciters/domain/repositories/reciters_repository.dart';
import 'features/player/cubit/player_cubit.dart';
import 'features/player/data/audio_player_handler.dart';
import 'features/home/presentation/home_screen.dart';

late final AudioPlayerHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.instance.init();
  FavoritesService.instance.load();
  SurahFavoritesService.instance.load();
  RecentlyPlayedService.instance.load();
  DownloadService.instance.load();

  // بنسجل الـ handler مع نظام التشغيل عشان يظهر تحكم حقيقي في إشعار
  // التشغيل وعلى شاشة القفل (تشغيل/إيقاف/التالي/السابق).
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.jannataka.quran.audio',
      androidNotificationChannelName: 'جَنَّتَكَ - تشغيل الصوت',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const QuranPremiumApp());
}

class QuranPremiumApp extends StatelessWidget {
  const QuranPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    final RecitersRepository repository =
        RecitersRepositoryImpl(RecitersRemoteDataSourceImpl());

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<PlayerCubit>(create: (_) => PlayerCubit(audioHandler)),
          ],
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance,
            builder: (context, themeMode, _) {
              return MaterialApp(
                title: 'جَنَّتَكَ',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                locale: const Locale('ar'),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('ar')],
                home: HomeScreen(repository: repository),
              );
            },
          ),
        );
      },
    );
  }
}
