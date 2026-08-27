import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/splashscreen.dart';
import 'services/notification_service.dart';
import 'themes/app_theme.dart';

// ── GLOBAL NOTIFIERS ──
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<String> currencyNotifier = ValueNotifier('₹ INR');
final ValueNotifier<String?> avatarNotifier  = ValueNotifier(null); // NEW: Avatar State

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await NotificationService.requestPermission();

  final prefs = await SharedPreferences.getInstance();
  
  // Load Theme
  final isDark = prefs.getBool('is_dark_mode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  // Load Currency
  currencyNotifier.value = prefs.getString('currency') ?? '₹ INR';

  // Load Avatar
  avatarNotifier.value = prefs.getString('avatar');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'SPENDWISE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme, 
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const SplashScreen(),
        );
      },
    );
  }
}