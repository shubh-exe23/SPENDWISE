import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction.dart';

class FloatingAction extends StatefulWidget {
  final TransactionController controller;
  const FloatingAction({super.key, required this.controller});

  @override
  State<FloatingAction> createState() => _FloatingActionState();
}

class _FloatingActionState extends State<FloatingAction> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';
  bool _isExpense = true;
  bool _isSaving = false;

  final List<String> _categories = ['Food', 'Hobbies', 'Study', 'Travel', 'Extra'];
  static const _jade = Color(0xFF3EB489);

  @override
  void dispose() { _title.dispose(); _amount.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _jade)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showCreateCategoryDialog(Color cardBg, Color textColor) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Category', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        content: TextField(
          controller: controller, autofocus: true, textCapitalization: TextCapitalization.words,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(hintText: 'e.g. Health', hintStyle: TextStyle(color: Colors.grey.shade500), filled: true, fillColor: cardBg == Colors.white ? const Color(0xFFE8F5F0) : Colors.white12, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _jade, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) { setState(() { _categories.add(name); _selectedCategory = name; }); Navigator.pop(context); }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onCancel(Color cardBg, Color textColor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Discard Expense?', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        content: Text('Are you sure you want to discard this expense?', style: TextStyle(color: textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No', style: TextStyle(color: _jade))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final transaction = Transaction(title: _title.text.trim(), amount: double.parse(_amount.text.trim()), isExpense: _isExpense, date: _selectedDate, category: _selectedCategory);
    final success = await widget.controller.addTransaction(transaction);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) { Navigator.pop(context); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save transaction. Try again.'), backgroundColor: Colors.redAccent)); }
  }

  @override
  Widget build(BuildContext context) {
    // ── DARK MODE FORMULA ──
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF6FDFB);
    final cardBg     = isDarkMode ? const Color(0xFF2A2A3E) : Colors.white;
    final textColor  = isDarkMode ? Colors.white : const Color(0xFF2A7D5F);
    final hintColor  = isDarkMode ? Colors.white54 : Colors.grey.shade400;
    final borderColor = isDarkMode ? Colors.white12 : const Color(0xFFCCEDE2);
    final chipBg     = isDarkMode ? const Color(0xFF3B3B4F) : const Color(0xFFCCEDE2);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        title: Text('Add Transaction', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 18)),
        leading: IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => _onCancel(cardBg, textColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Type', textColor), const SizedBox(height: 8),
              _typeToggle(isDarkMode, textColor), const SizedBox(height: 24),
              _sectionLabel('Purpose', textColor), const SizedBox(height: 8),
              _styledField(controller: _title, hint: 'e.g. Lunch, Books, Netflix', icon: Icons.edit_outlined, validator: (v) => (v == null || v.trim().isEmpty) ? 'Purpose cannot be empty' : null, cardBg: cardBg, textColor: textColor, hintColor: hintColor, borderColor: borderColor),
              const SizedBox(height: 24),
              _sectionLabel('Amount', textColor), const SizedBox(height: 8),
              _styledField(controller: _amount, hint: '0.00', icon: Icons.currency_rupee, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (v) { if (v == null || v.trim().isEmpty) return 'Amount cannot be empty'; if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter a valid amount greater than 0'; return null; }, cardBg: cardBg, textColor: textColor, hintColor: hintColor, borderColor: borderColor),
              const SizedBox(height: 24),
              _sectionLabel('Spending Date', textColor), const SizedBox(height: 8),
              _dateSelector(cardBg, textColor, borderColor), const SizedBox(height: 24),
              _sectionLabel('Category', textColor), const SizedBox(height: 12),
              _categorySelector(cardBg, chipBg, textColor, borderColor), const SizedBox(height: 40),
              _actionButtons(borderColor, textColor, cardBg), const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color textColor) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor, letterSpacing: 0.5));

  Widget _typeToggle(bool isDarkMode, Color textColor) {
    return Container(
      decoration: BoxDecoration(color: isDarkMode ? Colors.white12 : const Color(0xFFE8F5F0), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleOption('Expense', true, textColor),
          _toggleOption('Income', false, textColor),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool value, Color textColor) {
    final active = _isExpense == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpense = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: active ? _jade : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : textColor, fontWeight: FontWeight.w600, fontSize: 14))),
        ),
      ),
    );
  }

  Widget _styledField({required TextEditingController controller, required String hint, required IconData icon, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator, required Color cardBg, required Color textColor, required Color hintColor, required Color borderColor}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, inputFormatters: inputFormatters, validator: validator, style: TextStyle(fontSize: 15, color: textColor),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: hintColor), prefixIcon: Icon(icon, color: _jade, size: 20), filled: true, fillColor: cardBg, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _jade, width: 1.5)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent))),
    );
  }

  Widget _dateSelector(Color cardBg, Color textColor, Color borderColor) {
    final formatted = '${_selectedDate.day.toString().padLeft(2, '0')} / ${_selectedDate.month.toString().padLeft(2, '0')} / ${_selectedDate.year}';
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: _jade, size: 20), const SizedBox(width: 12),
            Text(formatted, style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500)),
            const Spacer(), const Icon(Icons.chevron_right, color: _jade),
          ],
        ),
      ),
    );
  }

  Widget _categorySelector(Color cardBg, Color chipBg, Color textColor, Color borderColor) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: [
        ..._categories.map((cat) => _categoryChip(cat, chipBg, textColor)),
        GestureDetector(
          onTap: () => _showCreateCategoryDialog(cardBg, textColor),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _jade, width: 1.2)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: _jade, size: 16), SizedBox(width: 4),
                Text('Create Category', style: TextStyle(color: _jade, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(String label, Color chipBg, Color textColor) {
    final selected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(color: selected ? _jade : chipBg, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : textColor, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _actionButtons(Color borderColor, Color textColor, Color cardBg) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => _onCancel(cardBg, textColor),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: borderColor))),
            child: Text('Cancel', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _onSave,
            style: ElevatedButton.styleFrom(backgroundColor: _jade, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}