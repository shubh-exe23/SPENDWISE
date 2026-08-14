import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── initialize ──
  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  // ── request permission ──
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ── check if permission granted ──
  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ── show warning notification ──
  static Future<void> showWarning({
    required String goalName,
    required double remaining,
  }) async {
    if (!await hasPermission()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'budget_warning_v2',        // <-- NEW ID FORCES A FRESH CHANNEL
      'Budget Warnings',          
      channelDescription: 'Alerts when budget is almost exhausted',
      importance: Importance.max, // <-- BUMPED TO MAX
      priority: Priority.max,     // <-- BUMPED TO MAX
      color: Color(0xFFFF9800),   
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      1, 
      '⚠️ Budget Warning!',
      '$goalName — Only ₹${remaining.toStringAsFixed(0)} left!',
      details,
    );
  }

  // ── show exceeded notification ──
  static Future<void> showExceeded({
    required String goalName,
    required double exceededBy,
  }) async {
    if (!await hasPermission()) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'budget_exceeded_v2',       // <-- NEW ID FORCES A FRESH CHANNEL
      'Budget Exceeded',          
      channelDescription: 'Alerts when budget is exceeded',
      importance: Importance.max, 
      priority: Priority.max,     
      color: Color(0xFFE53935),   
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      2, 
      '🚨 Budget Exceeded!',
      '$goalName — Exceeded by ₹${exceededBy.toStringAsFixed(0)}!',
      details,
    );
  }
}