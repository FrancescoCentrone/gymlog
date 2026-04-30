import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:gym_log/data/database/database_helper.dart';

class ImportExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List of tables to export/import
  final List<String> _tables = [
    'exercises',
    'routines',
    'routine_exercises',
    'workouts',
    'workout_exercises',
    'workout_sets',
    'user_profile',
    'bia_reports',
    'weight_logs',
  ];

  Future<String> exportData() async {
    final db = await _dbHelper.database;
    final Map<String, List<Map<String, dynamic>>> allData = {};

    for (final table in _tables) {
      allData[table] = await db.query(table);
    }

    return jsonEncode(allData);
  }

  Future<bool> importData(String jsonString, {required bool override}) async {
    try {
      final Map<String, dynamic> dataMap = jsonDecode(jsonString);
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        if (override) {
          // Clear all tables
          for (final table in _tables.reversed) {
            await txn.delete(table);
          }
          
          // Re-insert data exactly as it was
          for (final table in _tables) {
            if (dataMap.containsKey(table)) {
               final rows = dataMap[table] as List<dynamic>;
               for (final row in rows) {
                 await txn.insert(table, Map<String, dynamic>.from(row as Map));
               }
            }
          }
        } else {
          // Merge Data - We need to insert and remap IDs for relational data
          
          final Map<int, int> exerciseIdMap = {};
          final Map<int, int> routineIdMap = {};
          final Map<int, int> workoutIdMap = {};

          Future<void> insertAndMap(String tableName, Map<String, dynamic> row, Map<int, int> idMap) async {
            final oldId = row['id'] as int;
            row.remove('id'); // Remove old ID to let DB autoincrement
            final newId = await txn.insert(tableName, row);
            idMap[oldId] = newId;
          }

          if (dataMap.containsKey('exercises')) {
             for (final r in (dataMap['exercises'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               if (row['isCustom'] == 1) {
                  await insertAndMap('exercises', row, exerciseIdMap);
               } else {
                 final oldId = row['id'] as int;
                 exerciseIdMap[oldId] = oldId;
               }
             }
          }

          if (dataMap.containsKey('routines')) {
             for (final r in (dataMap['routines'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               await insertAndMap('routines', row, routineIdMap);
             }
          }

          if (dataMap.containsKey('routine_exercises')) {
             for (final r in (dataMap['routine_exercises'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               final oldRoutineId = row['routineId'] as int?;
               final oldExerciseId = row['exerciseId'] as int?;
               
               if (oldRoutineId != null && routineIdMap.containsKey(oldRoutineId)) {
                   row['routineId'] = routineIdMap[oldRoutineId];
               }
               if (oldExerciseId != null && exerciseIdMap.containsKey(oldExerciseId)) {
                   row['exerciseId'] = exerciseIdMap[oldExerciseId];
               }
               row.remove('id');
               await txn.insert('routine_exercises', row);
             }
          }

          if (dataMap.containsKey('workouts')) {
             for (final r in (dataMap['workouts'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               final oldRoutineId = row['routineId'] as int?;
               
               if (oldRoutineId != null && routineIdMap.containsKey(oldRoutineId)) {
                   row['routineId'] = routineIdMap[oldRoutineId];
               }
               await insertAndMap('workouts', row, workoutIdMap);
             }
          }

          if (dataMap.containsKey('workout_exercises')) {
             for (final r in (dataMap['workout_exercises'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               final oldWorkoutId = row['workoutId'] as int?;
               final oldExerciseId = row['exerciseId'] as int?;

               if (oldWorkoutId != null && workoutIdMap.containsKey(oldWorkoutId)) {
                   row['workoutId'] = workoutIdMap[oldWorkoutId];
               }
               if (oldExerciseId != null && exerciseIdMap.containsKey(oldExerciseId)) {
                   row['exerciseId'] = exerciseIdMap[oldExerciseId];
               }
               row.remove('id');
               await txn.insert('workout_exercises', row);
             }
          }

          if (dataMap.containsKey('workout_sets')) {
             for (final r in (dataMap['workout_sets'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               final oldWorkoutId = row['workoutId'] as int?;
               final oldExerciseId = row['exerciseId'] as int?;

               if (oldWorkoutId != null && workoutIdMap.containsKey(oldWorkoutId)) {
                   row['workoutId'] = workoutIdMap[oldWorkoutId];
               }
               if (oldExerciseId != null && exerciseIdMap.containsKey(oldExerciseId)) {
                   row['exerciseId'] = exerciseIdMap[oldExerciseId];
               }
               row.remove('id');
               await txn.insert('workout_sets', row);
             }
          }

          if (dataMap.containsKey('bia_reports')) {
             for (final r in (dataMap['bia_reports'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               row.remove('id');
               await txn.insert('bia_reports', row);
             }
          }

          if (dataMap.containsKey('weight_logs')) {
             for (final r in (dataMap['weight_logs'] as List)) {
               final row = Map<String, dynamic>.from(r as Map);
               row.remove('id');
               await txn.insert('weight_logs', row);
             }
          }
        }
      });

      return true;
    } catch (e) {
      print('Import Error: \$e');
      return false;
    }
  }
}
