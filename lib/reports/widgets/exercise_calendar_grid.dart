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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercise Calendar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6A5D7B), // Updated to new purple
                    ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 24),
                    color: const Color(0xFF6A5D7B), // Updated to new purple
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state = DateTime(
                        selectedDate.year,
                        selectedDate.month - 1,
                        1,
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A5D7B).withOpacity(0.1), // Updated to new purple
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('MMMM yyyy').format(selectedDate),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6A5D7B), // Updated to new purple
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 24),
                    color: const Color(0xFF6A5D7B), // Updated to new purple
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
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map((day) => SizedBox(
                width: 36,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A5D7B), // Updated to new purple
                    fontSize: 14,
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
      cells.add(const SizedBox(width: 36, height: 36));
    }

    // Add cells for each day of the month
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      final hasExercises = exerciseRecords.any((record) =>
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day);

      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      cells.add(
        GestureDetector(
          onTap: () {
            // Handle day selection if needed
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isToday
                  ? const Color(0xFF6A5D7B).withOpacity(0.2) // Updated to new purple
                  : hasExercises
                      ? const Color(0xFF6A5D7B).withOpacity(0.1) // Updated to new purple
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday
                    ? const Color(0xFF6A5D7B) // Updated to new purple
                    : Colors.grey.withOpacity(0.2),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasExercises || isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: hasExercises || isToday
                        ? const Color(0xFF6A5D7B) // Updated to new purple
                        : Colors.black87,
                  ),
                ),
                if (hasExercises)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A5D7B), // Updated to new purple
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: cells,
    );
  }
}