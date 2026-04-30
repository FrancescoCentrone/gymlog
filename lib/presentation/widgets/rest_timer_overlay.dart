import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/presentation/state/rest_timer_provider.dart';

class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isActive) {
      return const SizedBox.shrink();
    }

    final minutes = (timerState.remainingSeconds ~/ 60).toString().padLeft(1, '0');
    final seconds = (timerState.remainingSeconds % 60).toString().padLeft(2, '0');

    return Positioned(
      bottom: 100, // Above the navigation bar
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rest Timer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Text(
                  '$minutes:$seconds',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    ref.read(restTimerProvider.notifier).stopTimer();
                  },
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
