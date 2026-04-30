import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/exercise_model.dart';
import 'package:gym_log/data/models/routine_model.dart';
import 'package:gym_log/presentation/screens/exercise_catalog_screen.dart';
import 'package:gym_log/presentation/state/routine_provider.dart';
import 'package:gym_log/presentation/screens/set_configuration_screen.dart';
import 'package:gym_log/data/models/routine_exercise_set.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final Routine? routine;
  const RoutineEditorScreen({super.key, this.routine});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<RoutineExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.name ?? '');
    _exercises = widget.routine?.exercises.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise() async {
    final Exercise? selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseCatalogScreen()),
    );

    if (selectedExercise != null) {
      if (selectedExercise.id == null) return; 

      if (mounted) {
        // Create initial sets
        final initialSets = List.generate(3, (index) => RoutineExerciseSet(
          setIndex: index,
          reps: 10,
        ));

        // Navigate to configuration
        final SetConfigurationResult? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetConfigurationScreen(
              exerciseName: selectedExercise.name,
              initialSets: initialSets,
              initialRestSeconds: 60,
            ),
          ),
        );

        if (result != null && mounted) {
           final configuredSets = result.sets;
          
          // Calculate aggregate minReps and maxReps across all sets
          int overallMin = configuredSets.first.isRange 
              ? configuredSets.first.minReps! 
              : configuredSets.first.reps;
          int overallMax = configuredSets.first.isRange 
              ? configuredSets.first.maxReps! 
              : configuredSets.first.reps;
          
          for (final set in configuredSets) {
            final setMin = set.isRange ? set.minReps! : set.reps;
            final setMax = set.isRange ? set.maxReps! : set.reps;
            if (setMin < overallMin) overallMin = setMin;
            if (setMax > overallMax) overallMax = setMax;
          }
          
          setState(() {
            _exercises.add(RoutineExercise(
              exerciseId: selectedExercise.id!,
              exercise: selectedExercise,
              sets: configuredSets.length,
              minReps: overallMin,
              maxReps: overallMax,
              restSeconds: result.restSeconds, 
              orderIndex: _exercises.length,
            ));
          });
        }
      }
    }
  }

  void _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise.')),
      );
      return;
    }

    final orderedExercises = _exercises.asMap().entries.map((entry) {
      return entry.value.copyWith(orderIndex: entry.key);
    }).toList();

    final routine = Routine(
      id: widget.routine?.id,
      name: _nameController.text,
      exercises: orderedExercises,
    );

    if (widget.routine == null) {
      await ref.read(routinesProvider.notifier).addRoutine(routine);
    } else {
      await ref.read(routinesProvider.notifier).updateRoutine(routine);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _editExerciseDetails(int index) async {
    final exercise = _exercises[index];
    
    // Reconstruct sets from aggregate data
    // If minReps != maxReps, assume it was a range for all sets
    final isRange = exercise.minReps != exercise.maxReps;
    final initialSets = List.generate(exercise.sets, (i) => RoutineExerciseSet(
      setIndex: i,
      reps: isRange ? ((exercise.minReps + exercise.maxReps) / 2).round() : exercise.minReps,
      minReps: isRange ? exercise.minReps : null,
      maxReps: isRange ? exercise.maxReps : null,
      isRange: isRange,
    ));

    final SetConfigurationResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetConfigurationScreen(
          exerciseName: exercise.exercise?.name ?? 'Exercise',
          initialSets: initialSets,
          initialRestSeconds: exercise.restSeconds,
        ),
      ),
    );

    if (result != null && mounted) {
        final configuredSets = result.sets;
        
        // Calculate aggregate minReps and maxReps across all sets
        int overallMin = configuredSets.first.isRange 
            ? configuredSets.first.minReps! 
            : configuredSets.first.reps;
        int overallMax = configuredSets.first.isRange 
            ? configuredSets.first.maxReps! 
            : configuredSets.first.reps;
        
        for (final set in configuredSets) {
          final setMin = set.isRange ? set.minReps! : set.reps;
          final setMax = set.isRange ? set.maxReps! : set.reps;
          if (setMin < overallMin) overallMin = setMin;
          if (setMax > overallMax) overallMax = setMax;
        }
        
        setState(() {
        _exercises[index] = exercise.copyWith(
            sets: configuredSets.length,
            minReps: overallMin,
            maxReps: overallMax,
            restSeconds: result.restSeconds,
        );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routine == null ? 'Create Routine' : 'Edit Routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRoutine,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Routine Name',
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
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final routineExercise = _exercises[index];
                  final repsDisplay = routineExercise.minReps == routineExercise.maxReps
                      ? '${routineExercise.minReps}'
                      : '${routineExercise.minReps}-${routineExercise.maxReps}';
                  return ListTile(
                    key: ValueKey(routineExercise),
                    title: Text(routineExercise.exercise?.name ?? 'Exercise ${routineExercise.exerciseId}'),
                    subtitle: Text('${routineExercise.sets} sets x $repsDisplay reps'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editExerciseDetails(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _exercises.removeAt(index);
                            });
                          },
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
    );
  }
}
