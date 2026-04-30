import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/data/models/routine_model.dart';
import 'package:gym_log/data/models/workout_set.dart';
import 'package:gym_log/presentation/state/workout_provider.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/widgets/set_list_item.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/widgets/set_input_form.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/stepper_input_field.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/widgets/pr_celebration_service.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/widgets/volume_summary.dart';

class TodayTab extends ConsumerStatefulWidget {
  final RoutineExercise routineExercise;
  final int workoutId;

  const TodayTab({
    super.key,
    required this.routineExercise,
    required this.workoutId,
  });

  @override
  ConsumerState<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends ConsumerState<TodayTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late List<Map<String, dynamic>> _sets;
  List<WorkoutSet> _prevWorkoutSets = [];
  
  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _partialsController = TextEditingController();
  double? _selectedRpe;
  
  int _currentTargetIndex = -1;

  @override
  void initState() {
    super.initState();
    _sets = List.generate(widget.routineExercise.sets, (index) => {
      'id': null,
      'index': index + 1,
      'prev': '-', 
      'kg': '',
      'reps': '',
      'partialReps': '0',
      'rpe': null,
      'completed': false,
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSets();
    });
  }

  Future<void> _loadSets() async {
    final repository = ref.read(workoutRepositoryProvider);
    final savedSets = await repository.getWorkoutSets(widget.workoutId);
    final exerciseSets = savedSets.where((s) => s.exerciseId == widget.routineExercise.exerciseId).toList();

    final session = await repository.getWorkoutSessionById(widget.workoutId);
    final refDate = session?.startTime ?? DateTime.now();

    final prevSets = await repository.getLastTimeExerciseSets(
      widget.routineExercise.exerciseId, 
      refDate
    );

    if (!mounted) return;

    setState(() {
      if (exerciseSets.isNotEmpty) {
        for (final set in exerciseSets) {
          final index = set.setNumber - 1;
          if (index < _sets.length) {
             _sets[index]['kg'] = set.weight.toString();
             _sets[index]['reps'] = set.reps.toString();
             _sets[index]['partialReps'] = set.partialReps.toString();
             _sets[index]['rpe'] = set.rpe;
             _sets[index]['completed'] = true;
             _sets[index]['id'] = set.id;
          } else {
             _sets.add({
               'id': set.id,
               'index': set.setNumber,
               'prev': '-',
               'kg': set.weight.toString(),
               'reps': set.reps.toString(),
               'partialReps': set.partialReps.toString(),
               'rpe': set.rpe,
               'completed': true,
             });
          }
        }
      }
      _prevWorkoutSets = prevSets;
      _refreshPreviousValues();
    });
  }

  @override
  void dispose() {
    _kgController.dispose();
    _repsController.dispose();
    _partialsController.dispose();
    super.dispose();
  }

  Future<void> _logSet() async {
    final kgText = _kgController.text;
    final repsText = _repsController.text;
    final partialsText = _partialsController.text;

    if (kgText.isEmpty || repsText.isEmpty) return;

    final kg = double.tryParse(kgText) ?? 0.0;
    final reps = int.tryParse(repsText) ?? 0;
    final partials = int.tryParse(partialsText) ?? 0;

    final nextIndex = _sets.indexWhere((s) => !(s['completed'] as bool));
    final setNumber = nextIndex != -1 ? nextIndex + 1 : _sets.length + 1;
    
    final workoutSet = WorkoutSet(
      workoutId: widget.workoutId,
      exerciseId: widget.routineExercise.exercise!.id!, 
      setNumber: setNumber,
      reps: reps,
      partialReps: partials,
      weight: kg,
      rpe: _selectedRpe,
      completedAt: DateTime.now(),
    );

    final repository = ref.read(workoutRepositoryProvider);
    final oldRecords = await repository.getExerciseRecords(widget.routineExercise.exerciseId);
    final newSetId = await repository.logSet(workoutSet);
    final newRecords = await repository.getExerciseRecords(widget.routineExercise.exerciseId);
    
    if (mounted) PRCelebrationService.checkAndShowPR(context, oldRecords, newRecords);
    HapticFeedback.mediumImpact();

    if (!mounted) return;

    setState(() {
      if (nextIndex != -1) {
        _sets[nextIndex]['kg'] = kgText;
        _sets[nextIndex]['reps'] = repsText;
        _sets[nextIndex]['partialReps'] = partials.toString();
        _sets[nextIndex]['rpe'] = _selectedRpe;
        _sets[nextIndex]['completed'] = true;
        _sets[nextIndex]['id'] = newSetId;
      } else {
        _sets.add({
          'id': newSetId,
          'index': setNumber,
          'prev': '-',
          'kg': kgText,
          'reps': repsText,
          'partialReps': partials.toString(),
          'completed': true,
        });
      }
      _refreshPreviousValues();
    });
  }

  Future<void> _deleteSet(int index) async {
    final set = _sets[index];
    if (set['completed'] != true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text('Delete Set ${set['index']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || set['id'] == null) return;
    
    await ref.read(workoutRepositoryProvider).deleteWorkoutSet(set['id']);
    if (!mounted) return;

    setState(() {
      _sets.removeAt(index);
      for (int i = index; i < _sets.length; i++) _sets[i]['index'] = i + 1;
      _refreshPreviousValues();
    });

    for (int i = index; i < _sets.length; i++) {
      if (_sets[i]['completed'] == true && _sets[i]['id'] != null) {
        await ref.read(workoutRepositoryProvider).updateWorkoutSetNumber(_sets[i]['id'], i + 1);
      }
    }
  }

  void _refreshPreviousValues() {
    for (int i = 0; i < _sets.length; i++) {
      if (i < _prevWorkoutSets.length) {
        final prevSet = _prevWorkoutSets[i];
        final partialsStr = prevSet.partialReps > 0 ? ' + ${prevSet.partialReps}' : '';
        _sets[i]['prev'] = '${prevSet.weight.toInt()}kg x ${prevSet.reps}$partialsStr';
      } else {
        _sets[i]['prev'] = '-';
      }
    }
  }

  void _updateInputControllers(int index) {
      if (index == _currentTargetIndex) return;
      _currentTargetIndex = index;

      String? targetKg;
      String? targetReps;
      String? targetPartials;

      if (index < _sets.length) {
         final prevVal = _sets[index]['prev'] as String;
         if (prevVal != '-' && prevVal.contains('kg x')) {
             final parts = prevVal.split('kg x');
             if (parts.length == 2) {
                 targetKg = parts[0].trim();
                 final repsPartVal = parts[1].trim();
                 if (repsPartVal.contains('+')) {
                   final rpParts = repsPartVal.split('+');
                   targetReps = rpParts[0].trim();
                   targetPartials = rpParts[1].trim();
                 } else {
                   targetReps = repsPartVal;
                   targetPartials = '0';
                 }
             }
         }
      }

      if (targetKg == null && index > 0) {
          final prevSetFn = _sets[index - 1];
          if (prevSetFn['completed'] == true) {
              targetKg = prevSetFn['kg'];
              targetReps = prevSetFn['reps'];
              targetPartials = prevSetFn['partialReps'];
          }
      }

      if (targetKg == null) {
          targetKg = '20';
          targetReps = widget.routineExercise.maxReps > 0 ? widget.routineExercise.maxReps.toString() : '10';
          targetPartials = '0';
      }

      _kgController.text = targetKg ?? '20';
      _repsController.text = targetReps ?? '10';
      _partialsController.text = targetPartials ?? '0';
      _selectedRpe = null;
  }

  void _modifyWeight(double delta) {
    double current = double.tryParse(_kgController.text) ?? 0.0;
    double newValue = current + delta;
    if (newValue < 0) newValue = 0;
    _kgController.text = newValue % 1 == 0 ? newValue.toInt().toString() : newValue.toString();
  }

  void _modifyReps(int delta) {
    int current = int.tryParse(_repsController.text) ?? 0;
    int newValue = current + delta;
    if (newValue < 0) newValue = 0;
    _repsController.text = newValue.toString();
  }

  void _modifyPartials(int delta) {
    int current = int.tryParse(_partialsController.text) ?? 0;
    int newValue = current + delta;
    if (newValue < 0) newValue = 0;
    _partialsController.text = newValue.toString();
  }

  Future<void> _editSet(int index) async {
    final set = _sets[index];
    if (set['completed'] != true) return;

    final kgController = TextEditingController(text: set['kg'] ?? '');
    final repsController = TextEditingController(text: set['reps'] ?? '');
    final partialsController = TextEditingController(text: set['partialReps'] ?? '0');
    double? editRpe = set['rpe'];

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit Set ${set['index']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 StepperInputField(label: 'KG', controller: kgController, keyboardType: const TextInputType.numberWithOptions(decimal: true), onDecrement: () => _editModifyWeight(kgController, -0.5), onIncrement: () => _editModifyWeight(kgController, 0.5)),
                 const SizedBox(height: 16),
                 Row(children: [
                   Expanded(child: StepperInputField(label: 'REPS', controller: repsController, keyboardType: TextInputType.number, onDecrement: () => _editModifyReps(repsController, -1), onIncrement: () => _editModifyReps(repsController, 1))),
                   const SizedBox(width: 8),
                   Expanded(child: StepperInputField(label: 'PARTIALS', controller: partialsController, keyboardType: TextInputType.number, onDecrement: () => _editModifyReps(partialsController, -1), onIncrement: () => _editModifyReps(partialsController, 1))),
                 ]),
                 const SizedBox(height: 16),
                 DropdownButtonFormField<double>(
                  value: editRpe,
                  decoration: const InputDecoration(labelText: 'RPE'),
                  items: List.generate(10, (index) => index + 1).map((val) => DropdownMenuItem<double>(value: val.toDouble(), child: Text(val.toString()))).toList(),
                  onChanged: (val) => setDialogState(() => editRpe = val),
                 ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop({'kg': kgController.text, 'reps': repsController.text, 'partials': partialsController.text, 'rpe': editRpe?.toString() ?? ''}), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (result == null || !mounted) return;

    await ref.read(workoutRepositoryProvider).updateWorkoutSet(set['id'], double.tryParse(result['kg']!) ?? 0, int.tryParse(result['reps']!) ?? 0, partialReps: int.tryParse(result['partials']!) ?? 0, rpe: double.tryParse(result['rpe']!));

    setState(() {
      set['kg'] = result['kg'];
      set['reps'] = result['reps'];
      set['partialReps'] = result['partials'];
      set['rpe'] = double.tryParse(result['rpe']!);
    });
  }

  void _editModifyWeight(TextEditingController controller, double delta) {
    double current = double.tryParse(controller.text) ?? 0;
    double newValue = (current + delta);
    if (newValue < 0) newValue = 0;
    newValue = (newValue * 2).roundToDouble() / 2;
    controller.text = newValue % 1 == 0 ? newValue.toInt().toString() : newValue.toString();
  }

  void _editModifyReps(TextEditingController controller, int delta) {
    int current = int.tryParse(controller.text) ?? 0;
    int newValue = current + delta;
    if (newValue < 0) newValue = 0;
    controller.text = newValue.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final nextIndex = _sets.indexWhere((s) => !(s['completed'] as bool));
    final targetSetIndex = nextIndex != -1 ? nextIndex : _sets.length; 
    
    if (_currentTargetIndex != targetSetIndex) {
       WidgetsBinding.instance.addPostFrameCallback((_) => _updateInputControllers(targetSetIndex));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SetInputForm(
          displaySetNumber: targetSetIndex + 1,
          restSeconds: widget.routineExercise.restSeconds,
          minReps: widget.routineExercise.minReps,
          maxReps: widget.routineExercise.maxReps,
          kgController: _kgController,
          repsController: _repsController,
          partialsController: _partialsController,
          selectedRpe: _selectedRpe,
          onRpeChanged: (val) => setState(() => _selectedRpe = val),
          onWeightDecrement: () => _modifyWeight(-0.5),
          onWeightIncrement: () => _modifyWeight(0.5),
          onRepsDecrement: () => _modifyReps(-1),
          onRepsIncrement: () => _modifyReps(1),
          onPartialsDecrement: () => _modifyPartials(-1),
          onPartialsIncrement: () => _modifyPartials(1),
          onLogSet: _logSet,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text(
                'LOGGED SETS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_sets.where((s) => s['completed'] == true).length}/${_sets.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          itemCount: _sets.length,
          itemBuilder: (context, index) => SetListItem(
            set: _sets[index],
            isCompleted: _sets[index]['completed'] == true,
            onEdit: () => _editSet(index),
            onDelete: () => _deleteSet(index),
          ),
        ),
        VolumeSummary(sets: _sets),
        const SizedBox(height: 80), // Bottom padding for navigation bar
      ],
      ),
    );
  }
}
