import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_log/data/models/routine_exercise_set.dart';

class SetConfigurationResult {
  final List<RoutineExerciseSet> sets;
  final int restSeconds;

  SetConfigurationResult({required this.sets, required this.restSeconds});
}

class SetConfigurationScreen extends StatefulWidget {
  final String exerciseName;
  final List<RoutineExerciseSet> initialSets;
  final int initialRestSeconds;

  const SetConfigurationScreen({
    super.key,
    required this.exerciseName,
    required this.initialSets,
    required this.initialRestSeconds,
  });

  @override
  State<SetConfigurationScreen> createState() => _SetConfigurationScreenState();
}

class _SetConfigurationScreenState extends State<SetConfigurationScreen> {
  late List<RoutineExerciseSet> _sets;
  late int _restSeconds;

  @override
  void initState() {
    super.initState();
    _sets = List.from(widget.initialSets);
    _restSeconds = widget.initialRestSeconds;
    if (_sets.isEmpty) {
      _addSet();
    }
  }

  void _addSet() {
    setState(() {
      final lastSet = _sets.isNotEmpty ? _sets.last : null;
      _sets.add(RoutineExerciseSet(
        setIndex: _sets.length,
        reps: lastSet?.reps ?? 10,
      ));
    });
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
      // Re-index remaining sets
      for (int i = 0; i < _sets.length; i++) {
        _sets[i] = _sets[i].copyWith(setIndex: i);
      }
    });
  }

  void _updateSet(int index, {int? reps, int? minReps, int? maxReps, bool? isRange}) {
    setState(() {
      _sets[index] = _sets[index].copyWith(
        reps: reps,
        minReps: minReps,
        maxReps: maxReps,
        isRange: isRange,
      );
    });
  }

  void _toggleRepType(int index) {
    setState(() {
      final set = _sets[index];
      if (set.isRange) {
        // Switch to specific count, use average of range
        final avgReps = set.minReps != null && set.maxReps != null
            ? ((set.minReps! + set.maxReps!) / 2).round()
            : set.reps;
        _sets[index] = set.copyWith(
          isRange: false,
          reps: avgReps,
          minReps: null,
          maxReps: null,
        );
      } else {
        // Switch to range, create range around current reps
        final currentReps = set.reps;
        _sets[index] = set.copyWith(
          isRange: true,
          minReps: currentReps - 2 > 0 ? currentReps - 2 : 1,
          maxReps: currentReps + 2,
        );
      }
    });
  }

  bool _validate() {
    if (_restSeconds <= 0) return false;
    for (final set in _sets) {
      if (set.isRange) {
        if (set.minReps == null || set.maxReps == null ||
            set.minReps! < 1 || set.maxReps! < 1 ||
            set.minReps! > set.maxReps!) {
          return false;
        }
      } else {
        if (set.reps < 1) {
          return false;
        }
      }
    }
    return _sets.isNotEmpty;
  }

  void _save() {
    if (_validate()) {
      Navigator.pop(
        context,
        SetConfigurationResult(sets: _sets, restSeconds: _restSeconds),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please ensure all sets have valid reps (>=1, min <= max) and rest (>0).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configure: ${widget.exerciseName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: [
          // Global Rest Configuration
          Card(
            margin: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _NumberInputControl(
                label: 'Rest between sets (seconds)',
                value: _restSeconds,
                onChanged: (val) {
                  setState(() {
                    _restSeconds = val;
                  });
                },
                min: 5,
                step: 5,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _sets.length,
              itemBuilder: (context, index) {
                final set = _sets[index];
                return Dismissible(
                  key: ValueKey('set_${index}_${_sets.length}'), 
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _removeSet(index);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Set ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  set.isRange ? 'Range' : 'Fixed',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onDeleted: () => _toggleRepType(index),
                                deleteIcon: const Icon(Icons.swap_horiz, size: 16),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => _removeSet(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (set.isRange)
                            Row(
                              children: [
                                Expanded(
                                  child: _NumberInputControl(
                                    label: 'Min Reps',
                                    value: set.minReps ?? 8,
                                    onChanged: (val) => _updateSet(index, minReps: val),
                                    min: 1,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _NumberInputControl(
                                    label: 'Max Reps',
                                    value: set.maxReps ?? 12,
                                    onChanged: (val) => _updateSet(index, maxReps: val),
                                    min: 1,
                                  ),
                                ),
                              ],
                            )
                          else
                            _NumberInputControl(
                              label: 'Reps',
                              value: set.reps,
                              onChanged: (val) => _updateSet(index, reps: val),
                              min: 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NumberInputControl extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int step;

  const _NumberInputControl({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.step = 1,
  });

  @override
  State<_NumberInputControl> createState() => _NumberInputControlState();
}

class _NumberInputControlState extends State<_NumberInputControl> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _NumberInputControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (int.tryParse(_controller.text) != widget.value) {
        _controller.text = widget.value.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    widget.onChanged(widget.value + widget.step);
  }

  void _decrement() {
    if (widget.value - widget.step >= widget.min) {
      widget.onChanged(widget.value - widget.step);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelSmall),
        Row(
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.remove),
              onPressed: _decrement,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  final intVal = int.tryParse(val);
                  if (intVal != null && intVal >= widget.min) {
                    widget.onChanged(intVal);
                  }
                },
              ),
            ),
             IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: _increment,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}
