import 'package:gym_log/data/database/database_helper.dart';
import 'package:gym_log/data/models/workout_session.dart';
import 'package:gym_log/data/models/workout_set.dart';
import 'package:gym_log/data/models/workout_exercise.dart';
import 'package:gym_log/data/models/exercise_model.dart';
import 'package:gym_log/data/enums/muscle_group.dart';
import 'package:gym_log/data/enums/muscle.dart';

class WorkoutRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> createWorkoutSession(WorkoutSession session) async {
    final db = await _databaseHelper.database;
    final workoutId = await db.insert('workouts', session.toMap());

    // Only copy exercises if routineId is present and valid
    if (session.routineId != null && session.routineId! > 0) {
      // Copy exercises from routine to workout
      final routineExercisesResult = await db.query(
        'routine_exercises',
        where: 'routineId = ?',
        whereArgs: [session.routineId],
      );

      final batch = db.batch();
      for (final map in routineExercisesResult) {
        batch.insert('workout_exercises', {
          'workoutId': workoutId,
          'exerciseId': map['exerciseId'],
          'orderIndex': map['orderIndex'],
          'targetSets': map['sets'],
          'targetMinReps': map['minReps'],
          'targetMaxReps': map['maxReps'],
          'notes': map['notes'],
        });
      }
      await batch.commit(noResult: true);
    }
    return workoutId;
  }

  Future<WorkoutSession?> getWorkoutSessionByDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'workouts',
      where: 'startTime BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      limit: 1, // Assuming one workout per day for now, or taking the first one
    );

    if (result.isNotEmpty) {
      return WorkoutSession.fromMap(result.first);
    }
    return null;
  }

  Future<WorkoutSession?> getTodayWorkoutSession(int? routineId) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final String whereClause;
    final List<dynamic> whereArgs;

    if (routineId != null) {
      whereClause = 'routineId = ? AND startTime BETWEEN ? AND ?';
      whereArgs = [routineId, todayStart, todayEnd];
    } else {
      whereClause = 'routineId IS NULL AND startTime BETWEEN ? AND ?';
      whereArgs = [todayStart, todayEnd];
    }

    final result = await db.query(
      'workouts',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (result.isNotEmpty) {
      return WorkoutSession.fromMap(result.first);
    }
    return null;
  }

  Future<int> logSet(WorkoutSet set) async {
    final db = await _databaseHelper.database;
    return await db.insert('workout_sets', set.toMap());
  }

  Future<List<WorkoutSet>> getWorkoutSets(int workoutId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'workout_sets',
      where: 'workoutId = ?',
      whereArgs: [workoutId],
      orderBy: 'completedAt ASC',
    );

    return result.map((map) => WorkoutSet.fromMap(map)).toList();
  }

  Future<void> updateSessionRoutineId(int sessionId, int? routineId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'workouts',
      {'routineId': routineId},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Adds exercises from a routine to an existing workout session,
  /// skipping any exercises that are already in that workout.
  Future<void> addRoutineExercisesToWorkout(int workoutId, int routineId) async {
    final db = await _databaseHelper.database;

    final routineExercisesResult = await db.query(
      'routine_exercises',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );

    // Get already-existing exercise ids in this workout to avoid duplicates
    final existingResult = await db.query(
      'workout_exercises',
      columns: ['exerciseId'],
      where: 'workoutId = ?',
      whereArgs: [workoutId],
    );
    final existingIds = existingResult.map((r) => r['exerciseId'] as int).toSet();

    // Get max current orderIndex
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(orderIndex) as maxOrder FROM workout_exercises WHERE workoutId = ?',
      [workoutId],
    );
    int nextOrder = 0;
    if (maxOrderResult.isNotEmpty && maxOrderResult.first['maxOrder'] != null) {
      nextOrder = (maxOrderResult.first['maxOrder'] as int) + 1;
    }

    final batch = db.batch();
    for (final map in routineExercisesResult) {
      final exerciseId = map['exerciseId'] as int;
      if (!existingIds.contains(exerciseId)) {
        batch.insert('workout_exercises', {
          'workoutId': workoutId,
          'exerciseId': exerciseId,
          'orderIndex': nextOrder++,
          'targetSets': map['sets'],
          'targetMinReps': map['minReps'],
          'targetMaxReps': map['maxReps'],
          'restSeconds': map['restSeconds'],
          'notes': map['notes'],
        });
      }
    }
    await batch.commit(noResult: true);
  }

  Future<int> addExerciseToWorkout(int workoutId, int exerciseId, {int sets = 3, int minReps = 8, int maxReps = 12, int restSeconds = 60}) async {
    final db = await _databaseHelper.database;
    // Get max order index for this workout
    final maxOrderResult = await db.rawQuery('SELECT MAX(orderIndex) as maxOrder FROM workout_exercises WHERE workoutId = ?', [workoutId]);
    int newOrder = 0;
    if (maxOrderResult.isNotEmpty && maxOrderResult.first['maxOrder'] != null) {
      newOrder = (maxOrderResult.first['maxOrder'] as int) + 1;
    }

    return await db.insert('workout_exercises', {
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'orderIndex': newOrder,
      'targetSets': sets,
      'targetMinReps': minReps,
      'targetMaxReps': maxReps,
      'restSeconds': restSeconds,
      'notes': '', 
    });
  }

  Future<List<WorkoutExercise>> getWorkoutExercises(int workoutId) async {
    final db = await _databaseHelper.database;
    
    // Join with exercises table to get details
    final result = await db.rawQuery('''
      SELECT we.*, e.name, e.description, e.primaryMuscleGroup, e.primaryMuscle, e.secondaryMuscle, e.isCustom
      FROM workout_exercises we
      INNER JOIN exercises e ON we.exerciseId = e.id
      WHERE we.workoutId = ?
      ORDER BY we.orderIndex ASC
    ''', [workoutId]);

    return result.map((map) {
      final exercise = Exercise(
        id: map['exerciseId'] as int,
        name: map['name'] as String,
        description: map['description'] as String,
        primaryMuscleGroup: MuscleGroup.fromString(map['primaryMuscleGroup'] as String),
        primaryMuscle: Muscle.fromString(map['primaryMuscle'] as String),
        secondaryMuscle: map['secondaryMuscle'] != null ? Muscle.fromString(map['secondaryMuscle'] as String) : null,
        isCustom: (map['isCustom'] as int) == 1,
      );
      
      return WorkoutExercise.fromMap(map, exercise: exercise);
    }).toList();
  }

  Future<void> deleteWorkoutSet(int setId) async {
    final db = await _databaseHelper.database;
    await db.delete('workout_sets', where: 'id = ?', whereArgs: [setId]);
  }

  Future<void> deleteWorkoutExercise(int workoutId, int exerciseId) async {
    final db = await _databaseHelper.database;
    // First delete all sets for this workout exercise
    await db.delete(
      'workout_sets',
      where: 'workoutId = ? AND exerciseId = ?',
      whereArgs: [workoutId, exerciseId],
    );
    // Then delete the workout exercise itself
    await db.delete(
      'workout_exercises',
      where: 'workoutId = ? AND exerciseId = ?',
      whereArgs: [workoutId, exerciseId],
    );
  }

  Future<void> updateWorkoutSet(int setId, double weight, int reps, {int partialReps = 0, double? rpe}) async {
    final db = await _databaseHelper.database;
    await db.update(
      'workout_sets',
      {'weight': weight, 'reps': reps, 'partialReps': partialReps, 'rpe': rpe},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  Future<void> updateWorkoutSetNumber(int setId, int newNumber) async {
    final db = await _databaseHelper.database;
    await db.update(
      'workout_sets',
      {'setNumber': newNumber},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  Future<WorkoutSession?> getWorkoutSessionById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return WorkoutSession.fromMap(result.first);
    }
    return null;
  }

  Future<List<WorkoutSet>> getLastTimeExerciseSets(int exerciseId, DateTime beforeDate) async {
    final db = await _databaseHelper.database;
    final beforeDateStr = beforeDate.toIso8601String();

    // 1. Find the most recent workout containing this exercise BEFORE the provided date
    // We check workout_sets to ensure we only look at workouts where the user actually did the exercise.
    
    final lastWorkoutResult = await db.rawQuery('''
      SELECT w.id 
      FROM workouts w
      INNER JOIN workout_sets ws ON w.id = ws.workoutId
      WHERE ws.exerciseId = ? AND w.startTime < ?
      ORDER BY w.startTime DESC
      LIMIT 1
    ''', [exerciseId, beforeDateStr]);

    if (lastWorkoutResult.isEmpty) {
      return [];
    }

    final lastWorkoutId = lastWorkoutResult.first['id'] as int;

    // 2. Fetch sets for that workout
    return getWorkoutSets(lastWorkoutId).then((sets) => 
      sets.where((s) => s.exerciseId == exerciseId).toList()
    );
  }

  Future<Map<DateTime, List<WorkoutSet>>> getExerciseHistory(int exerciseId) async {
    final db = await _databaseHelper.database;
    
    // Fetch all sets for this exercise with workout dates
    final result = await db.rawQuery('''
      SELECT ws.*, w.startTime
      FROM workout_sets ws
      INNER JOIN workouts w ON ws.workoutId = w.id
      WHERE ws.exerciseId = ?
      ORDER BY w.startTime DESC, ws.setNumber ASC
    ''', [exerciseId]);

    // Group by workout date
    final Map<DateTime, List<WorkoutSet>> groupedSets = {};
    
    for (final row in result) {
      final workoutDate = DateTime.parse(row['startTime'] as String);
      // Normalize to day (remove time component for grouping)
      final dateKey = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);
      
      final set = WorkoutSet.fromMap(row);
      
      if (!groupedSets.containsKey(dateKey)) {
        groupedSets[dateKey] = [];
      }
      groupedSets[dateKey]!.add(set);
    }

    return groupedSets;
  }

  Future<Map<String, dynamic>> getExerciseRecords(int exerciseId) async {
    final db = await _databaseHelper.database;
    
    // Fetch all sets for this exercise with dates
    final result = await db.rawQuery('''
      SELECT ws.*, w.startTime
      FROM workout_sets ws
      INNER JOIN workouts w ON ws.workoutId = w.id
      WHERE ws.exerciseId = ?
    ''', [exerciseId]);

    if (result.isEmpty) {
      return {}; // No records yet
    }

    // Calculate records
    double maxWeight = 0;
    Map<String, dynamic>? maxWeightRecord;
    
    int maxReps = 0;
    Map<String, dynamic>? maxRepsRecord;
    
    double maxVolumeSingleSet = 0;
    Map<String, dynamic>? maxVolumeSetRecord;
    
    double maxEstimated1RM = 0;
    Map<String, dynamic>? max1RMRecord;

    // Track workout volumes
    Map<int, double> workoutVolumes = {};
    Map<int, DateTime> workoutDates = {};

    for (final row in result) {
      final weight = (row['weight'] as num).toDouble();
      final reps = row['reps'] as int;
      final workoutId = row['workoutId'] as int;
      final date = DateTime.parse(row['startTime'] as String);
      
      final volume = weight * reps;
      final estimated1RM = weight * (1 + reps / 30.0); // Epley formula

      // Track max weight
      if (weight > maxWeight) {
        maxWeight = weight;
        maxWeightRecord = {'weight': weight, 'reps': reps, 'date': date};
      }

      // Track max reps
      if (reps > maxReps) {
        maxReps = reps;
        maxRepsRecord = {'reps': reps, 'weight': weight, 'date': date};
      }

      // Track max volume (single set)
      if (volume > maxVolumeSingleSet) {
        maxVolumeSingleSet = volume;
        maxVolumeSetRecord = {'volume': volume, 'weight': weight, 'reps': reps, 'date': date};
      }

      // Track estimated 1RM
      if (estimated1RM > maxEstimated1RM) {
        maxEstimated1RM = estimated1RM;
        max1RMRecord = {'value': estimated1RM, 'fromWeight': weight, 'fromReps': reps, 'date': date};
      }

      // Accumulate workout volumes
      workoutVolumes[workoutId] = (workoutVolumes[workoutId] ?? 0) + volume;
      workoutDates[workoutId] = date;
    }

    // Find best workout volume
    double maxWorkoutVolume = 0;
    DateTime? maxWorkoutDate;
    workoutVolumes.forEach((workoutId, volume) {
      if (volume > maxWorkoutVolume) {
        maxWorkoutVolume = volume;
        maxWorkoutDate = workoutDates[workoutId];
      }
    });

    return {
      'maxWeight': maxWeightRecord,
      'maxReps': maxRepsRecord,
      'maxVolumeSingleSet': maxVolumeSetRecord,
      'maxVolumeWorkout': {'volume': maxWorkoutVolume, 'date': maxWorkoutDate},
      'estimated1RM': max1RMRecord,
    };
  }

  Future<Map<DateTime, Map<MuscleGroup, double>>> getWeeklySetsByMuscleGroup() async {
    final db = await _databaseHelper.database;

    // Get all sets with their date and muscle group
    final result = await db.rawQuery('''
      SELECT w.startTime, e.primaryMuscleGroup, e.primaryMuscle, e.secondaryMuscle
      FROM workout_sets ws
      INNER JOIN workouts w ON ws.workoutId = w.id
      INNER JOIN exercises e ON ws.exerciseId = e.id
      ORDER BY w.startTime ASC
    ''');

    final Map<DateTime, Map<MuscleGroup, double>> weeklySets = {};

    for (final row in result) {
      final date = DateTime.parse(row['startTime'] as String);
      // Find start of the week (Monday)
      // subtract (weekday - 1) days to get to Monday
      final startOfWeek = DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1));

      final primaryMuscleGroupString = row['primaryMuscleGroup'] as String;
      final primaryMuscleGroup = MuscleGroup.fromString(primaryMuscleGroupString);
      
      final secondaryMuscleString = row['secondaryMuscle'] as String?;
      final secondaryMuscle = secondaryMuscleString != null 
          ? Muscle.fromString(secondaryMuscleString) 
          : null;

      if (!weeklySets.containsKey(startOfWeek)) {
        weeklySets[startOfWeek] = {};
      }

      final weekMap = weeklySets[startOfWeek]!;
      
      // Primary muscle group counts as 1 set
      weekMap[primaryMuscleGroup] = (weekMap[primaryMuscleGroup] ?? 0.0) + 1.0;
      
      // Secondary muscle's group counts as 0.5 sets
      if (secondaryMuscle != null) {
        final secondaryMuscleGroup = secondaryMuscle.muscleGroup;
        weekMap[secondaryMuscleGroup] = (weekMap[secondaryMuscleGroup] ?? 0.0) + 0.5;
      }
    }

    return weeklySets;
  }
}
