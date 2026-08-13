import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction.dart';

class AnalysisPage extends StatefulWidget {
  final TransactionController controller;
  const AnalysisPage({super.key, required this.controller});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  static const _jade     = Color(0xFF3EB489);
  
  static const _categoryColors = [
    Color(0xFF3EB489), Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFBE0B), Color(0xFF9B5DE5), Color(0xFFFF9F1C), Color(0xFF2EC4B6),
  ];

  String _filter = 'This Month';
  DateTime? _customDate;
  bool _isDonut = true;

  final List<String> _filters = ['Today', 'Yesterday', 'This Week', 'This Month', 'This Year', 'Custom'];

  List<Transaction> get _expenses {
    return widget.controller.getFiltered(_filter, _customDate).where((t) => t.isExpense).toList();
  }

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = {};
    for (final t in _expenses) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    return totals;
  }

  double get _grandTotal => _categoryTotals.values.fold(0, (sum, v) => sum + v);

  Future<void> _onFilterChanged(String? value) async {
    if (value == null) return;
    if (value == 'Custom') {
      final picked = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(),
        builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _jade)), child: child!),
      );
      if (picked != null) setState(() { _filter = value; _customDate = picked; });
    } else {
      setState(() { _filter = value; _customDate = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── DARK MODE FORMULA ──
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF6FDFB);
    final cardBg     = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white;
    final textColor  = isDarkMode ? Colors.white : const Color(0xFF2A7D5F);
    final hintColor  = isDarkMode ? Colors.white54 : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFCCEDE2);

    final totals  = _categoryTotals;
    final total   = _grandTotal;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        title: Text('Analyze Your Expenses', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: totals.isEmpty ? _emptyState(hintColor) : _content(totals, total, cardBg, textColor, hintColor, borderColor, isDarkMode),
    );
  }

  Widget _emptyState(Color hintColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 72, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No expense data available\nfor this period.', textAlign: TextAlign.center, style: TextStyle(color: hintColor, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _content(Map<String, double> totals, double total, Color cardBg, Color textColor, Color hintColor, Color borderColor, bool isDark) {
    final categories = totals.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    decoration: BoxDecoration(color: isDark ? Colors.white12 : const Color(0xFFE8F5F0), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                        icon: const Icon(Icons.keyboard_arrow_down, color: _jade, size: 18),
                        dropdownColor: cardBg,
                        items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: _onFilterChanged,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _chartTypeToggle(isDark, textColor),
                const SizedBox(height: 24),
                SizedBox(height: 220, child: _isDonut ? _donutChart(totals, total) : _pieChart(totals, total)),
                const SizedBox(height: 24),
                _legend(categories, textColor),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Category Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 12),
          ...categories.asMap().entries.map((entry) {
            final index    = entry.key;
            final category = entry.value;
            final amount   = totals[category]!;
            final percent  = total > 0 ? (amount / total * 100) : 0.0;
            final color    = _categoryColors[index % _categoryColors.length];
            return _categoryCard(category, amount, percent, color, cardBg, textColor, hintColor, borderColor);
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _chartTypeToggle(bool isDark, Color textColor) {
    return Container(
      decoration: BoxDecoration(color: isDark ? Colors.white12 : const Color(0xFFE8F5F0), borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleOption('Donut', true, textColor),
          _toggleOption('Pie', false, textColor),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool isDonutOption, Color textColor) {
    final active = _isDonut == isDonutOption;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isDonut = isDonutOption),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: active ? _jade : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : textColor, fontWeight: FontWeight.w600, fontSize: 13))),
        ),
      ),
    );
  }

  Widget _donutChart(Map<String, double> totals, double total) {
    return PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 60, sections: _buildSections(totals, total, showTitle: false)));
  }

  Widget _pieChart(Map<String, double> totals, double total) {
    return PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 0, sections: _buildSections(totals, total, showTitle: true)));
  }

  List<PieChartSectionData> _buildSections(Map<String, double> totals, double total, {required bool showTitle}) {
    final categories = totals.keys.toList();
    return categories.asMap().entries.map((entry) {
      final index    = entry.key;
      final category = entry.value;
      final amount   = totals[category]!;
      final percent  = total > 0 ? (amount / total * 100) : 0.0;
      final color    = _categoryColors[index % _categoryColors.length];

      return PieChartSectionData(value: amount, color: color, radius: showTitle ? 90 : 55, title: showTitle ? '${percent.toStringAsFixed(1)}%' : '', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white));
    }).toList();
  }

  Widget _legend(List<String> categories, Color textColor) {
    return Wrap(
      spacing: 16, runSpacing: 8,
      children: categories.asMap().entries.map((entry) {
        final color    = _categoryColors[entry.key % _categoryColors.length];
        final category = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(category, style: TextStyle(fontSize: 12, color: textColor)),
          ],
        );
      }).toList(),
    );
  }

  Widget _categoryCard(String category, double amount, double percent, Color color, Color cardBg, Color textColor, Color hintColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textColor)),
              const SizedBox(height: 2),
              Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: hintColor)),
            ],
          ),
        ],
      ),
    );
  }
}