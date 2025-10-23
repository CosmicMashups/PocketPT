import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/stretching_exercise.dart';
import '../models/stretching_routine.dart';
import '../services/stretching_data_service.dart';

/// State for stretching routine
class StretchingState {
  final StretchingRoutine? currentWarmupRoutine;
  final StretchingRoutine? currentCooldownRoutine;
  final bool isRoutineActive;
  final int currentExerciseIndex;
  final int remainingTime;
  final bool isPaused;
  final List<StretchingExercise> completedExercises;

  const StretchingState({
    this.currentWarmupRoutine,
    this.currentCooldownRoutine,
    this.isRoutineActive = false,
    this.currentExerciseIndex = 0,
    this.remainingTime = 0,
    this.isPaused = false,
    this.completedExercises = const [],
  });

  StretchingState copyWith({
    StretchingRoutine? currentWarmupRoutine,
    StretchingRoutine? currentCooldownRoutine,
    bool? isRoutineActive,
    int? currentExerciseIndex,
    int? remainingTime,
    bool? isPaused,
    List<StretchingExercise>? completedExercises,
  }) {
    return StretchingState(
      currentWarmupRoutine: currentWarmupRoutine ?? this.currentWarmupRoutine,
      currentCooldownRoutine: currentCooldownRoutine ?? this.currentCooldownRoutine,
      isRoutineActive: isRoutineActive ?? this.isRoutineActive,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      isPaused: isPaused ?? this.isPaused,
      completedExercises: completedExercises ?? this.completedExercises,
    );
  }
}

/// Provider for managing stretching routine state
class StretchingNotifier extends StateNotifier<StretchingState> {
  Timer? _exerciseTimer;

  StretchingNotifier() : super(const StretchingState());

  // Getters
  StretchingRoutine? get currentWarmupRoutine => state.currentWarmupRoutine;
  StretchingRoutine? get currentCooldownRoutine => state.currentCooldownRoutine;
  bool get isRoutineActive => state.isRoutineActive;
  int get currentExerciseIndex => state.currentExerciseIndex;
  int get remainingTime => state.remainingTime;
  bool get isPaused => state.isPaused;
  List<StretchingExercise> get completedExercises => state.completedExercises;

  StretchingRoutine? get currentRoutine {
    if (state.currentWarmupRoutine != null && state.isRoutineActive) return state.currentWarmupRoutine;
    if (state.currentCooldownRoutine != null && state.isRoutineActive) return state.currentCooldownRoutine;
    return null;
  }

  StretchingExercise? get currentExercise {
    final routine = currentRoutine;
    if (routine == null || state.currentExerciseIndex >= routine.exercises.length) {
      return null;
    }
    return routine.exercises[state.currentExerciseIndex];
  }

  double get progressPercentage {
    final routine = currentRoutine;
    if (routine == null) return 0.0;
    return state.currentExerciseIndex / routine.exercises.length;
  }

  /// Load routines for specific muscle group
  Future<void> loadRoutinesForMuscle(String muscleGroup) async {
    try {
      final warmupRoutine = await StretchingDataService.getRoutineForMuscle(muscleGroup, 'warmup');
      final cooldownRoutine = await StretchingDataService.getRoutineForMuscle(muscleGroup, 'cooldown');
      state = state.copyWith(
        currentWarmupRoutine: warmupRoutine,
        currentCooldownRoutine: cooldownRoutine,
      );
    } catch (e) {
      print('StretchingProvider: Error loading routines for $muscleGroup - $e');
    }
  }

  /// Load routines for specific muscle group with pain level consideration
  Future<void> loadRoutinesForMuscleWithPainLevel(String muscleGroup, int painScale) async {
    try {
      print('StretchingProvider: Loading routines for $muscleGroup with pain level $painScale');
      
      // Add timeout to prevent infinite loading
      final warmupRoutine = await StretchingDataService.getRoutineForMuscleWithPainLevel(
        muscleGroup, 'warmup', painScale).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('StretchingProvider: Timeout loading warmup routine for $muscleGroup');
          return null;
        },
      );
      
      final cooldownRoutine = await StretchingDataService.getRoutineForMuscleWithPainLevel(
        muscleGroup, 'cooldown', painScale).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('StretchingProvider: Timeout loading cooldown routine for $muscleGroup');
          return null;
        },
      );
      
      print('StretchingProvider: Loaded warmup routine: ${warmupRoutine != null}');
      print('StretchingProvider: Loaded cooldown routine: ${cooldownRoutine != null}');
      
      state = state.copyWith(
        currentWarmupRoutine: warmupRoutine,
        currentCooldownRoutine: cooldownRoutine,
      );
    } catch (e) {
      print('StretchingProvider: Error loading routines for $muscleGroup with pain level $painScale - $e');
      // Set empty routines to prevent infinite loading
      state = state.copyWith(
        currentWarmupRoutine: null,
        currentCooldownRoutine: null,
      );
    }
  }

  /// Start a stretching routine
  void startRoutine(StretchingRoutine routine) {
    state = state.copyWith(
      currentExerciseIndex: 0,
      completedExercises: [],
      isRoutineActive: true,
      isPaused: false,
      currentWarmupRoutine: routine.routineType == 'warmup' ? routine : state.currentWarmupRoutine,
      currentCooldownRoutine: routine.routineType == 'cooldown' ? routine : state.currentCooldownRoutine,
    );
    
    _startExerciseTimer();
  }

  /// Pause the current routine
  void pauseRoutine() {
    _exerciseTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  /// Resume the current routine
  void resumeRoutine() {
    state = state.copyWith(isPaused: false);
    _startExerciseTimer();
  }

  /// Move to next exercise
  void nextExercise() {
    final routine = currentRoutine;
    if (routine == null) return;

    // Complete current exercise
    final newCompletedExercises = List<StretchingExercise>.from(state.completedExercises);
    if (currentExercise != null) {
      newCompletedExercises.add(currentExercise!);
    }

    _exerciseTimer?.cancel();

    if (state.currentExerciseIndex < routine.exercises.length - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
        completedExercises: newCompletedExercises,
      );
      _startExerciseTimer();
    } else {
      completeRoutine();
    }
  }

  /// Move to previous exercise
  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      _exerciseTimer?.cancel();
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex - 1);
      _startExerciseTimer();
    }
  }

  /// Complete the current routine
  void completeRoutine() {
    _exerciseTimer?.cancel();
    state = state.copyWith(
      isRoutineActive: false,
      isPaused: false,
      remainingTime: 0,
    );
  }

  /// Start timer for current exercise
  void _startExerciseTimer() {
    final exercise = currentExercise;
    if (exercise == null) return;

    state = state.copyWith(remainingTime: exercise.recommendedDuration);
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime > 0) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
          timer.cancel();
          // Auto-advance to next exercise
          nextExercise();
        }
    });
  }

  /// Reset provider state
  void reset() {
    _exerciseTimer?.cancel();
    state = const StretchingState();
  }

  @override
  void dispose() {
    _exerciseTimer?.cancel();
    super.dispose();
  }
}

/// Stretching provider
final stretchingProvider = StateNotifierProvider<StretchingNotifier, StretchingState>((ref) {
  return StretchingNotifier();
});
