import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_providers.dart';
import '../expanded_report_page.dart';

class RehabPlanExpansionPanel extends ConsumerWidget {
  const RehabPlanExpansionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rehabPlans = ref.watch(rehabPlansProvider);

    return Card(
      elevation: 4,  // Slightly elevated to look more prominent
      color: Colors.blueGrey.shade50,  // Soft background color for the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),  // Rounded corners for the card
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.medical_services, color: Color(0xFF557A95)), // Icon on the title of ExpansionTile
        title: const Text(
          'Rehabilitation Plans History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF557A95), // Custom title color
          ),
        ),
        children: rehabPlans.map((plan) => _buildRehabPlanItem(
          context,
          plan.title,
          plan.icdCode,
          plan.status,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpandedReportPage(
                  planTitle: plan.title,
                  icdCode: plan.icdCode,
                ),
              ),
            );
          },
        )).toList(),
      ),
    );
  }

  Widget _buildRehabPlanItem(
    BuildContext context,
    String title,
    String icdCode,
    String status, {
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: Icon(
          Icons.fitness_center,  // Icon related to fitness for rehab plan
          color: status == 'ongoing' ? Color(0xFF557A95) : Colors.green,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,  // Custom text color for the title
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'ICD-10: $icdCode',
          style: TextStyle(
            color: Colors.grey[600],  // Lighter color for the subtitle
            fontSize: 14,
          ),
        ),
        trailing: Chip(
          label: Text(
            status,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: status == 'ongoing' ? Color(0xFF557A95) : Colors.green,
        ),
        onTap: onTap,
      ),
    );
  }
}