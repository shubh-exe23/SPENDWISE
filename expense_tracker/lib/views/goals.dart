import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/transaction_controller.dart';
import '../models/goals.dart';
import '../services/api_service.dart';
import 'package:expense_tracker/main.dart';

class GoalsPage extends StatefulWidget {
  final TransactionController controller;
  final List<Goal> goals;
  final VoidCallback onGoalsChanged; 

  const GoalsPage({
    super.key,
    required this.controller,
    required this.goals,
    required this.onGoalsChanged,
  });

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  static const _jade      = Color(0xFF3EB489);
  static const _jadeDark  = Color(0xFF2A7D5F);
  static const _jadeSoft  = Color(0xFFE8F5F0);
  static const _jadeChip  = Color(0xFFCCEDE2);

  double _spentForGoal(Goal goal) {
    return widget.controller.allTransactions
        .where((t) => t.isExpense && t.category == goal.category && !t.date.isBefore(goal.startDate) && !t.date.isAfter(goal.endDate))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalBudget => widget.goals.fold(0.0, (sum, g) => sum + g.budgetAmount);
  double get _totalSpent => widget.goals.fold(0.0, (sum, g) => sum + _spentForGoal(g));
  double get _totalRemaining => _totalBudget - _totalSpent;

  Color _progressColor(double percent) {
    if (percent >= 1.0) return Colors.red;
    if (percent >= 0.8) return Colors.orange;
    return _jade;
  }

  @override
  Widget build(BuildContext context) {
    // ── DARK MODE FORMULA ──
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF6FDFB);
    final cardBg     = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white;
    final textColor  = isDarkMode ? Colors.white : _jadeDark;
    final hintColor  = isDarkMode ? Colors.white54 : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white12 : _jadeChip;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Goals', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGoalSheet,
        backgroundColor: _jade,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: currencyNotifier,
        builder: (context, currency, child) {
          final sym = currency.split(' ')[0];

          return widget.goals.isEmpty
              ? _emptyState(hintColor)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Don't forget to pass 'sym' into these widgets so they update!
                      _overviewSection(cardBg, borderColor, hintColor, sym),
                      const SizedBox(height: 24),
                      Text('Active Goals', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 12),
                      ...widget.goals.map((g) => _goalCard(g, cardBg, textColor, hintColor, borderColor, isDarkMode, sym)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ); // ── FIXED: Semicolon here to end the return statement ──
        }, // ── FIXED: Added closing brace for the builder function ──
      ),
    ); // <-- Closes Scaffold
  } // <-- Closes the build() method

  Widget _emptyState(Color hintColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 72, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No goals created yet.\nCreate your first budget goal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: hintColor, fontSize: 15),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateGoalSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create Goal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _jade,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewSection(Color cardBg, Color borderColor, Color hintColor, String sym) {
    return Row(
      children: [
        // We pass 'sym' down to the summary cards here!
        Expanded(child: _summaryCard('Total Budget', _totalBudget, _jade, cardBg, borderColor, hintColor, sym)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('Spent', _totalSpent, Colors.redAccent, cardBg, borderColor, hintColor, sym)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('Remaining', _totalRemaining, _totalRemaining < 0 ? Colors.red : _jade, cardBg, borderColor, hintColor, sym)),
      ],
    );
  }

  Widget _summaryCard(String label, double amount, Color valColor, Color cardBg, Color borderColor, Color hintColor, String sym) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: hintColor)),
          const SizedBox(height: 6),
          // Replaced hardcoded '₹' with '$sym'
          Text('$sym${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valColor)),
        ],
      ),
    );
  }

  Widget _goalCard(Goal goal, Color cardBg, Color textColor, Color hintColor, Color borderColor, bool isDark, String sym) {
    final spent     = _spentForGoal(goal);
    final remaining = goal.budgetAmount - spent;
    final percent   = goal.budgetAmount > 0 ? (spent / goal.budgetAmount) : 0.0;
    final exceeded  = spent > goal.budgetAmount;
    final color     = _progressColor(percent);

    final startStr = _formatDate(goal.startDate);
    final endStr   = _formatDate(goal.endDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: exceeded ? Colors.red.shade200 : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: isDark ? Colors.white12 : _jadeSoft, borderRadius: BorderRadius.circular(6)),
                          child: Text(goal.category, style: TextStyle(fontSize: 11, color: isDark ? Colors.white : _jadeDark, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (exceeded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text('Exceeded', style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              IconButton(
                onPressed: () => _showEditGoalSheet(goal),
                icon: const Icon(Icons.edit_outlined, size: 18, color: _jade),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white12 : _jadeSoft,
                  padding: const EdgeInsets.all(6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.date_range_outlined, size: 14, color: hintColor),
              const SizedBox(width: 4),
              Text('$startStr → $endStr', style: TextStyle(fontSize: 12, color: hintColor)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Replaced hardcoded '₹' with '$sym'
              Text('$sym${spent.toStringAsFixed(0)} / $sym${goal.budgetAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              Text('${(percent * 100).toStringAsFixed(1)}% Used', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          if (exceeded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 6),
                  // Replaced hardcoded '₹' with '$sym'
                  Text('Exceeded by $sym${(spent - goal.budgetAmount).toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          if (!exceeded) ...[
            const SizedBox(height: 6),
            // Replaced hardcoded '₹' with '$sym'
            Text('$sym${remaining.toStringAsFixed(0)} remaining', style: TextStyle(fontSize: 12, color: hintColor)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showCreateGoalSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _GoalForm(categories: _getCategories(), onSuccess: widget.onGoalsChanged));
  }

  void _showEditGoalSheet(Goal goal) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _GoalForm(categories: _getCategories(), existingGoal: goal, onSuccess: widget.onGoalsChanged));
  }

  List<String> _getCategories() {
    final fromTransactions = widget.controller.allTransactions.map((t) => t.category).toSet().toList();
    final defaults = ['Food', 'Hobbies', 'Study', 'Travel', 'Extra'];
    return {...defaults, ...fromTransactions}.toList();
  }
}

// ════════════════════════════════════════
//         GOAL FORM (bottom sheet)
// ════════════════════════════════════════

class _GoalForm extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onSuccess;
  final Goal? existingGoal;

  const _GoalForm({required this.categories, required this.onSuccess, this.existingGoal});

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  static const _jade     = Color(0xFF3EB489);
  static const _jadeDark = Color(0xFF2A7D5F);

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController(); // Budget field

  String? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate   = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  // ── SLIDER STATE VARIABLES ──
  double _budgetAmount = 0.0;
  double _alertThreshold = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Listen to changes in the budget text field to dynamically update the slider's max limit
    _amountCtrl.addListener(_updateBudgetFromText);

    if (widget.existingGoal != null) {
      final g = widget.existingGoal!;
      _nameCtrl.text      = g.name;
      _amountCtrl.text    = g.budgetAmount.toString();
      _budgetAmount       = g.budgetAmount;
      _selectedCategory   = g.category;
      _startDate          = g.startDate;
      _endDate            = g.endDate;
      if (g.alertThreshold != null) {
        _alertThreshold = g.alertThreshold!;
      }
    }
  }

  void _updateBudgetFromText() {
    setState(() {
      // Safely parse what the user types
      _budgetAmount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
      
      // Auto-correct: If they lower the budget below the threshold, clamp the threshold down
      if (_alertThreshold > _budgetAmount) {
        _alertThreshold = _budgetAmount;
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_updateBudgetFromText); // Clean up memory
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context, initialDate: isStart ? _startDate : _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _jade)), child: child!),
    );
    if (picked != null) setState(() { if (isStart) _startDate = picked; else _endDate = picked; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category'))); return; }
    if (!_endDate.isAfter(_startDate)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after start date'))); return; }

    setState(() => _isLoading = true);

    // If the slider is at 0, that means they don't want an alert. Otherwise, send the slider's value!
    final parsedThreshold = _alertThreshold > 0 ? _alertThreshold : null;

    final goal = Goal(
      id:             widget.existingGoal?.id, 
      name:           _nameCtrl.text.trim(),
      category:       _selectedCategory!,
      budgetAmount:   _budgetAmount,
      startDate:      _startDate,
      endDate:        _endDate,
      alertThreshold: parsedThreshold,
    );

    bool success;
    if (goal.id == null) {
      success = await ApiService.addGoal(goal.toMap()); 
    } else {
      success = await ApiService.updateGoal(goal.id!, goal.toMap()); 
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      widget.onSuccess(); 
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save to database. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF6FDFB);
    final cardBg     = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white;
    final textColor  = isDarkMode ? Colors.white : _jadeDark;
    final hintColor  = isDarkMode ? Colors.white54 : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFCCEDE2);
    final chipBg     = isDarkMode ? const Color(0xFF3B3B4F) : const Color(0xFFCCEDE2);

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(widget.existingGoal != null ? 'Edit Goal' : 'Create Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 20),
              
              _label('Goal Name', textColor), const SizedBox(height: 8),
              _field(controller: _nameCtrl, hint: 'e.g. June Budget, Vacation Budget', icon: Icons.flag_outlined, cardBg: cardBg, textColor: textColor, hintColor: hintColor, borderColor: borderColor, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null),
              const SizedBox(height: 20),
              
              _label('Category', textColor), const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: widget.categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: selected ? _jade : chipBg, borderRadius: BorderRadius.circular(10)),
                      child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : textColor)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              _label('Budget Amount', textColor), const SizedBox(height: 8),
              _field(controller: _amountCtrl, hint: '0.00', icon: Icons.currency_rupee, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], cardBg: cardBg, textColor: textColor, hintColor: hintColor, borderColor: borderColor, validator: (v) { if (v == null || v.trim().isEmpty) return 'Amount cannot be empty'; if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter a valid amount greater than 0'; return null; }),
              const SizedBox(height: 24),

              // ── THE NEW SLIDER COMPONENT ──
              _label('Alert me when spent reaches (optional)', textColor),
              const SizedBox(height: 12),
              if (_budgetAmount > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹0', style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _jade.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('₹${_alertThreshold.toStringAsFixed(0)}', style: const TextStyle(color: _jade, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    Text('₹${_budgetAmount.toStringAsFixed(0)}', style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _jade,
                    inactiveTrackColor: isDarkMode ? Colors.white12 : const Color(0xFFCCEDE2),
                    thumbColor: _jade,
                    overlayColor: _jade.withOpacity(0.2),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: _alertThreshold,
                    min: 0,
                    max: _budgetAmount,
                    // Leaving 'divisions' out so it drags completely smooth like butter!
                    onChanged: (val) {
                      setState(() => _alertThreshold = val);
                    },
                  ),
                ),
                Center(
                  child: Text(
                    _alertThreshold == 0 
                      ? 'No alert set' 
                      : 'You will be notified when spending hits ₹${_alertThreshold.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: hintColor, fontStyle: FontStyle.italic),
                  ),
                ),
              ] else ...[
                // Shows a placeholder block if they haven't typed a budget yet
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white12 : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    'Enter a budget amount above to set an alert limit.', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 12, color: hintColor)
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Start Date', textColor), const SizedBox(height: 8), _dateBox(_startDate, () => _pickDate(isStart: true), cardBg, borderColor, textColor)])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('End Date', textColor), const SizedBox(height: 8), _dateBox(_endDate, () => _pickDate(isStart: false), cardBg, borderColor, textColor)])),
                ],
              ),
              const SizedBox(height: 28),
              
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: borderColor))), child: Text('Cancel', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: _jade, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.existingGoal != null ? 'Update Goal' : 'Save Goal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color textColor) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor, letterSpacing: 0.5));
  
  Widget _field({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator, required Color cardBg, required Color textColor, required Color hintColor, required Color borderColor}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, inputFormatters: inputFormatters, validator: validator, style: TextStyle(fontSize: 15, color: textColor),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: hintColor), prefixIcon: Icon(icon, color: _jade, size: 20), filled: true, fillColor: cardBg, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _jade, width: 1.5)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent))),
    );
  }

  Widget _dateBox(DateTime date, VoidCallback onTap, Color cardBg, Color borderColor, Color textColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: _jade, size: 16), const SizedBox(width: 8),
            Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}', style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}