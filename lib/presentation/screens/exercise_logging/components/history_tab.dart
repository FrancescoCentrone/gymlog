import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gym_log/data/models/workout_set.dart';
import 'package:gym_log/presentation/state/workout_provider.dart';

class HistoryTab extends ConsumerWidget {
  final int exerciseId;

  const HistoryTab({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<DateTime, List<WorkoutSet>>>(
      future: ref.read(workoutRepositoryProvider).getExerciseHistory(exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final history = snapshot.data ?? {};
        
        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No history yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Start logging sets to see your progress!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Sort dates descending (already done in query, but ensure)
        final sortedDates = history.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final sets = history[date]!;
            
            // Calculate total volume for this workout
            final totalVolume = sets.fold<double>(0, (sum, set) => sum + (set.weight * set.reps));

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${sets.length} sets • ${totalVolume.toInt()}kg total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Sets List
                    ...sets.map((set) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Set ${set.setNumber}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${set.weight.toInt()}kg × ${set.reps} reps${set.partialReps > 0 ? ' (+${set.partialReps} partials)' : ''}${set.rpe != null ? ' @ ${set.rpe!.toInt()} RPE' : ''}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Spacer(),
                            Text(
                              '${(set.weight * set.reps).toInt()}kg',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
