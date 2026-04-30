import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gym_log/presentation/state/workout_provider.dart';

class RecordsTab extends ConsumerWidget {
  final int exerciseId;

  const RecordsTab({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(workoutRepositoryProvider).getExerciseRecords(exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final records = snapshot.data ?? {};
        
        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No records yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Start logging to set your first record!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Max Weight
              if (records['maxWeight'] != null)
                _buildRecordCard(
                  context,
                  icon: Icons.fitness_center,
                  iconColor: Colors.orange,
                  title: 'Heaviest Weight',
                  value: '${records['maxWeight']['weight'].toInt()}kg',
                  subtitle: '${records['maxWeight']['reps']} reps • ${DateFormat('MMM d, yyyy').format(records['maxWeight']['date'])}',
                ),

              const SizedBox(height: 16),

              // Max Reps
              if (records['maxReps'] != null)
                _buildRecordCard(
                  context,
                  icon: Icons.repeat,
                  iconColor: Colors.blue,
                  title: 'Most Reps',
                  value: '${records['maxReps']['reps']} reps',
                  subtitle: 'at ${records['maxReps']['weight'].toInt()}kg • ${DateFormat('MMM d, yyyy').format(records['maxReps']['date'])}',
                ),

              const SizedBox(height: 16),

              // Max Volume (Single Set)
              if (records['maxVolumeSingleSet'] != null)
                _buildRecordCard(
                  context,
                  icon: Icons.analytics,
                  iconColor: Colors.purple,
                  title: 'Max Volume (Single Set)',
                  value: '${records['maxVolumeSingleSet']['volume'].toInt()}kg',
                  subtitle: '${records['maxVolumeSingleSet']['weight'].toInt()}kg × ${records['maxVolumeSingleSet']['reps']} reps • ${DateFormat('MMM d, yyyy').format(records['maxVolumeSingleSet']['date'])}',
                ),

              const SizedBox(height: 16),

              // Max Workout Volume
              if (records['maxVolumeWorkout'] != null && records['maxVolumeWorkout']['date'] != null)
                _buildRecordCard(
                  context,
                  icon: Icons.trending_up,
                  iconColor: Colors.green,
                  title: 'Best Workout Volume',
                  value: '${records['maxVolumeWorkout']['volume'].toInt()}kg total',
                  subtitle: DateFormat('MMM d, yyyy').format(records['maxVolumeWorkout']['date']),
                ),

              const SizedBox(height: 16),

              // Estimated 1RM
              if (records['estimated1RM'] != null)
                _buildRecordCard(
                  context,
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber,
                  title: 'Estimated 1RM',
                  value: '${records['estimated1RM']['value'].toInt()}kg',
                  subtitle: 'From ${records['estimated1RM']['fromWeight'].toInt()}kg × ${records['estimated1RM']['fromReps']} reps • ${DateFormat('MMM d, yyyy').format(records['estimated1RM']['date'])}',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
