class Goal {
  final int? id; // ── REQUIRED FOR DATABASE SAVING/EDITING ──
  final String name;
  final String category;
  final double budgetAmount;
  final DateTime startDate;
  final DateTime endDate;
  final double? alertThreshold;

  Goal({
    this.id,
    required this.name,
    required this.category,
    required this.budgetAmount,
    required this.startDate,
    required this.endDate,
    this.alertThreshold,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name':            name,
      'category':        category,
      'budget_amount':   budgetAmount,
      'start_date':      startDate.toIso8601String(),
      'end_date':        endDate.toIso8601String(),
      'alert_threshold': alertThreshold,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id:             map['id'],
      name:           map['name'],
      category:       map['category'],
      budgetAmount:   (map['budget_amount'] as num).toDouble(),
      startDate:      DateTime.parse(map['start_date']),
      endDate:        DateTime.parse(map['end_date']),
      alertThreshold: map['alert_threshold'] != null
          ? (map['alert_threshold'] as num).toDouble()
          : null,
    );
  }
}