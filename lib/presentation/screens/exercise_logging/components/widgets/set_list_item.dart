import 'package:flutter/material.dart';

class SetListItem extends StatelessWidget {
  final Map<String, dynamic> set;
  final bool isCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SetListItem({
    super.key,
    required this.set,
    required this.isCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String displayKg = '-';
    String displayReps = '-';
    String displayPartials = '-';
    String displayRpe = '';

    if (isCompleted || (set['kg'] as String).isNotEmpty) {
      displayKg = set['kg'];
    }
    if (isCompleted || (set['reps'] as String).isNotEmpty) {
      displayReps = set['reps'];
    }
    if (isCompleted || set['partialReps'] != '0') {
      displayPartials = set['partialReps'];
    }
    if (isCompleted && set['rpe'] != null) {
      displayRpe = '${set['rpe'].toInt()}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: isCompleted ? Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ) : null,
      ),
      child: Row(
        children: [
          // Set number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  set['index'].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                if (isCompleted)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Previous workout
          SizedBox(
            width: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PREV',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  set['prev'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Weight
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayKg,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'kg',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Separator
          Text(
            '×',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          // Reps
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayReps.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  'reps',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Partials & RPE
          if ((displayPartials != '-' && displayPartials != '0') || displayRpe.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (displayPartials != '-' && displayPartials != '0') ...[
                    Icon(
                      Icons.add_circle_outline,
                      size: 10,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      displayPartials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                  if ((displayPartials != '-' && displayPartials != '0') && displayRpe.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        '•',
                        style: TextStyle(
                          fontSize: 8,
                          color: Theme.of(context).colorScheme.onTertiaryContainer.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  if (displayRpe.isNotEmpty) ...[
                    Icon(
                      Icons.speed,
                      size: 10,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      displayRpe,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Edit & Delete buttons
          if (isCompleted) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withValues(alpha: 0.15),
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
