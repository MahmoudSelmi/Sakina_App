import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/downloads/data/download_service.dart';
import 'features/favorites/data/favorites_service.dart';
import 'features/reciters/data/datasources/reciters_remote_data_source.dart';
import 'features/reciters/data/repositories/reciters_repository_impl.dart';
import 'features/reciters/domain/repositories/reciters_repository.dart';
import 'features/player/cubit/player_cubit.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.instance.init();
  FavoritesService.instance.load();
  DownloadService.instance.load();
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
            BlocProvider<PlayerCubit>(create: (_) => PlayerCubit()),
          ],
          child: MaterialApp(
            title: 'قرآن بريميوم',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            locale: const Locale('ar'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ar')],
            home: HomeScreen(repository: repository),
          ),
        );
      },
    );
  }
}
