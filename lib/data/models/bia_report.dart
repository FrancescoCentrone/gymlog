enum Evaluation { normal, under, over }

class CompositionAnalysis {
  final double muscle;
  final double fat;
  final double tbw;
  final double ffm;

  CompositionAnalysis({
    required this.muscle,
    required this.fat,
    required this.tbw,
    required this.ffm,
  });

  Map<String, dynamic> toMap() {
    return {
      'muscle': muscle,
      'fat': fat,
      'tbw': tbw,
      'ffm': ffm,
    };
  }

  factory CompositionAnalysis.fromMap(Map<String, dynamic> map) {
    return CompositionAnalysis(
      muscle: (map['muscle'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      tbw: (map['tbw'] as num).toDouble(),
      ffm: (map['ffm'] as num).toDouble(),
    );
  }
}

class ObesityAnalysis {
  final double bmi;
  final double pbf;
  final int visceralFatLevel;
  final double bmr;

  ObesityAnalysis({
    required this.bmi,
    required this.pbf,
    required this.visceralFatLevel,
    required this.bmr,
  });

  Map<String, dynamic> toMap() {
    return {
      'bmi': bmi,
      'pbf': pbf,
      'visceralFatLevel': visceralFatLevel,
      'bmr': bmr,
    };
  }

  factory ObesityAnalysis.fromMap(Map<String, dynamic> map) {
    return ObesityAnalysis(
      bmi: (map['bmi'] as num).toDouble(),
      pbf: (map['pbf'] as num).toDouble(),
      visceralFatLevel: map['visceralFatLevel'] as int,
      bmr: (map['bmr'] as num).toDouble(),
    );
  }
}

class SegmentalData {
  final String partName; // e.g., "Right Arm"
  final double value;
  final Evaluation evaluation;

  SegmentalData({
    required this.partName,
    required this.value,
    required this.evaluation,
  });

  Map<String, dynamic> toMap() {
    return {
      'partName': partName,
      'value': value,
      'evaluation': evaluation.index,
    };
  }

  factory SegmentalData.fromMap(Map<String, dynamic> map) {
    return SegmentalData(
      partName: map['partName'] as String,
      value: (map['value'] as num).toDouble(),
      evaluation: Evaluation.values[map['evaluation'] as int],
    );
  }
}

class BiaReport {
  final int? id;
  final DateTime recordDate;
  final double weight;
  final CompositionAnalysis composition;
  final ObesityAnalysis obesity;
  final List<SegmentalData> leanAnalysis;
  final List<SegmentalData> fatAnalysis;
  final int fitnessScore;

  BiaReport({
    this.id,
    required this.recordDate,
    required this.weight,
    required this.composition,
    required this.obesity,
    required this.leanAnalysis,
    required this.fatAnalysis,
    required this.fitnessScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recordDate': recordDate.toIso8601String(),
      'weight': weight,
      'composition': composition.toMap(),
      'obesity': obesity.toMap(),
      'leanAnalysis': leanAnalysis.map((x) => x.toMap()).toList(),
      'fatAnalysis': fatAnalysis.map((x) => x.toMap()).toList(),
      'fitnessScore': fitnessScore,
    };
  }

  factory BiaReport.fromMap(Map<String, dynamic> map) {
    return BiaReport(
      id: map['id'] as int?,
      recordDate: DateTime.parse(map['recordDate'] as String),
      weight: (map['weight'] as num).toDouble(),
      composition: CompositionAnalysis.fromMap(map['composition'] as Map<String, dynamic>),
      obesity: ObesityAnalysis.fromMap(map['obesity'] as Map<String, dynamic>),
      leanAnalysis: (map['leanAnalysis'] as List<dynamic>)
          .map((x) => SegmentalData.fromMap(x as Map<String, dynamic>))
          .toList(),
      fatAnalysis: (map['fatAnalysis'] as List<dynamic>)
          .map((x) => SegmentalData.fromMap(x as Map<String, dynamic>))
          .toList(),
      fitnessScore: map['fitnessScore'] as int,
    );
  }
}
