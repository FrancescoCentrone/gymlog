import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/enums/muscle_group.dart';
import 'package:gym_log/presentation/state/exercise_provider.dart';

import 'package:gym_log/presentation/screens/exercise_editor_screen.dart';
import 'package:gym_log/presentation/screens/exercise_detail_screen.dart';

class ExerciseCatalogScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const ExerciseCatalogScreen({super.key, this.isSelectionMode = true});

  @override
  ConsumerState<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends ConsumerState<ExerciseCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MuscleGroup? _selectedMuscleGroup;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Select Exercise' : 'Exercise Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExerciseEditorScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Exercises',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedMuscleGroup == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedMuscleGroup = null;
                          });
                        }
                      },
                    ),
                  ),
                  ...MuscleGroup.values.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(group.displayName),
                        selected: _selectedMuscleGroup == group,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMuscleGroup = selected ? group : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filteredExercises = exercises.where((exercise) {
                  final matchesSearch = exercise.name.toLowerCase().contains(_searchQuery) ||
                         exercise.primaryMuscleGroup.displayName.toLowerCase().contains(_searchQuery);
                  final matchesGroup = _selectedMuscleGroup == null || 
                      exercise.primaryMuscleGroup == _selectedMuscleGroup || 
                      (exercise.secondaryMuscle != null && exercise.secondaryMuscle!.muscleGroup == _selectedMuscleGroup);
                  
                  return matchesSearch && matchesGroup;
                }).toList();

                if (filteredExercises.isEmpty) {
                  return const Center(child: Text('No exercises found.'));
                }

                return ListView.builder(
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(exercise.primaryMuscleGroup.displayName),
                      trailing: widget.isSelectionMode ? null : const Icon(Icons.chevron_right),
                      onTap: () {
                        if (widget.isSelectionMode) {
                          Navigator.pop(context, exercise);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailScreen(exercise: exercise),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
