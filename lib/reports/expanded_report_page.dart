import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'providers/report_providers.dart';

class ExpandedReportPage extends ConsumerWidget {
  final String planTitle;
  final String icdCode;

  const ExpandedReportPage({
    super.key,
    required this.planTitle,
    required this.icdCode,
  });

  // Define color constants
  static const mainColor = Color(0xFF800020); // Burgundy/Maroon
  static const detailColor = Color(0xFF6A5D7B); // Muted Purple
  static const completedColor = Colors.green;
  static const ongoingColor = Colors.orange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor, // Updated to mainColor
        title: Text(
          planTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.1), // Updated to mainColor
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medical_services,
                    color: mainColor, // Updated to mainColor
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Plan Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: mainColor, // Updated to mainColor
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'ICD-10 Code', icdCode),
            _buildDetailRow(context, 'Start Date', '2024-04-01'),
            _buildDetailRow(context, 'Status', 'Ongoing'),
            _buildDetailRow(context, 'Focus Area', 'Upper Body'),
            _buildDetailRow(context, 'Target Muscle', 'Rotator Cuff'),
            const SizedBox(height: 8),
          ],
        ),
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

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: detailColor.withOpacity(0.1), // Updated to detailColor
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: detailColor, // Updated to detailColor
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Exercise Records',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: detailColor, // Updated to detailColor
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filteredRecords.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'No exercise records yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredRecords.map((record) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: record.status.toLowerCase() == 'completed'
                                          ? completedColor.withOpacity(0.1)
                                          : ongoingColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.fitness_center,
                                      color: record.status.toLowerCase() == 'completed'
                                          ? completedColor
                                          : ongoingColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      record.exerciseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      record.status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: record.status.toLowerCase() == 'completed'
                                        ? completedColor
                                        : ongoingColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildRecordDetail(
                                    Icons.format_list_numbered,
                                    '${record.sets} sets × ${record.reps} reps',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildRecordDetail(
                                    Icons.calendar_today,
                                    DateFormat('MMM d, yyyy').format(record.date),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: detailColor, // Updated to detailColor
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}