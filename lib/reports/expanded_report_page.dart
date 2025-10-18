import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'providers/report_providers.dart';
import '../../data/rehabilitation_plan.dart';
class ExpandedReportPage extends ConsumerWidget {
  final String planTitle;
  final String icdCode;

  const ExpandedReportPage({
    super.key,
    required this.planTitle,
    required this.icdCode,
  });

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Professional blue
  static const subColor = Color(0xFFC24A4A); // Light blue
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green
  static const warningColor = Color(0xFFF59E0B); // Orange
  static const errorColor = Color(0xFFEF4444); // Red
  static const completedColor = successColor;
  static const ongoingColor = warningColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text(
          planTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                mainColor,
                subColor,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 24),
            _buildExerciseRecords(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_information,
                  color: mainColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treatment Plan Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clinical information and progress tracking',
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: mainColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(context, 'ICD-10 Code', icdCode),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Start Date', '2024-04-01'),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Status', 'Ongoing'),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Focus Area', 'Upper Body'),
                const SizedBox(height: 16),
                _buildDetailRow(context, 'Target Muscle', 'Rotator Cuff'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseRecords(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final exerciseRecords = ref.watch(exerciseRecordsProvider);
        final filteredRecords = exerciseRecords
            .where((record) => record.icdCode == icdCode)
            .toList();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: subColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: subColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercise Records',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: mainColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Patient exercise completion history',
                          style: TextStyle(
                            fontSize: 14,
                            color: detailColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (filteredRecords.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: detailColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No exercise records yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: detailColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Exercise records will appear here once the patient starts their rehabilitation program',
                        style: TextStyle(
                          fontSize: 14,
                          color: detailColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...filteredRecords.map((record) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: record.status.toLowerCase() == 'completed'
                              ? completedColor.withOpacity(0.2)
                              : ongoingColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: record.status.toLowerCase() == 'completed'
                                      ? completedColor.withOpacity(0.1)
                                      : ongoingColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: record.status.toLowerCase() == 'completed'
                                      ? completedColor
                                      : ongoingColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FutureBuilder<Exercise?>(
                                  future: ExerciseDataService.getExerciseById(record.exerciseId),
                                  builder: (context, snapshot) {
                                    final exerciseName = snapshot.hasData && snapshot.data != null
                                        ? snapshot.data!.exerciseName
                                        : record.exerciseName; // Fallback to placeholder name
                                    
                                    return Text(
                                      exerciseName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: mainColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: record.status.toLowerCase() == 'completed'
                                      ? completedColor
                                      : ongoingColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  record.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRecordDetail(
                                  Icons.format_list_numbered,
                                  '${record.sets} sets × ${record.reps} reps',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildRecordDetail(
                                  Icons.calendar_today,
                                  DateFormat('MMM d, yyyy').format(record.date),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.circle,
              size: 12,
              color: mainColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: detailColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: mainColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordDetail(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: mainColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: mainColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}