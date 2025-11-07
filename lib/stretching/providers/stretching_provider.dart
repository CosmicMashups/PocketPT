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
  final bool isReadyConfirmed;

  const StretchingState({
    this.currentWarmupRoutine,
    this.currentCooldownRoutine,
    this.isRoutineActive = false,
    this.currentExerciseIndex = 0,
    this.remainingTime = 0,
    this.isPaused = false,
    this.completedExercises = const [],
    this.isReadyConfirmed = false,
  });

  StretchingState copyWith({
    StretchingRoutine? currentWarmupRoutine,
    StretchingRoutine? currentCooldownRoutine,
    bool? isRoutineActive,
    int? currentExerciseIndex,
    int? remainingTime,
    bool? isPaused,
    List<StretchingExercise>? completedExercises,
    bool? isReadyConfirmed,
  }) {
    return StretchingState(
      currentWarmupRoutine: currentWarmupRoutine ?? this.currentWarmupRoutine,
      currentCooldownRoutine: currentCooldownRoutine ?? this.currentCooldownRoutine,
      isRoutineActive: isRoutineActive ?? this.isRoutineActive,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      isPaused: isPaused ?? this.isPaused,
      completedExercises: completedExercises ?? this.completedExercises,
      isReadyConfirmed: isReadyConfirmed ?? this.isReadyConfirmed,
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
  bool get isReadyConfirmed => state.isReadyConfirmed;

  StretchingRoutine? get currentRoutine {
    // For warmup/cooldown pages, return routine even if not active yet (allows preview)
    if (state.currentWarmupRoutine != null) return state.currentWarmupRoutine;
    if (state.currentCooldownRoutine != null) return state.currentCooldownRoutine;
    return null;
  }

  StretchingExercise? get currentExercise {
    final routine = currentRoutine;
    // Only debug when there's an issue (null routine or invalid index) to reduce console spam
    if (routine == null) {
      print('StretchingProvider: [CURRENT EXERCISE] No routine available (warmup: ${state.currentWarmupRoutine != null}, cooldown: ${state.currentCooldownRoutine != null}, isRoutineActive: ${state.isRoutineActive})');
      return null;
    }
    if (state.currentExerciseIndex >= routine.exercises.length) {
      print('StretchingProvider: [CURRENT EXERCISE] Index ${state.currentExerciseIndex} >= ${routine.exercises.length}');
      return null;
    }
    final exercise = routine.exercises[state.currentExerciseIndex];
    // Only print when exercise changes or first access
    if (state.remainingTime == 0 || state.remainingTime == exercise.recommendedDuration) {
      print('StretchingProvider: [CURRENT EXERCISE] ${exercise.exerciseName} (index: ${state.currentExerciseIndex}, duration: ${exercise.recommendedDuration}s)');
    }
    return exercise;
  }

  double get progressPercentage {
    final routine = currentRoutine;
    if (routine == null) return 0.0;
    return state.currentExerciseIndex / routine.exercises.length;
  }

  /// Load routines for specific muscle group
  Future<void> loadRoutinesForMuscle(String muscleGroup) async {
    try {
      print('StretchingProvider: [LOAD] Loading routines for muscle group: $muscleGroup');
      final warmupRoutine = await StretchingDataService.getRoutineForMuscle(muscleGroup, 'warmup');
      final cooldownRoutine = await StretchingDataService.getRoutineForMuscle(muscleGroup, 'cooldown');
      print('StretchingProvider: [LOAD] Warmup routine: ${warmupRoutine != null ? 'loaded (${warmupRoutine.exercises.length} exercises)' : 'null'}');
      print('StretchingProvider: [LOAD] Cooldown routine: ${cooldownRoutine != null ? 'loaded (${cooldownRoutine.exercises.length} exercises)' : 'null'}');
      state = state.copyWith(
        currentWarmupRoutine: warmupRoutine,
        currentCooldownRoutine: cooldownRoutine,
      );
      print('StretchingProvider: [LOAD] State updated. isRoutineActive=${state.isRoutineActive}, currentExerciseIndex=${state.currentExerciseIndex}');
      
      // Don't auto-start - wait for user readiness confirmation
      // Routine will be in ready state but timer won't start until user confirms
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
      
      // If no routines found with pain level, try without pain level filtering
      if (warmupRoutine == null && cooldownRoutine == null) {
        print('StretchingProvider: No routines found with pain level, trying without pain filtering');
        await loadRoutinesForMuscle(muscleGroup);
        return;
      }
      
      state = state.copyWith(
        currentWarmupRoutine: warmupRoutine,
        currentCooldownRoutine: cooldownRoutine,
      );
      print('StretchingProvider: [LOAD] State updated. isRoutineActive=${state.isRoutineActive}, currentExerciseIndex=${state.currentExerciseIndex}');
      
      // Don't auto-start - wait for user readiness confirmation
      // Routine will be in ready state but timer won't start until user confirms
    } catch (e) {
      print('StretchingProvider: Error loading routines for $muscleGroup with pain level $painScale - $e');
      // Try fallback without pain level filtering
      try {
        print('StretchingProvider: Attempting fallback to load routines without pain level filtering');
        await loadRoutinesForMuscle(muscleGroup);
      } catch (fallbackError) {
        print('StretchingProvider: Fallback also failed - $fallbackError');
        // Set empty routines to prevent infinite loading
        state = state.copyWith(
          currentWarmupRoutine: null,
          currentCooldownRoutine: null,
        );
      }
    }
  }

  /// Start a stretching routine (sets up routine but doesn't start timer until readiness confirmed)
  void startRoutine(StretchingRoutine routine) {
    print('StretchingProvider: [START] Starting routine: ${routine.routineType} (${routine.exercises.length} exercises)');
    state = state.copyWith(
      currentExerciseIndex: 0,
      completedExercises: [],
      isRoutineActive: true,
      isPaused: false,
      isReadyConfirmed: false, // Require user confirmation before starting timer
      currentWarmupRoutine: routine.routineType == 'warmup' ? routine : state.currentWarmupRoutine,
      currentCooldownRoutine: routine.routineType == 'cooldown' ? routine : state.currentCooldownRoutine,
    );
    print('StretchingProvider: [START] State updated. isRoutineActive=${state.isRoutineActive}, isReadyConfirmed=${state.isReadyConfirmed}, currentExerciseIndex=${state.currentExerciseIndex}');
    print('StretchingProvider: [START] Current exercise: ${currentExercise?.exerciseName ?? 'null'}');
    // Timer will start only after user confirms readiness via confirmReadiness()
  }

  /// Confirm user readiness and start the exercise timer
  void confirmReadiness() {
    print('StretchingProvider: [READINESS] User confirmed readiness');
    state = state.copyWith(isReadyConfirmed: true);
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
    // Only start timer if readiness was already confirmed (no need to re-confirm after pause)
    if (state.isReadyConfirmed) {
      _startExerciseTimer();
    }
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
    print('StretchingProvider: [TIMER] _startExerciseTimer called. exercise=${exercise?.exerciseName ?? 'null'}, isRoutineActive=${state.isRoutineActive}, isReadyConfirmed=${state.isReadyConfirmed}');
    if (exercise == null) {
      print('StretchingProvider: [TIMER] Cannot start timer - no current exercise');
      return;
    }
    if (!state.isReadyConfirmed) {
      print('StretchingProvider: [TIMER] Cannot start timer - user has not confirmed readiness');
      return;
    }

    print('StretchingProvider: [TIMER] Starting timer for "${exercise.exerciseName}" (${exercise.recommendedDuration}s)');
    state = state.copyWith(remainingTime: exercise.recommendedDuration);
    print('StretchingProvider: [TIMER] Timer state set. remainingTime=${state.remainingTime}');
    
    _exerciseTimer?.cancel(); // Cancel any existing timer
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Read current state at time of callback
      final currentTime = state.remainingTime;
      if (currentTime > 0) {
        final newTime = currentTime - 1;
        // Only print every 5 seconds or when time is low to reduce console spam
        if (newTime % 5 == 0 || newTime <= 3) {
          print('StretchingProvider: [TIMER] Remaining time: ${newTime}s');
        }
        state = state.copyWith(remainingTime: newTime);
      } else {
        print('StretchingProvider: [TIMER] Time expired, auto-advancing to next exercise');
        timer.cancel();
        // Auto-advance to next exercise
        nextExercise();
      }
    });
    print('StretchingProvider: [TIMER] Timer started successfully');
  }

  /// Reset provider state
  void reset() {
    _exerciseTimer?.cancel();
    state = const StretchingState();
  }

  /// Initialize routine without starting timer (for preview mode)
  void initializeRoutine(StretchingRoutine routine) {
    print('StretchingProvider: [INIT] Initializing routine: ${routine.routineType} (${routine.exercises.length} exercises)');
    state = state.copyWith(
      currentExerciseIndex: 0,
      completedExercises: [],
      isRoutineActive: true,
      isPaused: false,
      isReadyConfirmed: false,
      currentWarmupRoutine: routine.routineType == 'warmup' ? routine : state.currentWarmupRoutine,
      currentCooldownRoutine: routine.routineType == 'cooldown' ? routine : state.currentCooldownRoutine,
    );
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
