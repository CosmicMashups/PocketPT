import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/report_providers.dart';

class ExerciseCalendarGrid extends ConsumerStatefulWidget {
  const ExerciseCalendarGrid({super.key});

  @override
  ConsumerState<ExerciseCalendarGrid> createState() => _ExerciseCalendarGridState();
}

class _ExerciseCalendarGridState extends ConsumerState<ExerciseCalendarGrid> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exerciseRecordsAsync = ref.watch(enhancedExerciseRecordsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: exerciseRecordsAsync.when(
        loading: () => _buildLoadingState(context, isDark),
        error: (error, stackTrace) => _buildErrorState(context, isDark, error.toString()),
        data: (exerciseRecords) => _buildCalendarContent(context, isDark, exerciseRecords),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: 16),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
          color: Color.fromRGBO(255, 0, 0, 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Failed to load calendar',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarContent(BuildContext context, bool isDark, List<ExerciseRecord> exerciseRecords) {
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: 16),
        _buildWeekdayHeader(context, isDark),
        const SizedBox(height: 8),
        _buildCalendarGrid(
          context,
          isDark,
          daysInMonth,
          firstWeekday,
          selectedDate,
          exerciseRecords,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(139, 46, 46, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF8B2E2E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Calendar',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B2E2E),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              color: const Color(0xFF8B2E2E),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month - 1,
                    1,
                  );
                });
              },
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(139, 46, 46, 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color.fromRGBO(139, 46, 46, 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    DateFormat('MMM yyyy').format(selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF8B2E2E),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              color: const Color(0xFF8B2E2E),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month + 1,
                    1,
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(BuildContext context, bool isDark) {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cell size based on available width
        // Account for 6 gaps between 7 columns (spacing: 4)
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - (6 * 4)) / 7;
        final cellSize = cellWidth.clamp(32.0, 60.0); // Min 32px, Max 60px
        
        // Calculate total width needed for the calendar
        final totalWidth = (cellSize * 7) + (6 * 4); // 7 cells + 6 gaps
        
        return Center(
          child: SizedBox(
            width: totalWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekdays
                  .map((day) => Container(
                        width: cellSize,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              fontSize: cellSize > 45 ? 12 : 10,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    bool isDark,
    int daysInMonth,
    int firstWeekday,
    DateTime selectedDate,
    List<ExerciseRecord> exerciseRecords,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal cell size based on available width
        // Account for 6 gaps between 7 columns (spacing: 4)
        final availableWidth = constraints.maxWidth;
        final cellWidth = (availableWidth - (6 * 4)) / 7;
        final cellSize = cellWidth.clamp(32.0, 60.0); // Min 32px, Max 60px
        
        final rows = <Widget>[];
        final offset = firstWeekday % 7;
        
        // Build calendar rows
        var currentDay = 1;
        while (currentDay <= daysInMonth) {
          final rowCells = <Widget>[];
          
          // Add cells for this week
          for (var i = 0; i < 7; i++) {
            if (i < offset && currentDay == 1) {
              // Empty cell before first day of month
              rowCells.add(SizedBox(width: cellSize, height: cellSize));
            } else if (currentDay <= daysInMonth) {
              // Day cell
              final date = DateTime(selectedDate.year, selectedDate.month, currentDay);
              // Normalize date to midnight for comparison
              final dateNormalized = DateTime(date.year, date.month, date.day);
              
              // Check if there are exercises on this date (normalize record dates to midnight)
              final hasExercises = exerciseRecords.any((record) {
                final recordDateNormalized = DateTime(record.date.year, record.date.month, record.date.day);
                return recordDateNormalized.year == dateNormalized.year &&
                    recordDateNormalized.month == dateNormalized.month &&
                    recordDateNormalized.day == dateNormalized.day;
              });

              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              // Count completed and partial exercises for this date (normalize dates)
              final completedExercises = exerciseRecords.where((record) {
                final recordDateNormalized = DateTime(record.date.year, record.date.month, record.date.day);
                return recordDateNormalized.year == dateNormalized.year &&
                    recordDateNormalized.month == dateNormalized.month &&
                    recordDateNormalized.day == dateNormalized.day &&
                    record.status.toLowerCase() == 'completed';
              }).length;

              final partialExercises = exerciseRecords.where((record) {
                final recordDateNormalized = DateTime(record.date.year, record.date.month, record.date.day);
                return recordDateNormalized.year == dateNormalized.year &&
                    recordDateNormalized.month == dateNormalized.month &&
                    recordDateNormalized.day == dateNormalized.day &&
                    record.status.toLowerCase() == 'partial';
              }).length;

              final totalExercises = exerciseRecords.where((record) {
                final recordDateNormalized = DateTime(record.date.year, record.date.month, record.date.day);
                return recordDateNormalized.year == dateNormalized.year &&
                    recordDateNormalized.month == dateNormalized.month &&
                    recordDateNormalized.day == dateNormalized.day;
              }).length;

              rowCells.add(
                GestureDetector(
                  onTap: () {
                    if (hasExercises) {
                      _showDayDetails(context, date, exerciseRecords, isDark);
                    }
                  },
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: _getDayColor(isToday, hasExercises, completedExercises, partialExercises, totalExercises),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: const Color(0xFF8B2E2E), width: 2)
                          : null,
                      boxShadow: hasExercises ? [
                        BoxShadow(
                          color: Color.fromRGBO(139, 46, 46, 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            currentDay.toString(),
                            style: TextStyle(
                              color: _getDayTextColor(isToday, hasExercises, isDark),
                              fontWeight: hasExercises ? FontWeight.w700 : FontWeight.w500,
                              fontSize: cellSize > 45 ? 14 : 12,
                            ),
                          ),
                        ),
                        // Show circle indicators for exercise completion status
                        if (hasExercises && (completedExercises > 0 || partialExercises > 0))
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: cellSize > 45 ? 12 : 10,
                              height: cellSize > 45 ? 12 : 10,
                              decoration: BoxDecoration(
                                color: completedExercises > 0 
                                    ? const Color(0xFF10B981) // Green for completed
                                    : const Color(0xFFF59E0B), // Orange for partial
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                color: completedExercises > 0 
                                    ? Color.fromRGBO(16, 185, 129, 0.5)
                                    : Color.fromRGBO(245, 158, 11, 0.5),
                                    blurRadius: 3,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
              currentDay++;
            } else {
              // Empty cell after last day of month
              rowCells.add(SizedBox(width: cellSize, height: cellSize));
            }
          }
          
          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: rowCells,
            ),
          );
        }
        
        // Calculate total width needed for the calendar
        final totalWidth = (cellSize * 7) + (6 * 4); // 7 cells + 6 gaps
        
        return Center(
          child: SizedBox(
            width: totalWidth,
            child: Column(
              children: rows,
            ),
          ),
        );
      },
    );
  }

  Color _getDayColor(bool isToday, bool hasExercises, int completedExercises, int partialExercises, int totalExercises) {
    if (isToday) {
      return Color.fromRGBO(139, 46, 46, 0.1);
    }
    
    if (hasExercises) {
      if (completedExercises == totalExercises) {
        return Color.fromRGBO(16, 185, 129, 0.2); // All completed - green
      } else if (completedExercises > 0) {
        return Color.fromRGBO(16, 185, 129, 0.15); // Some completed - light green
      } else if (partialExercises > 0) {
        return Color.fromRGBO(245, 158, 11, 0.2); // Only partial - orange
      } else {
        return Color.fromRGBO(239, 68, 68, 0.2); // No completed or partial - red
      }
    }
    
    return Colors.transparent;
  }

  Color _getDayTextColor(bool isToday, bool hasExercises, bool isDark) {
    if (isToday) {
      return const Color(0xFF8B2E2E);
    }
    
    if (hasExercises) {
      return const Color(0xFF8B2E2E);
    }
    
    return isDark ? Colors.white70 : Colors.grey.shade600;
  }

  void _showDayDetails(BuildContext context, DateTime date, List<ExerciseRecord> exerciseRecords, bool isDark) {
    // Normalize date to midnight for comparison
    final dateNormalized = DateTime(date.year, date.month, date.day);
    final dayRecords = exerciseRecords.where((record) {
      final recordDateNormalized = DateTime(record.date.year, record.date.month, record.date.day);
      return recordDateNormalized.year == dateNormalized.year &&
          recordDateNormalized.month == dateNormalized.month &&
          recordDateNormalized.day == dateNormalized.day;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        title: Text(
          DateFormat('EEEE, MMMM d, yyyy').format(date),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF8B2E2E),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dayRecords.isEmpty)
                Text(
                  'No exercises recorded for this day.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
                )
              else
                ...dayRecords.map((record) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: record.status.toLowerCase() == 'completed'
                              ? Color.fromRGBO(16, 185, 129, 0.3)
                              : Color.fromRGBO(245, 158, 11, 0.3),
                          width: 1,
                        ),
                      ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: record.status.toLowerCase() == 'completed'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.exerciseName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF8B2E2E),
                              ),
                            ),
                            Text(
                              '${record.sets} sets × ${record.reps} reps',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: record.status.toLowerCase() == 'completed'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: const Color(0xFF8B2E2E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}