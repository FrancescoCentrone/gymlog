import 'dart:convert';
import 'package:gym_log/data/database/database_helper.dart';
import 'package:gym_log/data/models/bia_report.dart';

class BiaReportRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<List<BiaReport>> getAllBiaReports() async {
    final db = await _databaseHelper.database;
    final result = await db.query('bia_reports', orderBy: 'recordDate DESC');
    return result.map((json) => _fromDbMap(json)).toList();
  }

  Future<BiaReport?> getBiaReportById(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'bia_reports',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return _fromDbMap(result.first);
    }
    return null;
  }

  Future<int> createBiaReport(BiaReport report) async {
    final db = await _databaseHelper.database;
    return await db.insert('bia_reports', _toDbMap(report));
  }

  Future<int> updateBiaReport(BiaReport report) async {
    if (report.id == null) {
      throw ArgumentError('Cannot update BIA report without an id');
    }

    final db = await _databaseHelper.database;
    return await db.update(
      'bia_reports',
      _toDbMap(report),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  Future<int> deleteBiaReport(int id) async {
    final db = await _databaseHelper.database;
    return await db.delete(
      'bia_reports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods to convert between database format and model
  Map<String, dynamic> _toDbMap(BiaReport report) {
    return {
      'id': report.id,
      'recordDate': report.recordDate.toIso8601String(),
      'weight': report.weight,
      'composition': jsonEncode(report.composition.toMap()),
      'obesity': jsonEncode(report.obesity.toMap()),
      'leanAnalysis': jsonEncode(report.leanAnalysis.map((x) => x.toMap()).toList()),
      'fatAnalysis': jsonEncode(report.fatAnalysis.map((x) => x.toMap()).toList()),
      'fitnessScore': report.fitnessScore,
    };
  }

  BiaReport _fromDbMap(Map<String, dynamic> map) {
    return BiaReport(
      id: map['id'] as int?,
      recordDate: DateTime.parse(map['recordDate'] as String),
      // SQLite may return integers for REAL columns when the value has no decimal part.
      weight: (map['weight'] as num).toDouble(),
      composition: CompositionAnalysis.fromMap(
        jsonDecode(map['composition'] as String) as Map<String, dynamic>,
      ),
      obesity: ObesityAnalysis.fromMap(
        jsonDecode(map['obesity'] as String) as Map<String, dynamic>,
      ),
      leanAnalysis: (jsonDecode(map['leanAnalysis'] as String) as List<dynamic>)
          .map((x) => SegmentalData.fromMap(x as Map<String, dynamic>))
          .toList(),
      fatAnalysis: (jsonDecode(map['fatAnalysis'] as String) as List<dynamic>)
          .map((x) => SegmentalData.fromMap(x as Map<String, dynamic>))
          .toList(),
      fitnessScore: (map['fitnessScore'] as num).toInt(),
    );
  }
}
