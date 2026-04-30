import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const WeekCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  List<DateTime> _getCurrentWeek() {
    final now = DateTime.now();
    // Start of week (assuming Monday start)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getCurrentWeek();
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekDates.map((date) {
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, today);

          return Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(date),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !isSelected
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(date).substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isToday && !isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
