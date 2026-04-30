import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gym_log/presentation/state/routine_provider.dart';
import 'package:gym_log/presentation/screens/routine_editor_screen.dart';

class RoutinesListScreen extends ConsumerWidget {
  const RoutinesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Routines'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoutineEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return const Center(
              child: Text('No routines found. Create one!'),
            );
          }
          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return ListTile(
                title: Text(routine.name),
                subtitle: Text('${routine.exercises.length} exercises'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Routine?'),
                          content: Text('Are you sure you want to delete "${routine.name}"?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                ref.read(routinesProvider.notifier).deleteRoutine(routine.id!);
                                Navigator.of(context).pop();
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutineEditorScreen(routine: routine),
                    ),
                  );
                },
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
