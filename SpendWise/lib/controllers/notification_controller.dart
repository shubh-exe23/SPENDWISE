import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notifications.dart';
import '../models/goals.dart';
import 'transaction_controller.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationController {
  List<AppNotification> _notifications = [];
  
  // ── 1. NEW DYNAMIC STATE TRACKING ──
  final Map<String, double> _previousSpent = {};
  bool _isFirstCheck = true;

  List<AppNotification> get all => _notifications.reversed.toList();
  List<AppNotification> get unread => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unread.length;
  bool get hasUnread => unread.isNotEmpty;

  // ── 2. Fetch from Database ──
  Future<void> loadNotifications() async {
    final data = await ApiService.getNotifications();
    _notifications = data.map((n) => AppNotification.fromMap(n)).toList();
  }

  // ── 3. Mark as read in Database ──
  Future<void> markAllRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    await ApiService.markAllNotificationsRead();
  }

  // ── 4. Check Goals and Save/Push Alerts ──
  Future<void> checkGoals(List<Goal> goals, TransactionController txController) async {
    final prefs = await SharedPreferences.getInstance();
    final alertsEnabled = prefs.getBool('goal_alerts') ?? true; 

    for (final goal in goals) {
      final safeGoalCat = goal.category.trim().toLowerCase();

      final spent = txController.allTransactions
          .where((t) {
            final safeTxnCat = t.category.trim().toLowerCase();
            return t.isExpense && 
                   safeTxnCat == safeGoalCat && 
                   !t.date.isBefore(goal.startDate) && 
                   !t.date.isAfter(goal.endDate);
          })
          .fold(0.0, (sum, t) => sum + t.amount);

      // ── THE FIX: Detect if we JUST crossed the line ──
      final prevSpent = _previousSpent[goal.name] ?? spent;
      _previousSpent[goal.name] = spent;

      if (_isFirstCheck) continue; // Prevent spam on initial app launch

      // ── CHECK FOR BUDGET EXCEEDED ──
      if (spent > goal.budgetAmount && prevSpent <= goal.budgetAmount) {
        
        final message = 'You have exceeded your ${goal.name} budget. Total spent: ${spent.toStringAsFixed(0)}';
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
        
      // ── CHECK FOR WARNING THRESHOLD ──
      } else if (goal.alertThreshold != null && spent >= goal.alertThreshold! && prevSpent < goal.alertThreshold!) {
        
        final message = 'You are close to your ${goal.name} limit. Total spent: ${spent.toStringAsFixed(0)}';
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
    
    _isFirstCheck = false; // Turn off first check after the initial run completes
  }
}