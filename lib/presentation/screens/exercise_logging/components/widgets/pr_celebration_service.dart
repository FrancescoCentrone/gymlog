import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PRCelebrationService {
  static void checkAndShowPR(
    BuildContext context,
    Map<String, dynamic> oldRecords,
    Map<String, dynamic> newRecords,
  ) {
    final List<String> prsBroken = [];

    // Check Max Weight
    final oldWeight = (oldRecords['maxWeight']?['weight'] as num?)?.toDouble() ?? 0.0;
    final newWeight = (newRecords['maxWeight']?['weight'] as num?)?.toDouble() ?? 0.0;
    if (newWeight > oldWeight && oldWeight > 0) {
      prsBroken.add('New Max Weight: ${newWeight.toInt()}kg! 🏆');
    }

    // Check Max Reps
    final oldReps = (oldRecords['maxReps']?['reps'] as int?) ?? 0;
    final newReps = (newRecords['maxReps']?['reps'] as int?) ?? 0;
    if (newReps > oldReps && oldReps > 0) {
      prsBroken.add('New Rep Record: $newReps reps! 🏆');
    }

    // Check Estimated 1RM
    final old1RM = (oldRecords['estimated1RM']?['value'] as num?)?.toDouble() ?? 0.0;
    final new1RM = (newRecords['estimated1RM']?['value'] as num?)?.toDouble() ?? 0.0;
    if (new1RM > old1RM && old1RM > 0) {
      prsBroken.add('New Estimated 1RM: ${new1RM.toInt()}kg! 🏆');
    }

    if (prsBroken.isNotEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: prsBroken
                .map((pr) => Text(pr, style: const TextStyle(fontWeight: FontWeight.bold)))
                .toList(),
          ),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
