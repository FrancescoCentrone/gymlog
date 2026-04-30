class WorkoutSet {
  final int? id;
  final int workoutId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final int partialReps;
  final double weight;
  final double? rpe;
  final DateTime completedAt;

  WorkoutSet({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    this.partialReps = 0,
    required this.weight,
    this.rpe,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'setNumber': setNumber,
      'reps': reps,
      'partialReps': partialReps,
      'weight': weight,
      'rpe': rpe,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as int?,
      workoutId: map['workoutId'] as int,
      exerciseId: map['exerciseId'] as int,
      setNumber: map['setNumber'] as int,
      reps: map['reps'] as int,
      partialReps: (map['partialReps'] as int?) ?? 0,
      weight: (map['weight'] as num).toDouble(),
      rpe: map['rpe'] != null ? (map['rpe'] as num).toDouble() : null,
      completedAt: DateTime.parse(map['completedAt'] as String),
    );
  }

  WorkoutSet copyWith({
    int? id,
    int? workoutId,
    int? exerciseId,
    int? setNumber,
    int? reps,
    int? partialReps,
    double? weight,
    double? rpe,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      partialReps: partialReps ?? this.partialReps,
      weight: weight ?? this.weight,
      rpe: rpe ?? this.rpe,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
