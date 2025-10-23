# AI-Engineered Prompt: Stretching Integration with Exercise Recording Flow

## Feature Overview
Integrate stretching and cooldown exercises directly into the exercise recording workflow. Warm-up stretching should be offered before starting the first exercise, and cooldown stretching should be offered after completing the last exercise in the rehabilitation plan.

## Integration Points

### 1. **Pre-Recording Warm-up Integration**
- **Location**: `lib/record/pre_record_page.dart`
- **Trigger**: When user clicks "Start Recording" button
- **Flow**: PreRecordPage → WarmupStretchingPage → RecordExercisePage

### 2. **Post-Recording Cooldown Integration**
- **Location**: `lib/record/record_exercise.dart` (when "Finish" is clicked on last exercise)
- **Trigger**: After completing the last exercise in the rehabilitation plan
- **Flow**: RecordExercisePage → CooldownStretchingPage → ConfirmSavePage

## Updated Implementation

### A. Create Warm-up Stretching Page
```dart
// lib/record/warmup_stretching_page.dart
class WarmupStretchingPage extends StatefulWidget {
  final String muscleGroup;
  final Exercise firstExercise;
  
  const WarmupStretchingPage({
    Key? key,
    required this.muscleGroup,
    required this.firstExercise,
  }) : super(key: key);
}
```

### B. Create Cooldown Stretching Page
```dart
// lib/record/cooldown_stretching_page.dart
class CooldownStretchingPage extends StatefulWidget {
  final String muscleGroup;
  final List<Exercise> completedExercises;
  
  const CooldownStretchingPage({
    Key? key,
    required this.muscleGroup,
    required this.completedExercises,
  }) : super(key: key);
}
```

### C. Update PreRecordPage Integration
```dart
// In lib/record/pre_record_page.dart
// Modify the "Start Recording" button onTap to include warm-up option

onTap: () async {
  if (rehabPlan?.exerciseReferences.isEmpty != false) return;
  
  final currentExercise = await _cacheService.getExerciseById(
    rehabPlan!.exerciseReferences.first.exerciseId
  );
  if (currentExercise == null) return;
  
  // Get muscle group from assessment data
  final muscleGroup = AssessmentData.specificMuscle.isNotEmpty 
      ? AssessmentData.specificMuscle 
      : 'General';
  
  // Show warm-up option dialog
  _showWarmupOption(context, muscleGroup, currentExercise);
},

void _showWarmupOption(BuildContext context, String muscleGroup, Exercise firstExercise) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Ready to Start?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8B2E2E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We recommend a warm-up stretching routine to prepare your $muscleGroup muscles before exercising.',
              style: GoogleFonts.ptSans(
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2E2E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: const Color(0xFF8B2E2E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warm-up helps prevent injury and improves performance',
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: const Color(0xFF8B2E2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startRecordingDirectly(firstExercise);
            },
            child: Text(
              'Skip Warm-up',
              style: TextStyle(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startWithWarmup(muscleGroup, firstExercise);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2E2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Warm-up'),
          ),
        ],
      );
    },
  );
}

void _startWithWarmup(String muscleGroup, Exercise firstExercise) {
  StopwatchService.instance.start();
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          WarmupStretchingPage(
            muscleGroup: muscleGroup,
            firstExercise: firstExercise,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = RecordingDesignSystem.animationCurve;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: RecordingDesignSystem.animationMedium,
    ),
  );
}

void _startRecordingDirectly(Exercise firstExercise) {
  StopwatchService.instance.start();
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          RecordExercisePage(exercise: firstExercise),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = RecordingDesignSystem.animationCurve;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: RecordingDesignSystem.animationMedium,
    ),
  );
}
```

### D. Update RecordExercisePage Integration
```dart
// In lib/record/record_exercise.dart
// Modify the "Finish" button onTap to include cooldown option

// Replace the existing "Finish" button logic with:
} else {
  StopwatchService.instance.pause();

  // Record all completed exercises for today
  for (int i = 0; i <= currentIndex; i++) {
    final exerciseRef = rehabPlan.exerciseReferences[i];
    final exercise = await _cacheService.getExerciseById(exerciseRef.exerciseId);
    if (exercise != null) {
      try {
        await ExerciseHistory.recordTodayAndSave(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          sets: exerciseRef.sets,
          reps: exerciseRef.repetitions,
          durationSeconds: StopwatchService.instance.currentElapsed.inSeconds,
          status: 'completed',
          now: now,
        );
      } catch (e) {
        debugPrint('Failed to save completed exercise data: $e');
      }
    }
  }
  
  // Update progress tracking
  if (lastExerciseDay == null || lastExerciseDay.isBefore(today)) {
    // ... existing progress update logic ...
  }

  StopwatchService.instance.reset();

  // Get muscle group from assessment data
  final muscleGroup = AssessmentData.specificMuscle.isNotEmpty 
      ? AssessmentData.specificMuscle 
      : 'General';
  
  // Get all completed exercises for cooldown
  final completedExercises = <Exercise>[];
  for (int i = 0; i <= currentIndex; i++) {
    final exerciseRef = rehabPlan.exerciseReferences[i];
    final exercise = await _cacheService.getExerciseById(exerciseRef.exerciseId);
    if (exercise != null) {
      completedExercises.add(exercise);
    }
  }

  // Show cooldown option
  _showCooldownOption(context, muscleGroup, completedExercises);
}

void _showCooldownOption(BuildContext context, String muscleGroup, List<Exercise> completedExercises) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Great Work!',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8B2E2E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve completed all exercises! We recommend a cooldown stretching routine to help your $muscleGroup muscles recover.',
              style: GoogleFonts.ptSans(
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2E2E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.self_improvement, color: const Color(0xFF8B2E2E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cooldown helps reduce muscle soreness and promotes recovery',
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: const Color(0xFF8B2E2E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToSave(context);
            },
            child: Text(
              'Skip Cooldown',
              style: TextStyle(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startCooldown(muscleGroup, completedExercises);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2E2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Cooldown'),
          ),
        ],
      );
    },
  );
}

void _startCooldown(String muscleGroup, List<Exercise> completedExercises) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          CooldownStretchingPage(
            muscleGroup: muscleGroup,
            completedExercises: completedExercises,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = RecordingDesignSystem.animationCurve;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: RecordingDesignSystem.animationMedium,
    ),
  );
}

void _proceedToSave(BuildContext context) {
  Navigator.push(
    context,
    MedicalPageRoute(
      child: ConfirmSavePage(
        onSave: () {
          Navigator.pushAndRemoveUntil(
            context,
            MedicalPageRoute(
              child: HomePageWithDialog(),
              settings: const RouteSettings(name: '/home'),
            ),
            (route) => false,
          );
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
      settings: const RouteSettings(name: '/confirm-save'),
    ),
  );
}
```

## Updated File Structure

```
lib/
├── record/
│   ├── warmup_stretching_page.dart
│   ├── cooldown_stretching_page.dart
│   ├── pre_record_page.dart (updated)
│   └── record_exercise.dart (updated)
├── stretching/
│   ├── models/
│   │   ├── stretching_exercise.dart
│   │   └── stretching_routine.dart
│   ├── services/
│   │   └── stretching_data_service.dart
│   ├── providers/
│   │   └── stretching_provider.dart
│   └── widgets/
│       ├── exercise_instruction_widget.dart
│       ├── routine_progress_widget.dart
│       └── stretching_exercise_card.dart
└── assets/
    └── data/
        └── stretching_exercises.csv
```

## Key Integration Features

### 1. **Seamless User Experience**
- Warm-up option appears before starting exercises
- Cooldown option appears after completing all exercises
- Users can skip stretching if desired
- Maintains existing recording flow

### 2. **Muscle Group Integration**
- Uses `AssessmentData.specificMuscle` from assessment process
- Provides targeted stretching routines
- Maintains consistency with user's assessment

### 3. **Progress Tracking**
- Stretching completion can be tracked in exercise history
- Integration with existing progress reporting
- Optional stretching adherence metrics

### 4. **Healthcare Standards**
- Evidence-based stretching routines
- Safety precautions and modifications
- Professional-grade exercise instructions
- Injury prevention focus

## Implementation Benefits

### 1. **Enhanced Safety**
- Reduces injury risk during exercise
- Proper warm-up preparation
- Effective recovery with cooldown

### 2. **Improved User Experience**
- Integrated into natural workflow
- Optional but recommended
- Clear benefits communication

### 3. **Healthcare Compliance**
- Follows physical therapy standards
- Evidence-based exercise selection
- Professional-grade instructions

### 4. **Technical Excellence**
- Maintains existing code structure
- Minimal disruption to current flow
- Scalable and maintainable

This integration ensures that stretching exercises are seamlessly incorporated into the exercise recording workflow while maintaining the existing user experience and adding significant value through improved safety and recovery.
