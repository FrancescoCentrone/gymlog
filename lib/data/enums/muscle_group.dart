enum MuscleGroup {
  chest,
  back,
  legs,
  arms,
  shoulders,
  core,
  cardio;

  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.arms:
        return 'Arms';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.cardio:
        return 'Cardio';
    }
  }

  static MuscleGroup fromString(String? value) {
    if (value == null) return MuscleGroup.chest;
    try {
      return MuscleGroup.values.firstWhere(
        (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return MuscleGroup.chest;
    }
  }
}
