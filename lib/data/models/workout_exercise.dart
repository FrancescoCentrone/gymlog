import 'package:gym_log/data/models/exercise_model.dart';

class WorkoutExercise {
  final int? id;
  final int workoutId;
  final int exerciseId;
  final int orderIndex;
  final int targetSets;
  final int targetMinReps;
  final int targetMaxReps;
  final int restSeconds;
  final String? notes;
  final Exercise? exercise; // Helper for UI display

  WorkoutExercise({
    this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.orderIndex,
    required this.targetSets,
    required this.targetMinReps,
    required this.targetMaxReps,
    required this.restSeconds,
    this.notes,
    this.exercise,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'targetSets': targetSets,
      'targetMinReps': targetMinReps,
      'targetMaxReps': targetMaxReps,
      'restSeconds': restSeconds,
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map, {Exercise? exercise}) {
    return WorkoutExercise(
      id: map['id'] as int?,
      workoutId: map['workoutId'] as int,
      exerciseId: map['exerciseId'] as int,
      orderIndex: map['orderIndex'] as int,
      targetSets: map['targetSets'] as int,
      targetMinReps: map['targetMinReps'] as int,
      targetMaxReps: map['targetMaxReps'] as int,
      restSeconds: map['restSeconds'] as int? ?? 60,
      notes: map['notes'] as String?,
      exercise: exercise,
    );
  }
}
