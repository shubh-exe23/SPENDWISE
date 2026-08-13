import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notifications.dart';
import '../models/goals.dart';
import 'transaction_controller.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationController {
  List<AppNotification> _notifications = [];
  final Set<String> _firedSignatures = {};

  List<AppNotification> get all => _notifications.reversed.toList();
  List<AppNotification> get unread => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unread.length;
  bool get hasUnread => unread.isNotEmpty;

  // ── 1. Fetch from Database ──
  Future<void> loadNotifications() async {
    final data = await ApiService.getNotifications();
    _notifications = data.map((n) => AppNotification.fromMap(n)).toList();
    
    _firedSignatures.clear();
    for (var n in _notifications) {
      _firedSignatures.add('${n.type}_${n.message}');
    }
  }

  // ── 2. Mark as read in Database ──
  Future<void> markAllRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    await ApiService.markAllNotificationsRead();
  }

  // ── 3. Check Goals and Save/Push Alerts ──
  Future<void> checkGoals(List<Goal> goals, TransactionController txController) async {
    final prefs = await SharedPreferences.getInstance();
    final alertsEnabled = prefs.getBool('goal_alerts') ?? true; 

    for (final goal in goals) {
      final spent = txController.allTransactions
          .where((t) => t.isExpense && t.category == goal.category && !t.date.isBefore(goal.startDate) && !t.date.isAfter(goal.endDate))
          .fold(0.0, (sum, t) => sum + t.amount);

      // ── CHECK FOR BUDGET EXCEEDED ──
      if (spent > goal.budgetAmount) {
        
        // THE MAGIC FIX: We embed the exact 'spent' amount into the signature!
        // A new transaction changes the total, forcing a new alert.
        final message = 'You have exceeded your ${goal.name} budget. Total spent: ${spent.toStringAsFixed(0)}';
        final signature = 'alert_$message';
        
        if (!_firedSignatures.contains(signature)) {
          _firedSignatures.add(signature);
          
          final exceededBy = spent - goal.budgetAmount;
          final n = AppNotification(
            title: 'Budget Exceeded!',
            message: message,
            type: 'alert',
            createdAt: DateTime.now(),
          );
          
          _notifications.add(n);
          await ApiService.addNotification(n.toMap()); 
          
          if (alertsEnabled) {
            await NotificationService.showExceeded(goalName: goal.name, exceededBy: exceededBy);
          }
        }
        
      // ── CHECK FOR WARNING THRESHOLD ──
      } else if (goal.alertThreshold != null && spent >= goal.alertThreshold!) {
        
        // Embed the exact 'spent' amount here as well
        final message = 'You are close to your ${goal.name} limit. Total spent: ${spent.toStringAsFixed(0)}';
        final signature = 'warning_$message';
        
        if (!_firedSignatures.contains(signature)) {
          _firedSignatures.add(signature);
          
          final remaining = goal.budgetAmount - spent;
          final n = AppNotification(
            title: 'Budget Warning',
            message: message,
            type: 'warning',
            createdAt: DateTime.now(),
          );
          
          _notifications.add(n);
          await ApiService.addNotification(n.toMap()); 
          
          if (alertsEnabled) {
            await NotificationService.showWarning(goalName: goal.name, remaining: remaining);
          }
        }
      }
    }
  }
}