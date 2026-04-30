class WorkoutSession {
  final int? id;
  final int? routineId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;

  WorkoutSession({
    this.id,
    this.routineId,
    required this.startTime,
    this.endTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'] as int?,
      routineId: map['routineId'] as int?,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      notes: map['notes'] as String?,
    );
  }

  WorkoutSession copyWith({
    int? id,
    int? routineId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }
}
