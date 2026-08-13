import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/splashscreen.dart';
import 'services/notification_service.dart';

// ── GLOBAL NOTIFIER ──
// This allows any screen in the app to change the theme instantly
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<String> currencyNotifier = ValueNotifier('₹ INR');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  // ── LOAD SAVED THEME ON STARTUP ──
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  final savedCurrency = prefs.getString('currency') ?? '₹ INR';
  currencyNotifier.value = savedCurrency;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── LISTENS FOR CHANGES ANYWHERE IN THE APP ──
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          
          // Dictates which theme is actively showing
          themeMode: currentMode,
          
          // ── LIGHT THEME ──
          theme: ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3EB489)),
          ),
          
          // ── DARK THEME ──
          darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3EB489),
              brightness: Brightness.dark,
            ),
          ),
          
          home: const SplashScreen(),
        );
      },
    );
  }
}