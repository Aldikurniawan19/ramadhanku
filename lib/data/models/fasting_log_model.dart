class FastingLogModel {
  final String date; // YYYY-MM-DD
  final bool isCompleted;
  final String notes;

  FastingLogModel({
    required this.date,
    required this.isCompleted,
    this.notes = '',
  });

  factory FastingLogModel.fromMap(Map<String, dynamic> map, String date) {
    return FastingLogModel(
      date: date,
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }
}
