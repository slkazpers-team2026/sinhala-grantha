import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'services/drm_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase Client
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // 2. Enforce FLAG_SECURE globally to block screenshots and screen recordings
  await DrmService.secureScreen();

  runApp(const SinhalaGranthaApp());
}

class SinhalaGranthaApp extends StatelessWidget {
  const SinhalaGranthaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'සිංහල ග්‍රන්ථ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
