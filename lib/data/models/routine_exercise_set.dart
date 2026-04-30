class RoutineExerciseSet {
  final int setIndex;
  final int reps;
  final int? minReps; // For range: minReps to maxReps
  final int? maxReps; // For range: minReps to maxReps
  final bool isRange; // true if using range, false if using specific count

  RoutineExerciseSet({
    required this.setIndex,
    required this.reps,
    this.minReps,
    this.maxReps,
    this.isRange = false,
  });

  RoutineExerciseSet copyWith({
    int? setIndex,
    int? reps,
    int? minReps,
    int? maxReps,
    bool? isRange,
  }) {
    return RoutineExerciseSet(
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      isRange: isRange ?? this.isRange,
    );
  }

  String get displayReps {
    if (isRange && minReps != null && maxReps != null) {
      return '$minReps-$maxReps';
    }
    return reps.toString();
  }
}
