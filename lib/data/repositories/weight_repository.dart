import 'package:gym_log/data/database/database_helper.dart';
import 'package:gym_log/data/models/weight_log.dart';

class WeightRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<WeightLog>> getAllWeightLogs() async {
    final db = await _databaseHelper.database;
    final result = await db.query('weight_logs', orderBy: 'recordDate DESC');
    return result.map((json) => WeightLog.fromMap(json)).toList();
  }

  Future<int> createWeightLog(WeightLog log) async {
    final db = await _databaseHelper.database;
    return await db.insert('weight_logs', log.toMap());
  }

  Future<int> updateWeightLog(WeightLog log) async {
    if (log.id == null) {
      throw ArgumentError('Cannot update weight log without an id');
    }

    final db = await _databaseHelper.database;
    return await db.update(
      'weight_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteWeightLog(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'weight_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
