import 'package:flutter/material.dart';
import 'package:gym_log/presentation/screens/exercise_logging/components/stepper_input_field.dart';

class SetInputForm extends StatelessWidget {
  final int displaySetNumber;
  final int restSeconds;
  final int minReps;
  final int maxReps;
  final TextEditingController kgController;
  final TextEditingController repsController;
  final TextEditingController partialsController;
  final double? selectedRpe;
  final ValueChanged<double?> onRpeChanged;
  final VoidCallback onWeightDecrement;
  final VoidCallback onWeightIncrement;
  final VoidCallback onRepsDecrement;
  final VoidCallback onRepsIncrement;
  final VoidCallback onPartialsDecrement;
  final VoidCallback onPartialsIncrement;
  final VoidCallback onLogSet;

  const SetInputForm({
    super.key,
    required this.displaySetNumber,
    required this.restSeconds,
    required this.minReps,
    required this.maxReps,
    required this.kgController,
    required this.repsController,
    required this.partialsController,
    required this.selectedRpe,
    required this.onRpeChanged,
    required this.onWeightDecrement,
    required this.onWeightIncrement,
    required this.onRepsDecrement,
    required this.onRepsIncrement,
    required this.onPartialsDecrement,
    required this.onPartialsIncrement,
    required this.onLogSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with set number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        'SET',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displaySetNumber.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  minReps == maxReps ? '$minReps reps' : '$minReps-$maxReps reps',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${restSeconds}s',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onLogSet,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 2,
                    shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'LOG SET',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Input fields
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: StepperInputField(
                        label: 'WEIGHT (KG)',
                        controller: kgController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onDecrement: onWeightDecrement,
                        onIncrement: onWeightIncrement,
                        hintText: '0',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: StepperInputField(
                        label: 'REPS',
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        onDecrement: onRepsDecrement,
                        onIncrement: onRepsIncrement,
                        hintText: '0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: StepperInputField(
                        label: 'PARTIALS',
                        controller: partialsController,
                        keyboardType: TextInputType.number,
                        onDecrement: onPartialsDecrement,
                        onIncrement: onPartialsIncrement,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RPE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<double>(
                            value: selectedRpe,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: List.generate(10, (index) => index + 1).map((val) {
                              return DropdownMenuItem<double>(
                                value: val.toDouble(),
                                child: Text(
                                  val.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: onRpeChanged,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
