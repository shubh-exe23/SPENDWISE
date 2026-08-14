import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/transaction.dart';
import '../models/goals.dart';
import '../services/api_service.dart';
import 'floatingactionbutton.dart';
import 'settings.dart';
import 'analysis.dart';
import 'goals.dart';
import 'notification_page.dart';
import 'package:expense_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key}); // ── CONSTRUCTORS REMOVED ──

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TransactionController _controller = TransactionController();
  List<Goal> _goals = [];
  final NotificationController _notificationController = NotificationController();

  String selectDateFilter = 'Today';
  final List<String> dateoptions = ['Today', 'Yesterday', 'This week', 'This month', 'Custom'];
  DateTime? customDate;
  int _currentIndex = 0;

  List<Transaction> get filtered => _controller.getFiltered(selectDateFilter, customDate);
  double get totalIncome  => _controller.getTotalIncome(filtered);
  double get totalExpense => _controller.getTotalExpense(filtered);
  double get balance      => _controller.getBalance(filtered);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadTransactions();
    
    final goalsData = await ApiService.getGoals();
    _goals = goalsData.map((g) => Goal.fromMap(g)).toList();

    await _notificationController.loadNotifications(); 

    // ── FETCH USER PROFILE & CURRENCY ──
    final profile = await ApiService.getProfile();
    if (profile != null && profile['currency'] != null) {
      currencyNotifier.value = profile['currency'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', profile['currency']);
    }

    if (mounted) {
      setState(() {
        _notificationController.checkGoals(_goals, _controller);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── DARK MODE FORMULA ──
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF6FDFB);
    final bottomBg   = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white;

    return SafeArea(
      child: Scaffold(
        backgroundColor: bg,
        body: _currentIndex == 0
            ? _buildHome(isDarkMode)
            : _currentIndex == 1
                ? GoalsPage(
                    controller: _controller,
                    goals: _goals,
                    onGoalsChanged: () => _loadData(),
                    onBackToHome: () => setState(() => _currentIndex = 0), // ── ADDED ──
                  )
                : _currentIndex == 2
                    ? AnalysisPage(
                        controller: _controller,
                        onBackToHome: () => setState(() => _currentIndex = 0), // ── ADDED ──
                      )
                    : SettingsPage(
                        onBackToHome: () => setState(() => _currentIndex = 0), // ── ADDED ──
                      ), // ── CLEAN CALL ──

        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (_) => FloatingAction(controller: _controller),
                  );
                  if (!mounted) return;
                  await _loadData();
                },
                backgroundColor: const Color(0xFF3EB489),
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: bottomBg,
          elevation: 10,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(icon: Icons.home_outlined,      filledIcon: Icons.home,              label: 'Home',     index: 0),
                _navItem(icon: Icons.golf_course_sharp,   filledIcon: Icons.golf_course_sharp,           label: 'Set Goals',  index: 1),
                if (_currentIndex == 0) const SizedBox(width: 48),
                _navItem(icon: Icons.bar_chart_outlined, filledIcon: Icons.bar_chart,         label: 'Analysis', index: 2),
                _navItem(icon: Icons.settings_outlined,  filledIcon: Icons.settings,          label: 'Settings', index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required IconData filledIcon, required String label, required int index}) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _loadData();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? filledIcon : icon,
            color: isActive ? const Color(0xFF3EB489) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF3EB489) : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHome(bool isDarkMode) {
    final cardBg    = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.white70 : Colors.black54;

    // ── LISTEN FOR CURRENCY CHANGES ──
    return ValueListenableBuilder<String>(
      valueListenable: currencyNotifier,
      builder: (context, currency, child) {
        final sym = currency.split(' ')[0]; // Extracts '₹' from '₹ INR'

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              color: const Color(0xFF3EB489),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ── INVISIBLE PLACEHOLDER TO KEEP DROPDOWN CENTERED ──
                      // This is exactly 50px wide to balance the CircleAvatar on the right.
                      const SizedBox(width: 50),
                      
                      // ── CENTERED DROPDOWN ──
                      DropdownButton<String>(
                        value: selectDateFilter,
                        dropdownColor: const Color(0xFF3EB489),
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white,
                        underline: const SizedBox(),
                        items: dateoptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                        onChanged: (value) async {
                          setState(() => selectDateFilter = value!);
                          if (value == 'Custom') {
                            DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (picked != null) setState(() => customDate = picked);
                          }
                        },
                      ),
                      
                      // ── FUNCTIONAL NOTIFICATION ICON ON THE RIGHT ──
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationPage(notificationController: _notificationController)));
                          setState(() {});
                        },
                        child: Stack(
                          children: [
                            const CircleAvatar(radius: 25, child: Icon(Icons.notifications_outlined)),
                            if (_notificationController.hasUnread)
                              Positioned(
                                top: 0, right: 0,
                                child: Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                  child: Center(child: Text(_notificationController.unreadCount > 9 ? '9+' : '${_notificationController.unreadCount}', style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold))),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Current Balance', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  
                  // ── DYNAMIC CURRENCY SYMBOL HERE ──
                  Text('$sym${balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(child: _moneyCard('Income', totalIncome, Icons.account_balance_wallet_outlined, const Color(0xFFEAF3DE), const Color(0xFF3B6D11), cardBg, textColor, sym)),
                      const SizedBox(width: 12),
                      Expanded(child: _moneyCard('Expenses', totalExpense, Icons.credit_card_outlined, const Color(0xFFFAECE7), const Color(0xFF993C1D), cardBg, const Color(0xFFA32D2D), sym)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3EB489)))
                  : filtered.isEmpty
                      ? Center(child: Text('No transactions for this period', style: TextStyle(color: hintColor)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final t = filtered[index];
                            return ListTile(
                              leading: CircleAvatar(backgroundColor: t.isExpense ? const Color(0xFFFAECE7) : const Color(0xFFEAF3DE), child: Icon(t.isExpense ? Icons.arrow_upward : Icons.arrow_downward, color: t.isExpense ? const Color(0xFF993C1D) : const Color(0xFF3B6D11))),
                              title: Text(t.title, style: TextStyle(color: textColor)),
                              subtitle: Text(t.category, style: TextStyle(color: hintColor)),
                              
                              // ── DYNAMIC CURRENCY SYMBOL HERE ──
                              trailing: Text('${t.isExpense ? '-' : '+'}$sym${t.amount.toStringAsFixed(2)}', style: TextStyle(color: t.isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
                            );
                          },
                        ),
            ),
          ],
        );
      }
    );
  }

 Widget _moneyCard(String label, double amount, IconData icon, Color iconBgColor, Color iconColor, Color cardBg, Color amountColor, String sym) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          
          // ── DYNAMIC CURRENCY SYMBOL HERE ──
          Text('$sym${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: amountColor)),
        ],
      ),
    );
  }
}