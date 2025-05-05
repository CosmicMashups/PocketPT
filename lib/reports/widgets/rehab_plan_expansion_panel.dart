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
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        iconColor: const Color(0xFF6A5D7B), // Updated to new purple
        collapsedIconColor: const Color(0xFF6A5D7B), // Updated to new purple
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6A5D7B).withOpacity(0.1), // Updated to new purple
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.medical_services, 
            color: Color(0xFF6A5D7B), // Updated to new purple
            size: 24,
          ),
        ),
        title: const Text(
          'Rehabilitation Plans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${rehabPlans.length} active plan${rehabPlans.length != 1 ? 's' : ''}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: status == 'ongoing' 
                    ? const Color(0xFF6A5D7B).withOpacity(0.1) // Updated to new purple
                    : Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                color: status == 'ongoing' 
                    ? const Color(0xFF6A5D7B) // Updated to new purple
                    : Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ICD-10: $icdCode',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'ongoing' 
                    ? const Color(0xFF6A5D7B) // Updated to new purple
                    : Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}