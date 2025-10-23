import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stretching_exercise.dart';

/// Widget for displaying stretching exercise cards
class StretchingExerciseCard extends StatelessWidget {
  final StretchingExercise exercise;
  final bool isSelected;
  final VoidCallback onTap;

  const StretchingExerciseCard({
    Key? key,
    required this.exercise,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF8B2E2E).withOpacity(0.1) 
            : (isDark ? Theme.of(context).colorScheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF8B2E2E) 
              : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Header
              _buildExerciseHeader(),
              
              const SizedBox(height: 16),
              
              // Exercise Description
              _buildExerciseDescription(),
              
              const SizedBox(height: 16),
              
              // Exercise Details
              _buildExerciseDetails(),
              
              const SizedBox(height: 16),
              
              // Benefits Preview
              _buildBenefitsPreview(),
              
              // Selection Indicator
              if (isSelected) _buildSelectionIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF8B2E2E) 
                : const Color(0xFF8B2E2E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.fitness_center,
            color: isSelected ? Colors.white : const Color(0xFF8B2E2E),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.exerciseName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? const Color(0xFF8B2E2E) 
                      : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.exerciseType.toUpperCase(),
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? const Color(0xFF8B2E2E) 
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        // Duration Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF8B2E2E).withOpacity(0.2) 
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${exercise.recommendedDuration}s',
            style: GoogleFonts.ptSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected 
                  ? const Color(0xFF8B2E2E) 
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseDescription() {
    return Text(
      exercise.description,
      style: GoogleFonts.ptSans(
        fontSize: 14,
        color: isSelected 
            ? const Color(0xFF8B2E2E).withOpacity(0.8) 
            : const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildExerciseDetails() {
    return Row(
      children: [
        // Difficulty Level
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDifficultyColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            exercise.difficultyLevel.toUpperCase(),
            style: GoogleFonts.ptSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getDifficultyColor(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Equipment Required
        if (exercise.requiresEquipment)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.build,
                  size: 12,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  'EQUIPMENT',
                  style: GoogleFonts.ptSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBenefitsPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Benefits',
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...exercise.benefits.take(2).map((benefit) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                Expanded(
                  child: Text(
                    benefit,
                    style: GoogleFonts.ptSans(
                      fontSize: 12,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF8B2E2E),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (exercise.difficultyLevel.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'advanced':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
