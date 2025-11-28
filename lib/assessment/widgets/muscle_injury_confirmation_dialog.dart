import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/muscle_injury_choice.dart';

/// Dialog widget for confirming muscle injury exercise inclusion
class MuscleInjuryConfirmationDialog extends StatelessWidget {
  final List<String> injuredMuscles;
  final Map<String, String> musclePainCategories;
  final int availableExerciseCount;

  const MuscleInjuryConfirmationDialog({
    super.key,
    required this.injuredMuscles,
    required this.musclePainCategories,
    required this.availableExerciseCount,
  });

  // Professional healthcare color scheme (matching existing app patterns)
  static const mainColor = Color(0xFF8B2E2E);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);
  static const warningColor = Color(0xFFF59E0B);
  static const errorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                _buildHeader(),
                const SizedBox(height: 20),
                
                // Main message
                _buildMainMessage(),
                const SizedBox(height: 20),
                
                // Injured muscles list
                _buildInjuredMusclesList(),
                const SizedBox(height: 20),
                
                // Safety warning
                _buildSafetyWarning(),
                const SizedBox(height: 24),
                
                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: warningColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Insufficient Exercise Options',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Limited exercises available due to severe injuries.',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We found only $availableExerciseCount exercises that avoid your severely injured muscles (pain level 8-10). You can include exercises that target these muscles if you\'re comfortable, or focus on treatments only.',
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: detailColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInjuredMusclesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Target Muscles:',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: errorColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: injuredMuscles.map((muscle) {
              final category = musclePainCategories[muscle] ?? 'Unknown';
              final isSevere = category == 'Severe';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning,
                      color: errorColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      muscle,
                      style: GoogleFonts.ptSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: errorColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSevere ? "Severe" : category,
                        style: GoogleFonts.ptSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Safety Notice',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• These exercises may cause discomfort or pain\n'
            '• Please consult with your healthcare provider before proceeding\n'
            '• Monitor your pain levels during exercises\n'
            '• Stop immediately if you experience increased pain',
            style: GoogleFonts.ptSans(
              fontSize: 12,
              color: warningColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Include All Exercises Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              debugPrint('MuscleInjuryConfirmationDialog: User chose includeAll');
              Navigator.of(context).pop(MuscleInjuryChoice.includeAll);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Yes, Include All Exercises',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Keep Safe Exercises Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              debugPrint('MuscleInjuryConfirmationDialog: User chose keepSafe');
              Navigator.of(context).pop(MuscleInjuryChoice.keepSafe);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: mainColor,
              side: BorderSide(color: mainColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, size: 20),
                const SizedBox(width: 8),
                Text(
                  'No, Keep Safe Exercises Only',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Treatments Only Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              debugPrint('MuscleInjuryConfirmationDialog: User chose treatmentsOnly');
              Navigator.of(context).pop(MuscleInjuryChoice.treatmentsOnly);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: warningColor,
              side: BorderSide(color: warningColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medical_services, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Focus on Treatments Only',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Cancel Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              debugPrint('MuscleInjuryConfirmationDialog: User chose cancel');
              Navigator.of(context).pop(MuscleInjuryChoice.cancel);
            },
            style: TextButton.styleFrom(
              foregroundColor: detailColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Cancel',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
