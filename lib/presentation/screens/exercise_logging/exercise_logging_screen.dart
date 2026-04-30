import 'package:flutter/material.dart';
import 'package:gym_log/data/models/routine_model.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/history_tab.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/charts_tab.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/today_tab.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/records_tab.dart';

class ExerciseLoggingScreen extends StatelessWidget {
  final RoutineExercise routineExercise;
  final int workoutId;

  const ExerciseLoggingScreen({
    super.key,
    required this.routineExercise,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Hero(
            tag: 'routine_${routineExercise.exerciseId}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(routineExercise.exercise?.name ?? 'Exercise'),
            ),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'History'),
              Tab(text: 'Charts'),
              Tab(text: 'Records'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            TodayTab(
              routineExercise: routineExercise,
              workoutId: workoutId,
            ),
            HistoryTab(exerciseId: routineExercise.exerciseId),
            ChartsTab(exerciseId: routineExercise.exerciseId),
            RecordsTab(exerciseId: routineExercise.exerciseId),
          ],
        ),
      ),
    );
  }
}
