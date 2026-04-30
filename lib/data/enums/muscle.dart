import 'package:gym_log/data/enums/muscle_group.dart';

enum Muscle {
  // Chest
  upperChest,
  medialChest,
  lowerChest,
  
  // Back
  higherBack,
  lats,
  
  // Legs
  quadriceps,
  hamstrings,
  glutes,
  adductors,
  calves,
  
  // Shoulders
  anteriorDeltoid,
  lateralDeltoid,
  posteriorDeltoid,
  rotatorCuff,
  
  // Arms
  biceps,
  triceps,
  brachialis,
  brachioradialis,
  forearmFlexorsExtensors,
  
  // Core
  abdominis,
  obliques;

  String get displayName {
    switch (this) {
      // Chest
      case Muscle.upperChest:
        return 'Upper Chest';
      case Muscle.medialChest:
        return 'Medial Chest';
      case Muscle.lowerChest:
        return 'Lower Chest';
      
      // Back
      case Muscle.higherBack:
        return 'Higher Back';
      case Muscle.lats:
        return 'Lats';
      
      // Legs
      case Muscle.quadriceps:
        return 'Quadriceps';
      case Muscle.hamstrings:
        return 'Hamstrings';
      case Muscle.glutes:
        return 'Glutes';
      case Muscle.adductors:
        return 'Adductors';
      case Muscle.calves:
        return 'Calves';
      
      // Shoulders
      case Muscle.anteriorDeltoid:
        return 'Anterior Deltoid';
      case Muscle.lateralDeltoid:
        return 'Lateral Deltoid';
      case Muscle.posteriorDeltoid:
        return 'Posterior Deltoid';
      case Muscle.rotatorCuff:
        return 'Rotator Cuff';
      
      // Arms
      case Muscle.biceps:
        return 'Biceps';
      case Muscle.triceps:
        return 'Triceps';
      case Muscle.brachialis:
        return 'Brachialis';
      case Muscle.brachioradialis:
        return 'Brachioradialis';
      case Muscle.forearmFlexorsExtensors:
        return 'Forearm Flexors/Extensors';
      
      // Core
      case Muscle.abdominis:
        return 'Abdominis';
      case Muscle.obliques:
        return 'Obliques';
    }
  }

  static Muscle fromString(String? value) {
    if (value == null) return Muscle.upperChest;
    try {
      return Muscle.values.firstWhere(
        (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return Muscle.upperChest;
    }
  }

  /// Get the muscle group this muscle belongs to
  MuscleGroup get muscleGroup {
    switch (this) {
      case Muscle.upperChest:
      case Muscle.medialChest:
      case Muscle.lowerChest:
        return MuscleGroup.chest;
      
      case Muscle.higherBack:
      case Muscle.lats:
        return MuscleGroup.back;
      
      case Muscle.quadriceps:
      case Muscle.hamstrings:
      case Muscle.glutes:
      case Muscle.adductors:
      case Muscle.calves:
        return MuscleGroup.legs;
      
      case Muscle.anteriorDeltoid:
      case Muscle.lateralDeltoid:
      case Muscle.posteriorDeltoid:
      case Muscle.rotatorCuff:
        return MuscleGroup.shoulders;
      
      case Muscle.biceps:
      case Muscle.triceps:
      case Muscle.brachialis:
      case Muscle.brachioradialis:
      case Muscle.forearmFlexorsExtensors:
        return MuscleGroup.arms;
      
      case Muscle.abdominis:
      case Muscle.obliques:
        return MuscleGroup.core;
    }
  }

  /// Get all muscles for a given muscle group
  static List<Muscle> getMusclesByGroup(MuscleGroup group) {
    return Muscle.values.where((muscle) => muscle.muscleGroup == group).toList();
  }
}
