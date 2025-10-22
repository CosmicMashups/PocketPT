import 'package:flutter/material.dart';
import 'main.dart';
import 'record/design_system.dart';

class HomePageWithDialog extends StatefulWidget {
  const HomePageWithDialog({super.key});

  @override
  State<HomePageWithDialog> createState() => _HomePageWithDialogState();
}

class _HomePageWithDialogState extends State<HomePageWithDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.8,
      upperBound: 1.0,
    );

    // Use a slight delay to ensure the widget is fully built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showSessionCompleteDialog();
      }
    });
  }

  void _showSessionCompleteDialog() {
    debugPrint('HomeDialog: Attempting to show session complete dialog');
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        debugPrint('HomeDialog: Dialog builder called');
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          child: ScaleTransition(
            scale: _scaleController..forward(),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: RecordingDesignSystem.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
                boxShadow: RecordingDesignSystem.medicalShadowLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      color: RecordingDesignSystem.primaryMedical.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(RecordingDesignSystem.radiusXL),
                        topRight: Radius.circular(RecordingDesignSystem.radiusXL),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: RecordingDesignSystem.primaryMedical.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: RecordingDesignSystem.primaryMedical,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Session Complete!',
                            style: RecordingDesignSystem.headlineMedium.copyWith(
                              color: RecordingDesignSystem.getTextPrimaryColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
                          decoration: BoxDecoration(
                            color: RecordingDesignSystem.primaryMedical.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: RecordingDesignSystem.primaryMedical,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: RecordingDesignSystem.spacingL),
                        Text(
                          'You\'ve successfully completed today\'s exercise session. Great work on staying consistent with your rehabilitation!',
                          textAlign: TextAlign.center,
                          style: RecordingDesignSystem.bodyLarge.copyWith(
                            color: RecordingDesignSystem.getTextSecondaryColor(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                      color: RecordingDesignSystem.getBackgroundColor(context).withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(RecordingDesignSystem.radiusXL),
                        bottomRight: Radius.circular(RecordingDesignSystem.radiusXL),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            RecordingDesignSystem.primaryMedical,
                            RecordingDesignSystem.secondaryMedical,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                        boxShadow: RecordingDesignSystem.medicalShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                          onTap: () {
                            debugPrint('HomeDialog: Return to Dashboard tapped');
                            Navigator.of(context).maybePop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: RecordingDesignSystem.spacingM,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.home, color: Colors.white, size: 20),
                                const SizedBox(width: RecordingDesignSystem.spacingS),
                                Text(
                                  'Return to Dashboard',
                                  style: RecordingDesignSystem.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}