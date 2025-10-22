// confirm_save_page.dart

import 'package:flutter/material.dart';
import 'design_system.dart';
class ConfirmSavePage extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ConfirmSavePage({required this.onSave, required this.onCancel, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RecordingDesignSystem.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(RecordingDesignSystem.spacingS),
          decoration: BoxDecoration(
            color: RecordingDesignSystem.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
            boxShadow: RecordingDesignSystem.shadowSmall,
          ),
          child: IconButton(
            icon: Icon(
              Icons.close,
              color: RecordingDesignSystem.primaryMedical,
            ),
            onPressed: onCancel,
          ),
        ),
        centerTitle: true,
        title: Text(
          'Confirm Save',
          style: RecordingDesignSystem.headlineMedium.copyWith(
            color: RecordingDesignSystem.getTextPrimaryColor(context),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(RecordingDesignSystem.spacingL),
            decoration: BoxDecoration(
              color: RecordingDesignSystem.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusXL),
              boxShadow: RecordingDesignSystem.medicalShadowLarge,
              border: Border.all(
                color: RecordingDesignSystem.getBorderColor(context),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(RecordingDesignSystem.spacingM),
                  decoration: BoxDecoration(
                    color: RecordingDesignSystem.primaryMedical.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.save_alt,
                    color: RecordingDesignSystem.primaryMedical,
                    size: 32,
                  ),
                ),
                const SizedBox(height: RecordingDesignSystem.spacingM),
                Text(
                  'Save your session?',
                  textAlign: TextAlign.center,
                  style: RecordingDesignSystem.headlineLarge.copyWith(
                    color: RecordingDesignSystem.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: RecordingDesignSystem.spacingS),
                Text(
                  'We will update your daily progress and streak based on today\'s activity.',
                  textAlign: TextAlign.center,
                  style: RecordingDesignSystem.bodyMedium.copyWith(
                    color: RecordingDesignSystem.getTextSecondaryColor(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: RecordingDesignSystem.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: RecordingDesignSystem.getBorderColor(context),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: RecordingDesignSystem.spacingM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RecordingDesignSystem.radiusM),
                          ),
                          foregroundColor: RecordingDesignSystem.getTextPrimaryColor(context),
                          backgroundColor: RecordingDesignSystem.getSurfaceColor(context),
                        ),
                        child: Text(
                          'Cancel',
                          style: RecordingDesignSystem.labelLarge.copyWith(
                            color: RecordingDesignSystem.getTextPrimaryColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: RecordingDesignSystem.spacingM),
                    Expanded(
                      child: Container(
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
                            onTap: onSave,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: RecordingDesignSystem.spacingM,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check, color: Colors.white, size: 20),
                                  const SizedBox(width: RecordingDesignSystem.spacingS),
                                  Text(
                                    'Save',
                                    style: RecordingDesignSystem.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
