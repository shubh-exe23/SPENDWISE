import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';
import '../main.dart'; 

class SettingsPage extends StatefulWidget {
  final VoidCallback onBackToHome;

  const SettingsPage({super.key, required this.onBackToHome});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _jade     = Color(0xFF3EB489);
  static const _jadeDark = Color(0xFF2A7D5F);

  late bool _darkMode;
  bool _goalAlerts       = true; 

  String _selectedCurrency = '₹ INR';

  String _userName = 'User';
  String _userInitial = 'U';

  final List<String> _currencies = ['₹ INR', '\$ USD', '€ EUR', '£ GBP', '¥ JPY'];

  @override
  void initState() {
    super.initState();
    _darkMode = themeNotifier.value == ThemeMode.dark;
    _selectedCurrency = currencyNotifier.value;
    
    _loadUserProfile();
    _loadLocalSettings(); 
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _goalAlerts = prefs.getBool('goal_alerts') ?? true;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await ApiService.getProfile();
    if (profile != null && profile['name'] != null) {
      if (mounted) {
        setState(() {
          _userName = profile['name'];
          if (_userName.isNotEmpty) {
            final parts = _userName.trim().split(' ');
            if (parts.length >= 2) {
              _userInitial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else {
              _userInitial = parts[0][0].toUpperCase();
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF2F2F7);
    final cardBg  = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white;
    final textPrimary   = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final textSecondary = isDarkMode ? Colors.white54 : Colors.grey.shade500;
    final divider = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _jade,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToHome, 
        ),
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Profile', textSecondary),
            _card(cardBg, divider, [
              _avatarTile(textPrimary, textSecondary),
            ]),
            const SizedBox(height: 24),

            _sectionHeader('Preferences', textSecondary),
            _card(cardBg, divider, [
              _toggleTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: _darkMode,
                textPrimary: textPrimary,
                onChanged: (val) async {
                  setState(() => _darkMode = val);
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_dark_mode', val);
                },
              ),
              _divider(divider),
              _dropdownTile(
                icon: Icons.currency_exchange_outlined,
                label: 'Currency',
                value: _selectedCurrency,
                options: _currencies,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() => _selectedCurrency = val);
                  currencyNotifier.value = val;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('currency', val);
                  await ApiService.updateProfile({'currency': val});
                },
              ),
              _divider(divider),
              _arrowTile(
                icon: Icons.language_outlined,
                label: 'Language (English)',
                textPrimary: textPrimary,
                iconColor: _jade,
                onTap: () => _showComingSoon('Support for other languages'),
              ),
            ]),
            const SizedBox(height: 24),

           _sectionHeader('Notifications', textSecondary),
            _card(cardBg, divider, [
              _toggleTile(
                icon: Icons.flag_outlined,
                label: 'Goal Exceeded Alerts',
                value: _goalAlerts,
                textPrimary: textPrimary,
                onChanged: (val) async {
                  setState(() => _goalAlerts = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('goal_alerts', val);
                },
              ),
            ]),
           
            const SizedBox(height: 24),

            _sectionHeader('Data', textSecondary),
            _card(cardBg, divider, [
              _arrowTile(
                icon: Icons.delete_outline,
                label: 'Clear Transactions',
                textPrimary: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () => _showClearTransactionsDialog(cardBg, textPrimary, textSecondary), 
              ),
            ]),
            const SizedBox(height: 24),

            _sectionHeader('General', textSecondary),
            _card(cardBg, divider, [
              _arrowTile(
                icon: Icons.info_outline,
                label: 'About',
                textPrimary: textPrimary,
                onTap: () => _showAboutDialog(cardBg, textPrimary, textSecondary),
              ),
              _divider(divider),
              _arrowTile(
                icon: Icons.lock_outline,
                label: 'Permissions',
                textPrimary: textPrimary,
                onTap: () => _showComingSoon('Permissions'),
              ),
              _divider(divider),
              _arrowTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                textPrimary: textPrimary,
                onTap: () => _showComingSoon('Privacy Policy'),
              ),
              _divider(divider),
              _arrowTile(
                icon: Icons.logout,
                label: 'Log Out',
                textPrimary: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () => _confirmLogout(cardBg, textPrimary),
              ),
            ]),
            const SizedBox(height: 32),

            Center(child: Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: textSecondary))),
            const SizedBox(height: 8),
            Center(child: Text('Made with ♥ using Flutter', style: TextStyle(fontSize: 12, color: textSecondary))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.4)),
    );
  }

  Widget _card(Color bg, Color divider, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _divider(Color color) => Padding(
        padding: const EdgeInsets.only(left: 52),
        child: Divider(height: 1, color: color),
      );

  Widget _avatarTile(Color textPrimary, Color textSecondary) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, 
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        _loadUserProfile();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFCCEDE2),
              child: Text(_userInitial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _jadeDark)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 2),
                Text('Tap to edit profile', style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({required IconData icon, required String label, required bool value, required Color textPrimary, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _jade),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: textPrimary))),
          Switch(value: value, onChanged: onChanged, activeColor: _jade),
        ],
      ),
    );
  }

  Widget _dropdownTile({required IconData icon, required String label, required String value, required List<String> options, required Color textPrimary, required Color textSecondary, required Function(String?) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _jade),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: textPrimary))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: Icon(Icons.chevron_right, color: textSecondary, size: 20),
              style: TextStyle(fontSize: 14, color: textSecondary),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowTile({required IconData icon, required String label, required Color textPrimary, Color? iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? _jade),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: textPrimary))),
            Icon(Icons.chevron_right, color: iconColor ?? Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _showClearTransactionsDialog(Color cardBg, Color textPrimary, Color textSecondary) {
    String selectedPeriod = 'All Time';
    final List<String> periods = ['Today', 'Yesterday', 'This Week', 'This Month', 'All Time'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Clear Transactions', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select the timeframe you want to clear.', style: TextStyle(color: textSecondary, fontSize: 14)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF6FDFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCCEDE2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPeriod,
                        isExpanded: true,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                        icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
                        items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedPeriod = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: _jade)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _jade,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); 
                    _showDeleteConfirmationDialog(selectedPeriod, cardBg, textPrimary, textSecondary);
                  },
                  child: const Text('Next', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String period, Color cardBg, Color textPrimary, Color textSecondary) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            Text('Are you sure?', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary, fontSize: 18)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: textPrimary, fontSize: 14, height: 1.4),
            children: [
              const TextSpan(text: 'You are about to permanently delete all transactions from '),
              TextSpan(text: '"$period"', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              const TextSpan(text: '.\n\nThis action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: _jade))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () async {
              Navigator.pop(context); 
              
              final success = await ApiService.clearTransactions(period);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully deleted transactions for: $period'), backgroundColor: _jade),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete transactions.'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Yes, Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(Color cardBg, Color textPrimary, Color textSecondary) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE8F5F0), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance_wallet_outlined, color: _jade, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Expense Tracker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0', style: TextStyle(color: textPrimary)), SizedBox(height: 4),
            Text('Build: 2024.1', style: TextStyle(color: textPrimary)), SizedBox(height: 4),
            Text('Platform: Flutter', style: TextStyle(color: textPrimary)), SizedBox(height: 12),
            Text('A simple and elegant expense tracking app built with Flutter.', style: TextStyle(color: textSecondary)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _jade, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(Color cardBg, Color textPrimary) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _jade))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context); 
              await ApiService.logout(); 

              themeNotifier.value = ThemeMode.light;
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('is_dark_mode');

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false, 
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature — coming soon')));
  }
}