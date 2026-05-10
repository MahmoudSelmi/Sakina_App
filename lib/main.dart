import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakina_app/SplashScreen.dart';
import 'package:sakina_app/features/home/logic/audio_player_cubit.dart';
import 'package:sakina_app/features/home/ui/screens/home_screen.dart';
import 'core/theming/colors.dart';
import 'features/home/logic/home_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SakinaApp());
}

class SakinaApp extends StatelessWidget {
  const SakinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 13 dimensions for precision
      minTextAdapt: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => HomeCubit()),
            BlocProvider(create: (context) => PlayerCubit()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Sakina',
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: ColorsManager.mainDark,
              fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/home': (context) => const HomeScreen(),
            },
          ),
        );
      },
    );
  }
}
