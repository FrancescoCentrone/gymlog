
import 'package:gym_log/data/models/exercise_model.dart';

class Routine {
  final int? id;
  final String name;
  final List<RoutineExercise> exercises;

  Routine({
    this.id,
    required this.name,
    this.exercises = const [],
  });

  Routine copyWith({
    int? id,
    String? name,
    List<RoutineExercise>? exercises,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map, {List<RoutineExercise> exercises = const []}) {
    return Routine(
      id: map['id'] as int?,
      name: map['name'] as String,
      exercises: exercises,
    );
  }
}

class RoutineExercise {
  final int? id;
  final int? routineId;
  final int exerciseId;
  final int sets;
  final int minReps;
  final int maxReps;
  final int restSeconds;
  final int orderIndex;
  final String? notes;
  final Exercise? exercise; // For display purposes

  RoutineExercise({
    this.id,
    this.routineId,
    required this.exerciseId,
    required this.sets,
    required this.minReps,
    required this.maxReps,
    required this.restSeconds,
    required this.orderIndex,
    this.notes,
    this.exercise,
  });

  RoutineExercise copyWith({
    int? id,
    int? routineId,
    int? exerciseId,
    int? sets,
    int? minReps,
    int? maxReps,
    int? restSeconds,
    int? orderIndex,
    String? notes,
    Exercise? exercise,
  }) {
    return RoutineExercise(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      restSeconds: restSeconds ?? this.restSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      exercise: exercise ?? this.exercise,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'exerciseId': exerciseId,
      'sets': sets,
      'minReps': minReps,
      'maxReps': maxReps,
      'restSeconds': restSeconds,
      'orderIndex': orderIndex,
      'notes': notes,
    };
  }

  factory RoutineExercise.fromMap(Map<String, dynamic> map, {Exercise? exercise}) {
    return RoutineExercise(
      id: map['id'] as int?,
      routineId: map['routineId'] as int?,
      exerciseId: map['exerciseId'] as int,
      sets: map['sets'] as int,
      minReps: map['minReps'] as int,
      maxReps: map['maxReps'] as int,
      restSeconds: map['restSeconds'] as int,
      orderIndex: map['orderIndex'] as int,
      notes: map['notes'] as String?,
      exercise: exercise,
    );
  }
}
