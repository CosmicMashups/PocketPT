import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/animations.dart';
import '../core/medical_design_system.dart';
import 'exercise_list.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;
  final bool isSelecting;

  const ExerciseDetailPage({
    super.key, 
    required this.exercise,
    this.isSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    String imagePath = 'assets/images/exercise/${exercise.imageUrl}';
    final bool hasImage = exercise.imageUrl.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.name,
          style: MedicalDesignSystem.headerStyle.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: MedicalDesignSystem.primaryBrand,
        elevation: 8,
        shadowColor: MedicalDesignSystem.primaryBrand.withOpacity(0.3),
        flexibleSpace: Container(
          decoration: MedicalDesignSystem.medicalGradientBackground,
        ),
        actions: [
          IconButton(
            icon: const Icon(MedicalIcons.contactSupport, color: Colors.white),
            onPressed: () => _showMedicalSupport(context),
            tooltip: 'Medical Support',
          ),
        ],
      ),
      backgroundColor: MedicalDesignSystem.backgroundClean,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: AnimationLimiter(
          child: ListView(
            children: [
              // Medical Exercise Hero Image
              AnimationConfiguration.staggeredList(
                position: 0,
                duration: PocketPTAnimations.pageTransition,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Container(
                      decoration: MedicalDesignSystem.medicalCardAccentDecoration,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            hasImage
                                ? Image.asset(
                                    imagePath,
                                    height: 280,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 280,
                                        color: MedicalDesignSystem.primaryBrand.withOpacity(0.1),
                                        child: Icon(
                                          MedicalIcons.fitnessCenter,
                                          color: MedicalDesignSystem.primaryBrand,
                                          size: 100,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 280,
                                    width: double.infinity,
                                    color: MedicalDesignSystem.primaryBrand.withOpacity(0.08),
                                    child: Icon(
                                      MedicalIcons.fitnessCenter,
                                      color: MedicalDesignSystem.primaryBrand,
                                      size: 100,
                                    ),
                                  ),
                            // Medical overlay gradient
                            Container(
                              height: 280,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    MedicalDesignSystem.primaryBrand.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                            // Medical safety indicator
                            Positioned(
                              top: 16,
                              right: 16,
                              child: MedicalDesignSystem.medicalStatusBadge(
                                text: 'Medical Exercise',
                                status: MedicalStatus.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Medical Exercise Description
              AnimationConfiguration.staggeredList(
                position: 1,
                duration: PocketPTAnimations.pageTransition,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: MedicalDesignSystem.medicalCardWithHeader(
                      title: 'Exercise Description',
                      icon: MedicalIcons.healthAndSafety,
                      iconColor: MedicalDesignSystem.primaryBrand,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.description,
                            style: MedicalDesignSystem.bodyStyle,
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 16),
                          MedicalDesignSystem.medicalDisclaimerBanner(
                            text: 'Follow proper form and stop if you experience pain. Consult your healthcare provider if you have concerns.',
                            isWarning: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Medical Exercise Information
              AnimationConfiguration.staggeredList(
                position: 2,
                duration: PocketPTAnimations.pageTransition,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: MedicalDesignSystem.medicalCardWithHeader(
                      title: 'Medical Exercise Information',
                      icon: MedicalIcons.medicalServices,
                      iconColor: MedicalDesignSystem.primaryBrand,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MedicalDesignSystem.medicalStatusBadge(
                                text: 'Primary: ${exercise.muscle}',
                                status: MedicalStatus.info,
                              ),
                              const SizedBox(width: 8),
                              MedicalDesignSystem.medicalStatusBadge(
                                text: 'Pain Level: ${exercise.painLevel}',
                                status: MedicalStatus.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              MedicalDesignSystem.medicalStatusBadge(
                                text: 'Goal: ${exercise.goal}',
                                status: MedicalStatus.success,
                              ),
                              const SizedBox(width: 8),
                              MedicalDesignSystem.medicalStatusBadge(
                                text: '${exercise.rep} reps',
                                status: MedicalStatus.info,
                              ),
                            ],
                          ),
                          if (exercise.otherMuscles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            MedicalDesignSystem.medicalStatusBadge(
                              text: 'Secondary: ${exercise.otherMuscles}',
                              status: MedicalStatus.info,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Medical Action Buttons
              AnimationConfiguration.staggeredList(
                position: 3,
                duration: PocketPTAnimations.pageTransition,
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Column(
                      children: [
                        if (isSelecting) ...[
                          // Selection mode - show Select button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: MedicalDesignSystem.primaryMedicalButton,
                              onPressed: () => _selectExercise(context),
                              icon: const Icon(MedicalIcons.checkCircle),
                              label: const Text('Select Exercise'),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ] else ...[
                          // Normal mode - show exercise action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: MedicalDesignSystem.primaryMedicalButton,
                                  onPressed: () => _startExercise(context),
                                  icon: const Icon(MedicalIcons.fitnessCenter),
                                  label: const Text('Start Exercise'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: MedicalDesignSystem.warningMedicalButton,
                                  onPressed: () => _reportPain(context),
                                  icon: const Icon(MedicalIcons.emergency),
                                  label: const Text('Report Pain'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: MedicalDesignSystem.secondaryMedicalButton,
                            onPressed: () => _contactHealthcareProvider(context),
                            icon: const Icon(MedicalIcons.contactSupport),
                            label: const Text('Contact Healthcare Provider'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectExercise(BuildContext context) {
    // Return the exercise to the calling page
    Navigator.pop(context, exercise);
  }

  void _startExercise(BuildContext context) {
    // TODO: Implement exercise start logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Starting exercise...'),
        backgroundColor: MedicalDesignSystem.primaryBrand,
      ),
    );
  }

  void _reportPain(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(MedicalIcons.emergency, color: MedicalDesignSystem.dangerRed),
            const SizedBox(width: 8),
            const Text('Report Pain'),
          ],
        ),
        content: const Text(
          'If you are experiencing pain during this exercise, please stop immediately and consult your healthcare provider.',
        ),
        actions: [
          ElevatedButton(
            style: MedicalDesignSystem.warningMedicalButton,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _contactHealthcareProvider(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(MedicalIcons.contactSupport, color: MedicalDesignSystem.primaryBrand),
            const SizedBox(width: 8),
            const Text('Contact Healthcare Provider'),
          ],
        ),
        content: const Text(
          'For medical concerns or questions about your exercise plan, please contact your healthcare provider.',
        ),
        actions: [
          ElevatedButton(
            style: MedicalDesignSystem.primaryMedicalButton,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMedicalSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(MedicalIcons.contactSupport, color: MedicalDesignSystem.primaryBrand),
            const SizedBox(width: 8),
            const Text('Medical Support'),
          ],
        ),
        content: const Text(
          'For medical support and questions about this exercise, please consult your healthcare provider.',
        ),
        actions: [
          ElevatedButton(
            style: MedicalDesignSystem.primaryMedicalButton,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}