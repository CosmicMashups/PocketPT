import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../expanded_report_page.dart';
import '../../data/rehabilitation_plan.dart';
import '../../data/treatment.dart';
import '../providers/report_providers.dart';

class RehabPlanExpansionPanel extends ConsumerWidget {
  const RehabPlanExpansionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rehabPlansAsync = ref.watch(enhancedRehabPlansProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: rehabPlansAsync.when(
        loading: () => _buildLoadingExpansionTile(context, isDark),
        error: (error, stackTrace) => _buildErrorExpansionTile(context, isDark, error.toString()),
        data: (rehabPlans) => _buildExpansionTile(context, isDark, rehabPlans),
      ),
    );
  }

  Widget _buildExpansionTile(BuildContext context, bool isDark, List<RehabPlan> rehabPlans) {
    return ExpansionTile(
      initiallyExpanded: true,
      collapsedBackgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      iconColor: const Color(0xFF8B2E2E),
      collapsedIconColor: const Color(0xFF8B2E2E),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B2E2E).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.medical_services, 
          color: Color(0xFF8B2E2E),
          size: 24,
        ),
      ),
      title: Text(
        'Rehabilitation Plans',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF8B2E2E),
        ),
      ),
      subtitle: Text(
        rehabPlans.isEmpty 
          ? 'No active plans - Complete assessment to generate plan'
          : '${rehabPlans.length} active plan${rehabPlans.length != 1 ? 's' : ''}',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      children: rehabPlans.isEmpty 
        ? [_buildEmptyState(context, isDark)]
        : [
            // Exercise plans
            ...rehabPlans.map((plan) => _buildExercisePlanItem(
              context,
              plan,
              isDark,
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
            // Add treatment plans if they exist
            ..._buildTreatmentPlans(context, isDark),
          ],
    );
  }

  Widget _buildLoadingExpansionTile(BuildContext context, bool isDark) {
    return ExpansionTile(
      initiallyExpanded: true,
      collapsedBackgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      iconColor: const Color(0xFF8B2E2E),
      collapsedIconColor: const Color(0xFF8B2E2E),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B2E2E).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.medical_services, 
          color: Color(0xFF8B2E2E),
          size: 24,
        ),
      ),
      title: Text(
        'Rehabilitation Plans',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF8B2E2E),
        ),
      ),
      subtitle: const Text(
        'Loading plans...',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorExpansionTile(BuildContext context, bool isDark, String error) {
    return ExpansionTile(
      initiallyExpanded: true,
      collapsedBackgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      backgroundColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      iconColor: const Color(0xFFEF4444),
      collapsedIconColor: const Color(0xFFEF4444),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline, 
          color: Color(0xFFEF4444),
          size: 24,
        ),
      ),
      title: Text(
        'Rehabilitation Plans',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF8B2E2E),
        ),
      ),
      subtitle: const Text(
        'Failed to load plans',
        style: TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Error loading rehabilitation plans',
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

  List<Widget> _buildTreatmentPlans(BuildContext context, bool isDark) {
    final userRehab = UserRehabilitation.instance;
    if (userRehab.treatmentReferences == null || userRehab.treatmentReferences!.isEmpty) {
      return [];
    }

    return userRehab.treatmentReferences!.map((treatmentRef) => _buildTreatmentPlanItem(
      context,
      treatmentRef,
      isDark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpandedReportPage(
              planTitle: 'Treatment Plan',
              icdCode: 'TREAT-${treatmentRef.treatmentId}',
            ),
          ),
        );
      },
    )).toList();
  }

  Widget _buildExercisePlanItem(
    BuildContext context,
    RehabPlan plan,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2E2E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Color(0xFF8B2E2E),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF8B2E2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${plan.focusArea} • ${plan.targetMuscle}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
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
                color: const Color(0xFF8B2E2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                plan.status.toUpperCase(),
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

  Widget _buildTreatmentPlanItem(
    BuildContext context,
    TreatmentReference treatmentRef,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return FutureBuilder<Treatment?>(
      future: ExerciseDataService.getTreatmentById(treatmentRef.treatmentId),
      builder: (context, snapshot) {
        final treatment = snapshot.data;
        final treatmentName = treatment?.treatmentName ?? 'Treatment ${treatmentRef.treatmentId}';
        
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B2E2E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Color(0xFF8B2E2E),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatmentName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF8B2E2E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Treatment Plan',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
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
                    color: const Color(0xFF8B2E2E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'ONGOING',
                    style: TextStyle(
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
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 48,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No active rehabilitation plans',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your assessment to generate a personalized rehabilitation plan',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}