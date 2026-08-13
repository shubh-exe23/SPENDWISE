class Transaction {
  final String title;
  final double amount;
  final bool isExpense;
  final DateTime date;
  final String category;

  Transaction({
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.date,
    required this.category,
  });

  // ADD after your existing constructor

Map<String, dynamic> toMap() {
  return {
    'title':      title,
    'amount':     amount,
    'is_expense': isExpense,
    'date':       date.toIso8601String(),
    'category':   category,
  };
}

factory Transaction.fromMap(Map<String, dynamic> map) {
  return Transaction(
    title:     map['title'],
    amount:    (map['amount'] as num).toDouble(),
    isExpense: map['is_expense'],
    date:      DateTime.parse(map['date']),
    category:  map['category'],
  );
}

  Transaction.empty()
      : title = '',
        amount = 0.0,
        isExpense = false,
        date = DateTime.now(),
        category = '';
}