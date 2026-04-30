import 'package:gym_log/data/enums/muscle_group.dart';
import 'package:gym_log/data/enums/muscle.dart';

class Exercise {
  final int? id;
  final String name;
  final String description;
  final MuscleGroup primaryMuscleGroup;
  final Muscle primaryMuscle;
  final Muscle? secondaryMuscle;
  final bool isCustom;
  final String? notes;

  Exercise({
    this.id,
    required this.name,
    required this.description,
    required this.primaryMuscleGroup,
    required this.primaryMuscle,
    this.secondaryMuscle,
    required this.isCustom,
    this.notes,
  });

  Exercise copyWith({
    int? id,
    String? name,
    String? description,
    MuscleGroup? primaryMuscleGroup,
    Muscle? primaryMuscle,
    Muscle? secondaryMuscle,
    bool? isCustom,
    String? notes,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscle: secondaryMuscle ?? this.secondaryMuscle,
      isCustom: isCustom ?? this.isCustom,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primaryMuscleGroup': primaryMuscleGroup.displayName,
      'primaryMuscle': primaryMuscle.displayName,
      'secondaryMuscle': secondaryMuscle?.displayName,
      'isCustom': isCustom ? 1 : 0,
      'notes': notes,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      primaryMuscleGroup: MuscleGroup.fromString(map['primaryMuscleGroup'] as String),
      primaryMuscle: Muscle.fromString(map['primaryMuscle'] as String),
      secondaryMuscle: map['secondaryMuscle'] != null 
          ? Muscle.fromString(map['secondaryMuscle'] as String) 
          : null,
      isCustom: (map['isCustom'] as int) == 1,
      notes: map['notes'] as String?,
    );
  }
}
