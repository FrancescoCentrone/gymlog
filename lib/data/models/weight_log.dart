class WeightLog {
  final int? id;
  final double weight;
  final DateTime recordDate;

  WeightLog({
    this.id,
    required this.weight,
    required this.recordDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'recordDate': recordDate.toIso8601String(),
    };
  }

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'] as int?,
      weight: (map['weight'] as num).toDouble(),
      recordDate: DateTime.parse(map['recordDate'] as String),
    );
  }
}
