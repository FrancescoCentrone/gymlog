class AiPrompts {
  static const String biaReportSchema = '''
{
  "recordDate": "YYYY-MM-DD",
  "weight": 0.0,
  "composition": {
    "muscle": 0.0,
    "fat": 0.0,
    "tbw": 0.0,
    "ffm": 0.0
  },
  "obesity": {
    "bmi": 0.0,
    "pbf": 0.0,
    "visceralFatLevel": 0,
    "bmr": 0.0
  },
  "leanAnalysis": [
    {
      "partName": "string",
      "value": 0.0,
      "evaluation": 0
    }
  ],
  "fatAnalysis": [
    {
      "partName": "string",
      "value": 0.0,
      "evaluation": 0
    }
  ],
  "fitnessScore": 0
}
''';

  static String getBiaParsingPrompt(String rawText) {
    return '''
You are a medical data parser. Convert the following OCR text from a BIA report into a JSON object matching this schema: $biaReportSchema

OCR Text:
$rawText

Guidelines:
1. Extract weight, muscle mass (SMM), body fat mass, TBW, FFM.
2. Extract BMI, PBF, Visceral Fat Level, BMR.
3. Extract fitness score (InBody Score).
4. For segmental analysis, map Right Arm, Left Arm, Trunk, Right Leg, Left Leg.
5. Evaluations: Normal=0, Under=1, Over=2.
6. Return ONLY valid JSON.
''';
  }
}
