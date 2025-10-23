import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for displaying stretching routine progress
class RoutineProgressWidget extends StatelessWidget {
  final int currentExercise;
  final int totalExercises;
  final int remainingTime;
  final String currentExerciseName;
  final double progressPercentage;

  const RoutineProgressWidget({
    Key? key,
    required this.currentExercise,
    required this.totalExercises,
    required this.remainingTime,
    required this.currentExerciseName,
    required this.progressPercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress Header
          _buildProgressHeader(),
          
          const SizedBox(height: 16),
          
          // Progress Bar
          _buildProgressBar(),
          
          const SizedBox(height: 16),
          
          // Current Exercise Info
          _buildCurrentExerciseInfo(),
          
          const SizedBox(height: 16),
          
          // Timer Display
          _buildTimerDisplay(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B2E2E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.track_changes,
            color: const Color(0xFF8B2E2E),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Routine Progress",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B2E2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Exercise ${currentExercise + 1} of $totalExercises",
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        // Progress Percentage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF8B2E2E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${(progressPercentage * 100).toInt()}%',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B2E2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: progressPercentage,
          minHeight: 8,
          backgroundColor: const Color(0xFFE5E7EB),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
        ),
        const SizedBox(height: 8),
        // Progress Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Started',
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            Text(
              'Complete',
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentExerciseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fitness_center,
            color: const Color(0xFF8B2E2E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Exercise",
                  style: GoogleFonts.ptSans(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentExerciseName.isNotEmpty 
                      ? currentExerciseName 
                      : "Loading...",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B2E2E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: const Color(0xFF8B2E2E),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "Time Remaining: ${remainingTime}s",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B2E2E),
            ),
          ),
        ],
      ),
    );
  }
}
