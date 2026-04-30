import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/exercise_model.dart';
import 'package:gym_log/data/enums/muscle_group.dart';
import 'package:gym_log/data/enums/muscle.dart';
import 'package:gym_log/presentation/state/exercise_provider.dart';

class ExerciseEditorScreen extends ConsumerStatefulWidget {
  final Exercise? initialExercise;

  const ExerciseEditorScreen({super.key, this.initialExercise});

  @override
  ConsumerState<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends ConsumerState<ExerciseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  MuscleGroup _primaryMuscleGroup = MuscleGroup.chest;
  Muscle _primaryMuscle = Muscle.upperChest;
  Muscle? _secondaryMuscle;
  bool _isCustom = true;

  @override
  void initState() {
    super.initState();
    final ex = widget.initialExercise;
    if (ex != null) {
      _nameController.text = ex.name;
      _descriptionController.text = ex.description;
      _primaryMuscleGroup = ex.primaryMuscleGroup;
      _primaryMuscle = ex.primaryMuscle;
      _secondaryMuscle = ex.secondaryMuscle;
      _isCustom = ex.isCustom;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    final exercise = Exercise(
      id: widget.initialExercise?.id,
      name: _nameController.text,
      description: _descriptionController.text,
      primaryMuscleGroup: _primaryMuscleGroup,
      primaryMuscle: _primaryMuscle,
      secondaryMuscle: _secondaryMuscle,
      isCustom: _isCustom,
      notes: widget.initialExercise?.notes,
    );

    if (widget.initialExercise != null) {
      await ref.read(exercisesProvider.notifier).updateExercise(exercise);
    } else {
      await ref.read(exercisesProvider.notifier).addExercise(exercise);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialExercise != null ? 'Edit Exercise' : 'New Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveExercise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MuscleGroup>(
                value: _primaryMuscleGroup,
                decoration: const InputDecoration(
                  labelText: 'Primary Muscle Group',
                  border: OutlineInputBorder(),
                ),
                items: MuscleGroup.values.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _primaryMuscleGroup = value!;
                    // Reset primary muscle to first muscle of the new group
                    final musclesInGroup = Muscle.getMusclesByGroup(_primaryMuscleGroup);
                    if (musclesInGroup.isNotEmpty) {
                      _primaryMuscle = musclesInGroup.first;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Muscle>(
                value: _primaryMuscle,
                decoration: const InputDecoration(
                  labelText: 'Primary Muscle',
                  border: OutlineInputBorder(),
                ),
                items: Muscle.getMusclesByGroup(_primaryMuscleGroup).map((muscle) {
                  return DropdownMenuItem(
                    value: muscle,
                    child: Text(muscle.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _primaryMuscle = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a primary muscle';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Muscle>(
                value: _secondaryMuscle,
                decoration: const InputDecoration(
                  labelText: 'Secondary Muscle (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<Muscle>(value: null, child: Text('None')),
                  ...Muscle.values.map((muscle) {
                    return DropdownMenuItem(
                      value: muscle,
                      child: Text(muscle.displayName),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _secondaryMuscle = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
