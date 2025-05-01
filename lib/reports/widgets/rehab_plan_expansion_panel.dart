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
      child: ExpansionTile(
        title: const Text('Rehabilitation Plans History'),
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
    return ListTile(
      title: Text(title),
      subtitle: Text('ICD-10: $icdCode'),
      trailing: Chip(
        label: Text(
          status,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: status == 'ongoing' ? Colors.blue : Colors.green,
      ),
      onTap: onTap,
    );
  }
} 