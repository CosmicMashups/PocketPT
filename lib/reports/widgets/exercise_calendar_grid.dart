import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/report_providers.dart';

class ExerciseCalendarGrid extends ConsumerWidget {
  const ExerciseCalendarGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final exerciseRecords = ref.watch(exerciseRecordsProvider);

    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercise Calendar',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple[700],
                  ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.deepPurple),
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).state = DateTime(
                      selectedDate.year,
                      selectedDate.month - 1,
                      1,
                    );
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(selectedDate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.deepPurple[700],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.deepPurple),
                  onPressed: () {
                    ref.read(selectedDateProvider.notifier).state = DateTime(
                      selectedDate.year,
                      selectedDate.month + 1,
                      1,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildWeekdayHeader(),
        const SizedBox(height: 8),
        _buildCalendarGrid(
          daysInMonth,
          firstWeekday,
          selectedDate,
          exerciseRecords,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map((day) => SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: 16,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(
    int daysInMonth,
    int firstWeekday,
    DateTime selectedDate,
    List<ExerciseRecord> exerciseRecords,
  ) {
    final cells = <Widget>[];
    final offset = firstWeekday % 7;

    // Add empty cells for days before the first of the month
    for (var i = 0; i < offset; i++) {
      cells.add(const SizedBox(width: 40, height: 40));
    }

    // Add cells for each day of the month
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final hasExercises = exerciseRecords.any((record) =>
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day);

      cells.add(
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: hasExercises ? Colors.blue.withOpacity(0.2) : null,
            boxShadow: [
              if (hasExercises)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasExercises ? FontWeight.bold : FontWeight.normal,
                    color: hasExercises ? Colors.blue : Colors.black,
                  ),
                ),
              ),
              if (hasExercises)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(
                    Icons.fitness_center,
                    size: 12,
                    color: Colors.blue[600],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cells,
    );
  }
}