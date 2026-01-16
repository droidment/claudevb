import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'core/supabase_client.dart';
import 'core/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tournament Scheduler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.violet,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: AppColors.violet,
          secondary: AppColors.lime,
          onSecondary: AppColors.black,
          secondaryContainer: AppColors.secondaryLight,
          onSecondaryContainer: AppColors.black,
          tertiary: AppColors.violet,
          onTertiary: AppColors.white,
          error: AppColors.error,
          onError: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.black,
          surfaceContainerHighest: AppColors.surfaceDim,
          outline: Colors.grey.shade300,
        ),
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.violet,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.violet,
            side: BorderSide(color: AppColors.violet),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.violet,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.violet, width: 2),
          ),
          floatingLabelStyle: TextStyle(color: AppColors.violet),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.secondaryLight,
          selectedColor: AppColors.lime,
          labelStyle: TextStyle(color: AppColors.black),
          secondaryLabelStyle: TextStyle(color: AppColors.black),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: AppColors.violet,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.session != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// A comment to trigger the workflow.

