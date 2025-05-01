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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8B2E2E),
        title: Text(
          planTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildExerciseRecords(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rehabilitation Plan Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B2E2E),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('ICD-10 Code', icdCode),
            _buildDetailRow('Start Date', '2024-04-01'),
            _buildDetailRow('Status', 'Ongoing'),
            _buildDetailRow('Focus Area', 'Upper Body'),
            _buildDetailRow('Target Muscle', 'Rotator Cuff'),
            const SizedBox(height: 16),
            // Image.asset('assets/images/recovery.png', height: 150, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRecords() {
    return Consumer(
      builder: (context, ref, _) {
        final exerciseRecords = ref.watch(exerciseRecordsProvider);
        final filteredRecords = exerciseRecords
            .where((record) => record.icdCode == icdCode)
            .toList();

        if (filteredRecords.isEmpty) {
          return Card(
            color: Colors.grey.shade100,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No exercise records yet'),
            ),
          );
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exercise Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                ...filteredRecords.map((record) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fitness_center, color: Colors.blue[800]),
                              const SizedBox(width: 8),
                              Text(
                                '${record.exerciseName} (${record.sets} sets x ${record.reps} reps)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateFormat('yyyy-MM-dd').format(record.date)}',
                          ),
                          Text('Status: ${record.status}'),
                          const Divider(),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF8B2E2E), size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B2E2E),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}