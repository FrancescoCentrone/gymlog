import 'dart:async';
import 'package:flutter/material.dart';

class StepperInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final String? hintText;

  const StepperInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.onDecrement,
    required this.onIncrement,
    this.hintText,
  });

  @override
  State<StepperInputField> createState() => _StepperInputFieldState();
}

class _StepperInputFieldState extends State<StepperInputField> {
  Timer? _timer;
  int _pressDuration = 0;

  void _startLongPress(VoidCallback callback) {
    _pressDuration = 0;
    callback(); // Execute immediately on press
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _pressDuration += 100;
      
      // Calculate interval: starts at 300ms, decreases to 50ms over 3 seconds
      // Speed increases linearly with duration
      final baseInterval = 300;
      final minInterval = 50;
      final maxDuration = 3000; // 3 seconds to reach max speed
      
      final progress = (_pressDuration / maxDuration).clamp(0.0, 1.0);
      final currentInterval = baseInterval - ((baseInterval - minInterval) * progress);
      
      // Only execute if enough time has passed based on current speed
      if (_pressDuration % currentInterval.round() < 100) {
        callback();
      }
    });
  }

  void _stopLongPress() {
    _timer?.cancel();
    _timer = null;
    _pressDuration = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildStepperButton(
              context: context,
              icon: Icons.remove,
              onPressed: widget.onDecrement,
              onLongPressStart: () => _startLongPress(widget.onDecrement),
              onLongPressEnd: _stopLongPress,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? '0',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _buildStepperButton(
              context: context,
              icon: Icons.add,
              onPressed: widget.onIncrement,
              onLongPressStart: () => _startLongPress(widget.onIncrement),
              onLongPressEnd: _stopLongPress,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required VoidCallback onLongPressStart,
    required VoidCallback onLongPressEnd,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: onPressed,
        onLongPressStart: (_) => onLongPressStart(),
        onLongPressEnd: (_) => onLongPressEnd(),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}
