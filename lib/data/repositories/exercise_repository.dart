
import 'package:gym_log/data/database/database_helper.dart';
import 'package:gym_log/data/models/exercise_model.dart';

class ExerciseRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<Exercise>> getAllExercises() async {
    final db = await _databaseHelper.database;
    final result = await db.query('exercises', orderBy: 'name ASC');
    return result.map((json) => Exercise.fromMap(json)).toList();
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Exercise.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> createExercise(Exercise exercise) async {
    final db = await _databaseHelper.database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await _databaseHelper.database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
