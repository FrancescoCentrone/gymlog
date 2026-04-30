import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gym_log/data/models/workout_session.dart';
import 'package:gym_log/presentation/state/routine_provider.dart';
import 'package:gym_log/presentation/state/workout_provider.dart';
import 'package:gym_log/presentation/screens/routines_list_screen.dart';
import 'package:gym_log/presentation/screens/exercise_catalog_screen.dart';
import 'package:gym_log/presentation/widgets/workout/week_calendar.dart';
import 'package:gym_log/presentation/widgets/workout/workout_exercise_list.dart';


class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedRoutineId;
  
  @override
  void initState() {
    super.initState();
    // Load workout for today initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkoutForDate(_selectedDate);
    });
  }

  Future<void> _loadWorkoutForDate(DateTime date) async {
    final repository = ref.read(workoutRepositoryProvider);
    final session = await repository.getWorkoutSessionByDate(date);

    if (session != null) {
      setState(() {
        _selectedRoutineId = session.routineId;
      });
      ref.read(currentWorkoutIdProvider.notifier).state = session.id;
    } else {
      setState(() {
        _selectedRoutineId = null;
      });
      ref.read(currentWorkoutIdProvider.notifier).state = null;
    }
    // Refresh sets for the new session (or null session)
    ref.refresh(workoutSetsProvider);
    ref.refresh(workoutExercisesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
            ),
            Text(
              DateFormat('EEEE, MMM d').format(_selectedDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Weekly Calendar Strip
          WeekCalendar(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
              _loadWorkoutForDate(date);
            },
          ),
          const SizedBox(height: 24),

          // Routine Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Routine', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoutinesListScreen()),
                        );
                      },
                      child: const Text('Routines'),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: routinesAsync.when(
                    data: (routines) {
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<int?>( 
                          value: _selectedRoutineId,
                          hint: const Text('Select a routine'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null, 
                              child: Text('No Routine / Ad-hoc'),
                            ),
                            ...routines.map((routine) {
                              return DropdownMenuItem<int?>(
                                value: routine.id,
                                child: Text(routine.name),
                              );
                            }),
                          ],
                          onChanged: (int? newValue) async {
                            setState(() {
                              _selectedRoutineId = newValue;
                            });

                            final repository = ref.read(workoutRepositoryProvider);

                            // Always reuse the existing session for this day if one exists,
                            // so that previously logged exercises are never lost.
                            final existingSession = await repository.getWorkoutSessionByDate(_selectedDate);

                            int workoutId;
                            if (existingSession != null) {
                              workoutId = existingSession.id!;
                              // Update the routine association without touching exercises/sets
                              await repository.updateSessionRoutineId(workoutId, newValue);
                              // Add routine exercises on top (skips duplicates)
                              if (newValue != null) {
                                await repository.addRoutineExercisesToWorkout(workoutId, newValue);
                              }
                            } else {
                              // No session yet for today — create one
                              final newSession = WorkoutSession(
                                routineId: newValue,
                                startTime: _selectedDate,
                              );
                              workoutId = await repository.createWorkoutSession(newSession);
                            }

                            ref.read(currentWorkoutIdProvider.notifier).state = workoutId;
                            ref.refresh(workoutSetsProvider);
                            ref.refresh(workoutExercisesProvider);
                          },
                        ),
                      );
                    },
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (_, _) => const Text('Error loading routines'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Exercises List
          Expanded(
            child: WorkoutExerciseList(selectedDate: _selectedDate),
          ),

          // Add Exercise sticky button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseCatalogScreen(key: UniqueKey()),
                    ),
                  );
                  if (result != null && mounted) {
                    final exercise = result;
                    final repository = ref.read(workoutRepositoryProvider);
                    var workoutId = ref.read(currentWorkoutIdProvider);
                    if (workoutId == null) {
                      final newSession = WorkoutSession(
                        routineId: _selectedRoutineId,
                        startTime: _selectedDate,
                      );
                      workoutId = await repository.createWorkoutSession(newSession);
                      ref.read(currentWorkoutIdProvider.notifier).state = workoutId;
                    }
                    await repository.addExerciseToWorkout(workoutId, exercise.id);
                    ref.refresh(workoutExercisesProvider);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Exercise'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
