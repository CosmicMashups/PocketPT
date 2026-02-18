# Stretching and Cooldown Exercise Routine - Implementation Guide

## Overview
This guide provides step-by-step instructions for implementing the stretching and cooldown exercise routine feature in the PocketPT application.

## 1. File Structure Setup

### A. Create New Directories
```
lib/
├── stretching/
│   ├── models/
│   │   ├── stretching_exercise.dart
│   │   └── stretching_routine.dart
│   ├── services/
│   │   └── stretching_data_service.dart
│   ├── providers/
│   │   └── stretching_provider.dart
│   ├── pages/
│   │   ├── stretching_routine_page.dart
│   │   ├── exercise_instruction_page.dart
│   │   └── stretching_selection_page.dart
│   └── widgets/
│       ├── exercise_instruction_widget.dart
│       ├── routine_progress_widget.dart
│       └── stretching_exercise_card.dart
```

### B. Update Assets
```
assets/
├── data/
│   └── stretching_exercises.csv
└── images/
    └── stretches/
        ├── seated_spinal_twist.png
        ├── cat_cow.png
        ├── standing_quad.png
        └── [other exercise images]
```

## 2. Data Models Implementation

### A. StretchingExercise Model
```dart
// lib/stretching/models/stretching_exercise.dart
class StretchingExercise {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String exerciseType; // 'warmup' or 'cooldown'
  final String description;
  final List<String> stepByStepInstructions;
  final int recommendedDuration; // in seconds
  final String difficultyLevel; // 'beginner', 'intermediate', 'advanced'
  final List<String> benefits;
  final List<String> precautions;
  final String imagePath;
  final String videoPath; // optional
  final bool requiresEquipment;
  final String equipmentNeeded;

  StretchingExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.exerciseType,
    required this.description,
    required this.stepByStepInstructions,
    required this.recommendedDuration,
    required this.difficultyLevel,
    required this.benefits,
    required this.precautions,
    required this.imagePath,
    required this.videoPath,
    required this.requiresEquipment,
    required this.equipmentNeeded,
  });

  factory StretchingExercise.fromCSV(List<dynamic> row) {
    return StretchingExercise(
      exerciseId: row[0].toString(),
      exerciseName: row[1].toString(),
      muscleGroup: row[2].toString(),
      exerciseType: row[3].toString(),
      description: row[4].toString(),
      stepByStepInstructions: [
        row[5].toString(),
        row[6].toString(),
        row[7].toString(),
        row[8].toString(),
        row[9].toString(),
        row[10].toString(),
        row[11].toString(),
        row[12].toString(),
      ].where((step) => step.isNotEmpty).toList(),
      recommendedDuration: int.tryParse(row[13].toString()) ?? 30,
      difficultyLevel: row[14].toString(),
      benefits: [
        row[15].toString(),
        row[16].toString(),
        row[17].toString(),
      ].where((benefit) => benefit.isNotEmpty).toList(),
      precautions: [
        row[18].toString(),
        row[19].toString(),
        row[20].toString(),
      ].where((precaution) => precaution.isNotEmpty).toList(),
      imagePath: row[21].toString(),
      videoPath: row[22].toString(),
      requiresEquipment: row[23].toString().toLowerCase() == 'true',
      equipmentNeeded: row[24].toString(),
    );
  }
}
```

### B. StretchingRoutine Model
```dart
// lib/stretching/models/stretching_routine.dart
class StretchingRoutine {
  final String routineId;
  final String muscleGroup;
  final String routineType; // 'warmup' or 'cooldown'
  final List<StretchingExercise> exercises;
  final int totalDuration; // in seconds
  final String difficultyLevel;
  final String description;
  final List<String> generalInstructions;

  StretchingRoutine({
    required this.routineId,
    required this.muscleGroup,
    required this.routineType,
    required this.exercises,
    required this.totalDuration,
    required this.difficultyLevel,
    required this.description,
    required this.generalInstructions,
  });

  int get exerciseCount => exercises.length;
  bool get isEmpty => exercises.isEmpty;
}
```

## 3. Data Service Implementation

### A. StretchingDataService
```dart
// lib/stretching/services/stretching_data_service.dart
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/stretching_exercise.dart';
import '../models/stretching_routine.dart';

class StretchingDataService {
  static List<StretchingExercise>? _cachedExercises;
  static List<StretchingRoutine>? _cachedRoutines;

  /// Load all stretching exercises from CSV
  static Future<List<StretchingExercise>> loadStretchingExercises() async {
    if (_cachedExercises != null) {
      return _cachedExercises!;
    }

    try {
      print('StretchingDataService: Loading stretching exercises from CSV...');
      final csvData = await rootBundle.loadString('assets/data/stretching_exercises.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);

      if (csvTable.isEmpty) {
        print('StretchingDataService: CSV file is empty');
        return [];
      }

      // Skip header row and map to StretchingExercise objects
      final exercises = csvTable.skip(1).map((row) {
        if (row.length < 25) {
          print('StretchingDataService: Warning - row has insufficient columns: ${row.length}');
          return null;
        }
        
        return StretchingExercise.fromCSV(row);
      }).where((exercise) => exercise != null).cast<StretchingExercise>().toList();

      _cachedExercises = exercises;
      print('StretchingDataService: Successfully loaded ${exercises.length} stretching exercises');
      return exercises;
    } catch (e, stackTrace) {
      print('StretchingDataService: ERROR loading stretching exercises - $e');
      print('StretchingDataService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Load stretching routines based on exercises
  static Future<List<StretchingRoutine>> loadStretchingRoutines() async {
    if (_cachedRoutines != null) {
      return _cachedRoutines!;
    }

    try {
      final exercises = await loadStretchingExercises();
      final routines = <StretchingRoutine>[];

      // Group exercises by muscle group and type
      final groupedExercises = <String, Map<String, List<StretchingExercise>>>{};
      
      for (final exercise in exercises) {
        if (!groupedExercises.containsKey(exercise.muscleGroup)) {
          groupedExercises[exercise.muscleGroup] = {};
        }
        if (!groupedExercises[exercise.muscleGroup]!.containsKey(exercise.exerciseType)) {
          groupedExercises[exercise.muscleGroup]![exercise.exerciseType] = [];
        }
        groupedExercises[exercise.muscleGroup]![exercise.exerciseType]!.add(exercise);
      }

      // Create routines for each muscle group and type combination
      for (final muscleGroup in groupedExercises.keys) {
        for (final exerciseType in groupedExercises[muscleGroup]!.keys) {
          final routineExercises = groupedExercises[muscleGroup]![exerciseType]!;
          if (routineExercises.isNotEmpty) {
            final totalDuration = routineExercises.fold(0, (sum, exercise) => sum + exercise.recommendedDuration);
            
            routines.add(StretchingRoutine(
              routineId: '${muscleGroup}_${exerciseType}',
              muscleGroup: muscleGroup,
              routineType: exerciseType,
              exercises: routineExercises,
              totalDuration: totalDuration,
              difficultyLevel: _getMostCommonDifficulty(routineExercises),
              description: '${exerciseType.capitalize()} routine for ${muscleGroup}',
              generalInstructions: _getGeneralInstructions(exerciseType),
            ));
          }
        }
      }

      _cachedRoutines = routines;
      print('StretchingDataService: Successfully loaded ${routines.length} stretching routines');
      return routines;
    } catch (e, stackTrace) {
      print('StretchingDataService: ERROR loading stretching routines - $e');
      print('StretchingDataService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get routine for specific muscle group and type
  static Future<StretchingRoutine?> getRoutineForMuscle(String muscleGroup, String routineType) async {
    final routines = await loadStretchingRoutines();
    try {
      return routines.firstWhere((routine) => 
        routine.muscleGroup == muscleGroup && routine.routineType == routineType);
    } catch (e) {
      print('StretchingDataService: No routine found for $muscleGroup $routineType');
      return null;
    }
  }

  /// Get exercises for specific muscle group and type
  static Future<List<StretchingExercise>> getExercisesForMuscle(String muscleGroup, String routineType) async {
    final exercises = await loadStretchingExercises();
    return exercises.where((exercise) => 
      exercise.muscleGroup == muscleGroup && exercise.exerciseType == routineType).toList();
  }

  static String _getMostCommonDifficulty(List<StretchingExercise> exercises) {
    final difficultyCounts = <String, int>{};
    for (final exercise in exercises) {
      difficultyCounts[exercise.difficultyLevel] = (difficultyCounts[exercise.difficultyLevel] ?? 0) + 1;
    }
    return difficultyCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static List<String> _getGeneralInstructions(String exerciseType) {
    if (exerciseType == 'warmup') {
      return [
        'Perform each exercise slowly and controlled',
        'Focus on proper form over intensity',
        'Breathe deeply throughout each movement',
        'Stop if you feel any sharp pain',
        'Hold each stretch for the recommended duration'
      ];
    } else {
      return [
        'Relax and breathe deeply during each stretch',
        'Hold each position for the full duration',
        'Focus on releasing tension from your muscles',
        'Stop if you feel any discomfort',
        'Take your time and don\'t rush through the routine'
      ];
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
```

## 4. State Management Implementation

### A. StretchingProvider
```dart
// lib/stretching/providers/stretching_provider.dart
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/stretching_exercise.dart';
import '../models/stretching_routine.dart';
import '../services/stretching_data_service.dart';

class StretchingProvider extends ChangeNotifier {
  StretchingRoutine? _currentWarmupRoutine;
  StretchingRoutine? _currentCooldownRoutine;
  bool _isRoutineActive = false;
  int _currentExerciseIndex = 0;
  Timer? _exerciseTimer;
  int _remainingTime = 0;
  bool _isPaused = false;
  List<StretchingExercise> _completedExercises = [];

  // Getters
  StretchingRoutine? get currentWarmupRoutine => _currentWarmupRoutine;
  StretchingRoutine? get currentCooldownRoutine => _currentCooldownRoutine;
  bool get isRoutineActive => _isRoutineActive;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get remainingTime => _remainingTime;
  bool get isPaused => _isPaused;
  List<StretchingExercise> get completedExercises => _completedExercises;

  StretchingRoutine? get currentRoutine {
    if (_currentWarmupRoutine != null && _isRoutineActive) return _currentWarmupRoutine;
    if (_currentCooldownRoutine != null && _isRoutineActive) return _currentCooldownRoutine;
    return null;
  }

  StretchingExercise? get currentExercise {
    final routine = currentRoutine;
    if (routine == null || _currentExerciseIndex >= routine.exercises.length) {
      return null;
    }
    return routine.exercises[_currentExerciseIndex];
  }

  double get progressPercentage {
    final routine = currentRoutine;
    if (routine == null) return 0.0;
    return _currentExerciseIndex / routine.exercises.length;
  }

  /// Load routines for specific muscle group
  Future<void> loadRoutinesForMuscle(String muscleGroup) async {
    try {
      _currentWarmupRoutine = await StretchingDataService.getRoutineForMuscle(muscleGroup, 'warmup');
      _currentCooldownRoutine = await StretchingDataService.getRoutineForMuscle(muscleGroup, 'cooldown');
      notifyListeners();
    } catch (e) {
      print('StretchingProvider: Error loading routines for $muscleGroup - $e');
    }
  }

  /// Start a stretching routine
  void startRoutine(StretchingRoutine routine) {
    _currentExerciseIndex = 0;
    _completedExercises.clear();
    _isRoutineActive = true;
    _isPaused = false;
    
    if (routine.routineType == 'warmup') {
      _currentWarmupRoutine = routine;
    } else {
      _currentCooldownRoutine = routine;
    }
    
    _startExerciseTimer();
    notifyListeners();
  }

  /// Pause the current routine
  void pauseRoutine() {
    _isPaused = true;
    _exerciseTimer?.cancel();
    notifyListeners();
  }

  /// Resume the current routine
  void resumeRoutine() {
    _isPaused = false;
    _startExerciseTimer();
    notifyListeners();
  }

  /// Move to next exercise
  void nextExercise() {
    final routine = currentRoutine;
    if (routine == null) return;

    // Complete current exercise
    if (currentExercise != null) {
      _completedExercises.add(currentExercise!);
    }

    _exerciseTimer?.cancel();

    if (_currentExerciseIndex < routine.exercises.length - 1) {
      _currentExerciseIndex++;
      _startExerciseTimer();
    } else {
      completeRoutine();
    }
    
    notifyListeners();
  }

  /// Move to previous exercise
  void previousExercise() {
    if (_currentExerciseIndex > 0) {
      _exerciseTimer?.cancel();
      _currentExerciseIndex--;
      _startExerciseTimer();
      notifyListeners();
    }
  }

  /// Complete the current routine
  void completeRoutine() {
    _isRoutineActive = false;
    _isPaused = false;
    _exerciseTimer?.cancel();
    _remainingTime = 0;
    notifyListeners();
  }

  /// Start timer for current exercise
  void _startExerciseTimer() {
    final exercise = currentExercise;
    if (exercise == null) return;

    _remainingTime = exercise.recommendedDuration;
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        notifyListeners();
      } else {
        timer.cancel();
        // Auto-advance to next exercise
        nextExercise();
      }
    });
  }

  /// Reset provider state
  void reset() {
    _currentWarmupRoutine = null;
    _currentCooldownRoutine = null;
    _isRoutineActive = false;
    _currentExerciseIndex = 0;
    _exerciseTimer?.cancel();
    _remainingTime = 0;
    _isPaused = false;
    _completedExercises.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _exerciseTimer?.cancel();
    super.dispose();
  }
}
```

## 5. UI Implementation

### A. Stretching Routine Page
```dart
// lib/stretching/pages/stretching_routine_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/stretching_provider.dart';
import '../widgets/exercise_instruction_widget.dart';
import '../widgets/routine_progress_widget.dart';

class StretchingRoutinePage extends StatefulWidget {
  final String muscleGroup;
  final String routineType; // 'warmup' or 'cooldown'
  
  const StretchingRoutinePage({
    Key? key,
    required this.muscleGroup,
    required this.routineType,
  }) : super(key: key);

  @override
  State<StretchingRoutinePage> createState() => _StretchingRoutinePageState();
}

class _StretchingRoutinePageState extends State<StretchingRoutinePage> {
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StretchingProvider>().loadRoutinesForMuscle(widget.muscleGroup);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StretchingProvider>(
      builder: (context, stretchingProvider, child) {
        final routine = widget.routineType == 'warmup' 
            ? stretchingProvider.currentWarmupRoutine
            : stretchingProvider.currentCooldownRoutine;

        if (routine == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: _buildAppBar(),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: _buildAppBar(),
          body: SafeArea(
            child: Column(
              children: [
                // Progress Section
                RoutineProgressWidget(
                  currentExercise: stretchingProvider.currentExerciseIndex,
                  totalExercises: routine.exercises.length,
                  remainingTime: stretchingProvider.remainingTime,
                  currentExerciseName: stretchingProvider.currentExercise?.exerciseName ?? '',
                  progressPercentage: stretchingProvider.progressPercentage,
                ),
                
                const SizedBox(height: 24),
                
                // Exercise Instruction
                Expanded(
                  child: stretchingProvider.currentExercise != null
                      ? ExerciseInstructionWidget(
                          exercise: stretchingProvider.currentExercise!,
                          isActive: stretchingProvider.isRoutineActive,
                          remainingTime: stretchingProvider.remainingTime,
                          onNext: () => stretchingProvider.nextExercise(),
                          onPrevious: () => stretchingProvider.previousExercise(),
                          onComplete: () => stretchingProvider.completeRoutine(),
                        )
                      : _buildRoutineComplete(),
                ),
                
                // Control Buttons
                _buildControlButtons(stretchingProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: mainColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "${widget.routineType.capitalize()} - ${widget.muscleGroup}",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildRoutineComplete() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Routine Complete!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Great job completing your ${widget.routineType} routine!',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: detailColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(StretchingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (provider.currentExerciseIndex > 0)
            ElevatedButton.icon(
              onPressed: () => provider.previousExercise(),
              icon: const Icon(Icons.skip_previous),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                backgroundColor: detailColor,
                foregroundColor: Colors.white,
              ),
            ),
          
          if (provider.isRoutineActive)
            ElevatedButton.icon(
              onPressed: provider.isPaused 
                  ? () => provider.resumeRoutine()
                  : () => provider.pauseRoutine(),
              icon: Icon(provider.isPaused ? Icons.play_arrow : Icons.pause),
              label: Text(provider.isPaused ? 'Resume' : 'Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: subColor,
                foregroundColor: Colors.white,
              ),
            ),
          
          ElevatedButton.icon(
            onPressed: () => provider.nextExercise(),
            icon: const Icon(Icons.skip_next),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
```

## 6. Integration with Assessment Flow

### A. Update Assessment Pages
Add stretching routine recommendation after muscle selection:

```dart
// In b_core.dart, b_upperbody.dart, b_lowerbody.dart
// Add this method to show stretching routine recommendation

void _showStretchingRecommendation(String muscleGroup) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Recommended Stretching Routine',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: mainColor,
          ),
        ),
        content: Text(
          'We recommend performing a warm-up stretching routine before your assessment to prepare your $muscleGroup muscles.',
          style: GoogleFonts.ptSans(
            fontSize: 16,
            color: detailColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Skip', style: TextStyle(color: detailColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StretchingRoutinePage(
                    muscleGroup: muscleGroup,
                    routineType: 'warmup',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Warm-up'),
          ),
        ],
      );
    },
  );
}
```

### B. Update Main App Provider
```dart
// In main.dart, add StretchingProvider to the provider list
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => StretchingProvider()),
    // ... other providers
  ],
  child: MyApp(),
)
```

## 7. Testing and Validation

### A. Unit Tests
Create test files for:
- StretchingExercise model
- StretchingDataService
- StretchingProvider

### B. Integration Tests
Test the complete flow:
1. Muscle selection
2. Stretching routine recommendation
3. Routine execution
4. Progress tracking

### C. User Testing
- Test with different muscle groups
- Validate exercise instructions clarity
- Check accessibility features
- Verify healthcare standards compliance

## 8. Deployment Checklist

- [ ] CSV file created with all exercises
- [ ] Data models implemented
- [ ] Services implemented and tested
- [ ] UI components created
- [ ] State management implemented
- [ ] Integration with assessment flow
- [ ] Testing completed
- [ ] Healthcare professional review
- [ ] Documentation updated
- [ ] Performance optimization
- [ ] Accessibility testing
- [ ] Cross-platform testing

This implementation provides a comprehensive stretching and cooldown exercise routine system that enhances user safety and exercise effectiveness while maintaining healthcare standards.
