import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _jade = Color(0xFF3EB489);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {'quote': 'Stay organised\nwith less spending', 'subtitle': 'Take control of your finances effortlessly', 'color': const Color(0xFF3EB489), 'icon': Icons.account_balance_wallet_outlined},
    {'quote': 'Have more money\nby spending less', 'subtitle': 'Track your expenses and watch savings grow', 'color': const Color(0xFF2A7D5F), 'icon': Icons.savings_outlined},
    {'quote': 'Track every rupee,\nbuild your future', 'subtitle': 'Every small step leads to financial freedom', 'color': const Color(0xFF4ECDC4), 'icon': Icons.trending_up_outlined},
    {'quote': 'Small savings today,\nbig dreams tomorrow', 'subtitle': 'Your journey to financial freedom starts here', 'color': const Color(0xFF3EB489), 'icon': Icons.star_outline},
    {'quote': 'Know where your\nmoney goes', 'subtitle': 'Smart insights for smarter spending', 'color': const Color(0xFF2A7D5F), 'icon': Icons.pie_chart_outline},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final next = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      _startAutoSlide(); 
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── DARK MODE FORMULA ──
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF6FDFB);
    final textColor  = isDarkMode ? Colors.white : const Color(0xFF2A7D5F);
    final hintColor  = isDarkMode ? Colors.white54 : Colors.grey.shade500;
    final dotColor   = isDarkMode ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _slidePage(_slides[index], textColor, hintColor);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(color: _currentPage == index ? _jade : dotColor, borderRadius: BorderRadius.circular(4)),
                );
              }),
            ),
            const SizedBox(height: 32),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        style: ElevatedButton.styleFrom(backgroundColor: _jade, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: _jade, width: 1.5)),
                        child: const Text('Sign Up', style: TextStyle(color: _jade, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Your personal finance companion', style: TextStyle(fontSize: 12, color: hintColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slidePage(Map<String, dynamic> slide, Color textColor, Color hintColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity, height: 260,
            decoration: BoxDecoration(color: (slide['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(32), border: Border.all(color: (slide['color'] as Color).withOpacity(0.3), width: 1.5)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: (slide['color'] as Color).withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(slide['icon'] as IconData, size: 52, color: slide['color'] as Color),
                ),
                const SizedBox(height: 16),
                Text('Illustration coming soon', style: TextStyle(fontSize: 12, color: (slide['color'] as Color).withOpacity(0.8))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(slide['quote'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textColor, height: 1.3)),
          const SizedBox(height: 12),
          Text(slide['subtitle'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: hintColor, height: 1.5)),
        ],
      ),
    );
  }
}