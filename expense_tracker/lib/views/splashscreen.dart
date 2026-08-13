import 'package:flutter/material.dart';
import 'dart:async';
import 'welcome_screen.dart';
import 'homepage.dart'; 
import 'package:expense_tracker/services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); 

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // check if user already logged in
      final loggedIn = await ApiService.isLoggedIn();

      if (!mounted) return;
      
      // ── FIXED NAVIGATION ROUTE ──
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => loggedIn
              ? const MyHomePage()      // ← already logged in, clean navigation
              : const WelcomeScreen(),  // ← not logged in, show welcome
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── DARK MODE FORMULA ──
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDarkMode ? const Color(0xFF1A1A2E) : Colors.white;
    final iconBg     = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white70;
    final iconColor  = isDarkMode ? const Color(0xFF3EB489) : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: iconBg,
              ),
            ),
            Icon(Icons.settings, size: 70, color: iconColor),
          ],
        ),
      ),
    );
  }
}