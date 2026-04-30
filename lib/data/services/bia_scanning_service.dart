import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_local_ai/flutter_local_ai.dart';
// import 'package:mediapipe_genai/mediapipe_genai.dart'; // Commented out until used or removed
import 'package:gym_log/data/models/bia_report.dart';
import 'package:gym_log/data/constants/ai_prompts.dart';

enum AiState { available, missingApp, notSupported }

class BiaScanningService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _localAi = FlutterLocalAi();

  Future<AiState> checkAiCapability() async {
    try {
      // Add a small timeout for capability check
      final isAvailable = await _localAi.isAvailable().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      print('AI Capability check: isAvailable=$isAvailable');
      if (isAvailable) return AiState.available;
      
      return AiState.notSupported;
    } catch (e) {
      print('AI Capability check error: $e');
      return AiState.notSupported;
    }
  }

  Future<BiaReport?> scanReport(String imagePath) async {
    print('DEBUG: scanReport started for path: $imagePath');
    try {
      // 1. OCR Step
      final inputImage = InputImage.fromFilePath(imagePath);
      print('DEBUG: inputImage created. Processing with TextRecognizer...');
      
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Structural Reconstruction: Group text by horizontal rows
      final String rawText = _reconstructRows(recognizedText);
      
      print('DEBUG: OCR processing finished. Text length: ${rawText.length}');
      print('DEBUG: Extracted Text:\n$rawText');
      print('DEBUG: OCR Blocks: ${recognizedText.blocks.length}');

      // 2. Reasoning Step
      print('DEBUG: Checking AI capability...');
      final aiState = await checkAiCapability();
      print('DEBUG: AI State: $aiState');
      
      String? jsonResponse;

      if (aiState == AiState.available) {
        try {
          print('DEBUG: Attempting Gemini Nano inference with prompt...');
          final prompt = AiPrompts.getBiaParsingPrompt(rawText);
          
          jsonResponse = await _localAi.generateTextSimple(
            prompt: prompt,
            maxTokens: 1000,
          );
          print('DEBUG: Gemini Nano response received. Length: ${jsonResponse.length}');
        } catch (e) {
          print('DEBUG: Gemini Nano error: $e. Using MediaPipe fallback.');
          jsonResponse = await _processWithMediaPipe(rawText);
        }
      } else {
        print('DEBUG: Falling back to MediaPipe/Heuristic...');
        jsonResponse = await _processWithMediaPipe(rawText);
      }

      if (jsonResponse == null || jsonResponse.isEmpty) {
        print('DEBUG: No AI response. Using heuristic fallback.');
        final report = _heuristicExtraction(rawText);
        print('DEBUG: Heuristic extraction produced weight: ${report.weight}');
        return report;
      }

      try {
        print('DEBUG: Parsing AI JSON response...');
        final cleanJson = jsonResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        
        if (data['recordDate'] == 'YYYY-MM-DD' || data['recordDate'] == null) {
          data['recordDate'] = DateTime.now().toIso8601String();
        }

        final report = BiaReport.fromMap(data);
        print('DEBUG: BIA Report parsed successfully.');
        return report;
      } catch (e) {
        print('DEBUG: AI JSON parse error: $e. Falling back to heuristic.');
        return _heuristicExtraction(rawText);
      }
    } catch (e, stack) {
      print('DEBUG: CRITICAL error in scanReport: $e');
      print(stack);
      rethrow;
    }
  }

  /// Groups OCR lines into horizontal rows based on their Y-coordinates.
  /// This is essential for tabular layouts like BIA reports.
  String _reconstructRows(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return recognizedText.text;

    final List<TextElement> allElements = [];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        allElements.addAll(line.elements);
      }
    }

    // Sort by Y coordinate first, then X coordinate
    allElements.sort((a, b) {
      final yComp = a.boundingBox.top.compareTo(b.boundingBox.top);
      if (yComp != 0) return yComp;
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });

    final List<List<TextElement>> rows = [];
    double currentY = -1;
    const double verticalTolerance = 15.0; // Pixels to consider on the same line

    for (final element in allElements) {
      if (currentY == -1 || (element.boundingBox.top - currentY).abs() > verticalTolerance) {
        rows.add([element]);
        currentY = element.boundingBox.top;
      } else {
        rows.last.add(element);
      }
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      // Sort elements within row by X coordinate
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      buffer.writeln(row.map((e) => e.text).join(' '));
    }

    return buffer.toString();
  }

  /// Extracts basic metrics using regex as a reliable fallback
  BiaReport _heuristicExtraction(String rawText) {
    final now = DateTime.now();
    
    // Improved double parser helper that handles dots, commas and units
    double? findValue(List<String> keywords) {
      for (final keyword in keywords) {
        // Look for keyword, optional non-digit chars, then a number, then optional units
        final regex = RegExp('$keyword[:\\s]*([\\d]+[.,][\\d]+|[\\d]+)', caseSensitive: false);
        final match = regex.firstMatch(rawText);
        if (match != null) {
          final val = match.group(1)!.replaceAll(',', '.');
          return double.tryParse(val);
        }
      }
      return null;
    }

    // Weight is critical
    double weight = findValue(['Weight', 'Wt', 'Peso']) ?? 0.0;
    
    return BiaReport(
      recordDate: now,
      weight: weight,
      composition: CompositionAnalysis(
        muscle: findValue(['Muscle', 'SMM', 'Skeletal Muscle', 'Massa Muscular']) ?? 0.0,
        fat: findValue(['Body Fat Mass', 'Fat Mass', 'BFM', 'Massa Gorda']) ?? 0.0,
        tbw: findValue(['TBW', 'Total Body Water', 'Água Corporal']) ?? 0.0,
        ffm: findValue(['FFM', 'Fat-Free Mass', 'MLG']) ?? 0.0,
      ),
      obesity: ObesityAnalysis(
        bmi: findValue(['BMI', 'IMC', 'Body Mass Index']) ?? 0.0,
        pbf: findValue(['PBF', 'Percent Body Fat', 'Percentual de Gordura', 'Fat %', '%Gordura']) ?? 0.0,
        visceralFatLevel: (findValue(['Visceral Fat', 'Visc. Fat', 'Gordura Visceral', 'Level']) ?? 0).toInt(),
        bmr: findValue(['BMR', 'TMB', 'Basal Metabolic Rate']) ?? 0.0,
      ),
      leanAnalysis: [],
      fatAnalysis: [],
      fitnessScore: (findValue(['Fitness Score', 'InBody Score', 'Score', 'Pontos', 'Points']) ?? 0).toInt(),
    );
  }

  Future<String?> _processWithMediaPipe(String rawText) async {
    // MediaPipe logic remains a placeholder for now as it's highly dependent on architecture
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
