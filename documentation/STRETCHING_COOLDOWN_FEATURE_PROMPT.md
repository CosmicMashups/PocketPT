# AI-Engineered Prompt: Stretching and Cooldown Exercise Routine Feature

## Feature Overview
Implement a comprehensive stretching and cooldown exercise routine system that provides personalized warm-up and cool-down exercises for each specific muscle group selected during the assessment process. This feature will enhance user safety, improve exercise effectiveness, and follow healthcare standards for physical therapy and rehabilitation.

## Technical Requirements

### 1. Data Structure Implementation

#### A. Create StretchingExercise Model
```dart
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
}
```

#### B. Create StretchingRoutine Model
```dart
class StretchingRoutine {
  final String routineId;
  final String muscleGroup;
  final String routineType; // 'warmup' or 'cooldown'
  final List<StretchingExercise> exercises;
  final int totalDuration; // in seconds
  final String difficultyLevel;
  final String description;
  final List<String> generalInstructions;
}
```

### 2. CSV Data Structure

Create `assets/data/stretching_exercises.csv` with the following columns:
```csv
exercise_id,exercise_name,muscle_group,exercise_type,description,step_1,step_2,step_3,step_4,step_5,step_6,step_7,step_8,recommended_duration,difficulty_level,benefit_1,benefit_2,benefit_3,precaution_1,precaution_2,precaution_3,image_path,video_path,requires_equipment,equipment_needed
```

### 3. Muscle Group Mapping

Map each muscle from the assessment pages to appropriate stretching routines:

#### Core Muscles (from b_core.dart):
- **Abdominals**: Core stability stretches, cat-cow stretches, seated spinal twists
- **Obliques**: Side bends, seated side stretches, standing side stretches
- **Lower Back**: Child's pose, knee-to-chest stretches, pelvic tilts
- **Multifidus**: Seated forward folds, gentle spinal rotations, supine knee rolls

#### Upper Body Muscles (from b_upperbody.dart):
- **Deltoids**: Arm circles, cross-body arm stretches, doorway stretches
- **Biceps**: Bicep stretches, wall stretches, overhead arm stretches
- **Triceps**: Tricep stretches, overhead tricep stretches, cross-body tricep stretches
- **Cervical Muscle**: Neck rolls, gentle neck stretches, shoulder shrugs

#### Lower Body Muscles (from b_lowerbody.dart):
- **Quadriceps**: Standing quad stretches, lying quad stretches, wall quad stretches
- **Hamstrings**: Seated hamstring stretches, standing hamstring stretches, lying hamstring stretches
- **Calf**: Wall calf stretches, standing calf stretches, seated calf stretches
- **Ankle**: Ankle circles, calf raises, toe stretches
- **Gluteals**: Seated glute stretches, lying glute stretches, pigeon pose variations

### 4. Implementation Architecture

#### A. Data Service Layer
```dart
class StretchingDataService {
  static Future<List<StretchingExercise>> loadStretchingExercises() async;
  static Future<List<StretchingRoutine>> loadStretchingRoutines() async;
  static Future<StretchingRoutine?> getRoutineForMuscle(String muscleGroup, String routineType) async;
  static Future<List<StretchingExercise>> getExercisesForMuscle(String muscleGroup, String routineType) async;
}
```

#### B. State Management
```dart
class StretchingRoutineProvider extends ChangeNotifier {
  StretchingRoutine? _currentWarmupRoutine;
  StretchingRoutine? _currentCooldownRoutine;
  bool _isRoutineActive = false;
  int _currentExerciseIndex = 0;
  Timer? _exerciseTimer;
  int _remainingTime = 0;
  
  // Methods for routine management
  void startRoutine(StretchingRoutine routine);
  void pauseRoutine();
  void resumeRoutine();
  void nextExercise();
  void previousExercise();
  void completeRoutine();
}
```

### 5. User Interface Components

#### A. Stretching Routine Page
```dart
class StretchingRoutinePage extends StatefulWidget {
  final String muscleGroup;
  final String routineType; // 'warmup' or 'cooldown'
  
  const StretchingRoutinePage({
    Key? key,
    required this.muscleGroup,
    required this.routineType,
  }) : super(key: key);
}
```

#### B. Exercise Instruction Widget
```dart
class ExerciseInstructionWidget extends StatelessWidget {
  final StretchingExercise exercise;
  final bool isActive;
  final int remainingTime;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onComplete;
}
```

#### C. Routine Progress Widget
```dart
class RoutineProgressWidget extends StatelessWidget {
  final int currentExercise;
  final int totalExercises;
  final int remainingTime;
  final String currentExerciseName;
}
```

### 6. Integration Points

#### A. Assessment Integration
- Modify `AssessmentData` to include selected muscle group
- Update muscle selection pages to trigger stretching routine recommendation
- Add stretching routine suggestion after muscle selection

#### B. Exercise Recording Integration
- Add stretching routine completion tracking to exercise records
- Include stretching routine data in reports
- Track stretching routine adherence in progress reports

#### C. Report Integration
- Add stretching routine completion statistics to reports
- Include stretching routine recommendations in treatment plans
- Track stretching routine effectiveness metrics

### 7. Healthcare Standards Compliance

#### A. Exercise Safety Guidelines
- Include proper form instructions for each exercise
- Add contraindications and precautions
- Provide modification options for different fitness levels
- Include proper breathing techniques

#### B. Duration and Intensity Guidelines
- Follow ACSM (American College of Sports Medicine) guidelines
- Implement progressive difficulty levels
- Include rest periods between exercises
- Provide intensity scaling options

#### C. Medical Considerations
- Include injury prevention guidelines
- Add pain scale integration for stretching intensity
- Provide modifications for common conditions
- Include emergency stop procedures

### 8. CSV Data Content Requirements

#### A. Exercise Instructions Format
Each exercise should include:
- Clear, step-by-step instructions (8 steps maximum)
- Proper form cues
- Breathing instructions
- Common mistakes to avoid
- Modification options

#### B. Safety Information
- Contraindications for each exercise
- Warning signs to watch for
- When to stop or modify
- Equipment safety considerations

#### C. Healthcare Professional Review
- All exercises should be reviewed by licensed physical therapists
- Include evidence-based benefits
- Follow current rehabilitation standards
- Include references to supporting research

### 9. User Experience Features

#### A. Routine Customization
- Allow users to skip exercises if needed
- Provide alternative exercises for the same muscle group
- Include difficulty level adjustments
- Add personal preference settings

#### B. Progress Tracking
- Track routine completion rates
- Monitor stretching routine adherence
- Include feedback collection
- Provide routine effectiveness metrics

#### C. Accessibility Features
- Voice-guided instructions
- Large text options
- High contrast mode support
- Screen reader compatibility

### 10. Implementation Steps

#### Phase 1: Data Foundation
1. Create CSV file with all stretching exercises
2. Implement data models and services
3. Create basic UI components
4. Test data loading and parsing

#### Phase 2: Core Functionality
1. Implement routine selection logic
2. Create exercise instruction pages
3. Add timer and progress tracking
4. Integrate with assessment flow

#### Phase 3: Advanced Features
1. Add customization options
2. Implement progress tracking
3. Create reporting integration
4. Add accessibility features

#### Phase 4: Testing and Refinement
1. Conduct user testing
2. Gather healthcare professional feedback
3. Refine exercise instructions
4. Optimize user experience

### 11. Success Metrics

#### A. User Engagement
- Routine completion rates
- User satisfaction scores
- Feature adoption rates
- Time spent in stretching routines

#### B. Health Outcomes
- Reduced injury rates
- Improved exercise performance
- Increased user compliance
- Better rehabilitation outcomes

#### C. Technical Performance
- Fast loading times
- Smooth user experience
- Reliable data persistence
- Cross-platform compatibility

### 12. Future Enhancements

#### A. AI-Powered Personalization
- Machine learning-based routine recommendations
- Adaptive difficulty adjustment
- Personalized exercise modifications
- Predictive injury prevention

#### B. Advanced Analytics
- Detailed progress tracking
- Performance analytics
- Health outcome correlation
- Predictive modeling

#### C. Integration Opportunities
- Wearable device integration
- Health app synchronization
- Telehealth platform integration
- Electronic health record connectivity

## Implementation Priority

1. **High Priority**: Core data structure and basic UI
2. **Medium Priority**: Advanced features and customization
3. **Low Priority**: AI integration and advanced analytics

This feature will significantly enhance the user experience by providing evidence-based stretching routines that improve exercise safety and effectiveness while maintaining healthcare standards for physical therapy and rehabilitation.
