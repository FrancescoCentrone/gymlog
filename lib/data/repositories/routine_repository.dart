
import 'package:gym_log/data/database/database_helper.dart';
import 'package:gym_log/data/models/routine_model.dart';
import 'package:gym_log/data/models/exercise_model.dart';
import 'package:gym_log/data/enums/muscle_group.dart';
import 'package:gym_log/data/enums/muscle.dart';

class RoutineRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Routine>> getAllRoutines() async {
    final db = await _databaseHelper.database;
    final routinesResult = await db.query('routines', orderBy: 'name ASC');

    List<Routine> routines = [];
    for (var routineMap in routinesResult) {
      final routine = Routine.fromMap(routineMap);
      final exercises = await _getRoutineExercises(routine.id!);
      routines.add(routine.copyWith(exercises: exercises));
    }
    return routines;
  }

  Future<List<RoutineExercise>> _getRoutineExercises(int routineId) async {
    final db = await _databaseHelper.database;
    
    // Join with exercises table to get exercise details
    final result = await db.rawQuery('''
      SELECT re.*, e.name as exercise_name, e.description as exercise_desc, 
             e.primaryMuscleGroup, e.primaryMuscle, e.secondaryMuscle, e.isCustom, e.notes as exercise_notes
      FROM routine_exercises re
      INNER JOIN exercises e ON re.exerciseId = e.id
      WHERE re.routineId = ?
      ORDER BY re.orderIndex ASC
    ''', [routineId]);

    return result.map((row) {
      final exercise = Exercise(
        id: row['exerciseId'] as int,
        name: row['exercise_name'] as String,
        description: row['exercise_desc'] as String,
        primaryMuscleGroup: MuscleGroup.fromString(row['primaryMuscleGroup'] as String),
        primaryMuscle: Muscle.fromString(row['primaryMuscle'] as String),
        secondaryMuscle: row['secondaryMuscle'] != null ? Muscle.fromString(row['secondaryMuscle'] as String) : null,
        isCustom: (row['isCustom'] as int) == 1,
        notes: row['exercise_notes'] as String?,
      );
      
      return RoutineExercise.fromMap(row, exercise: exercise);
    }).toList();
  }

  Future<Routine?> getRoutineById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      final routine = Routine.fromMap(result.first);
      final exercises = await _getRoutineExercises(id);
      return routine.copyWith(exercises: exercises);
    } else {
      return null;
    }
  }

  Future<int> createRoutine(Routine routine) async {
    final db = await _databaseHelper.database;
    return await db.transaction((txn) async {
      final routineId = await txn.insert('routines', routine.toMap());

      for (var routineExercise in routine.exercises) {
        final exerciseToInsert = routineExercise.copyWith(routineId: routineId);
        await txn.insert('routine_exercises', exerciseToInsert.toMap());
      }
      return routineId;
    });
  }

  Future<void> updateRoutine(Routine routine) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'routines',
        routine.toMap(),
        where: 'id = ?',
        whereArgs: [routine.id],
      );

      // Simple strategy: delete all existing exercises for this routine and re-insert
      // This handles reordering, additions, and deletions cleanly
      await txn.delete(
        'routine_exercises',
        where: 'routineId = ?',
        whereArgs: [routine.id],
      );

      for (var routineExercise in routine.exercises) {
        final exerciseToInsert = routineExercise.copyWith(routineId: routine.id);
        await txn.insert('routine_exercises', exerciseToInsert.toMap());
      }
    });
  }

  Future<int> deleteRoutine(int id) async {
    final db = await _databaseHelper.database;
    // Cascade delete is set up in database_helper.dart, so deleting routine deletes its exercises
    return await db.delete(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
