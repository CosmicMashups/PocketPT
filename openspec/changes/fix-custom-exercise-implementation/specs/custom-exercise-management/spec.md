## MODIFIED Requirements

### Requirement: Custom Exercise Creation Form
The system SHALL provide a comprehensive form for users to create custom exercises with all necessary metadata fields. The form dialog title SHALL be "Custom Exercise" (not "Create Custom Exercise") to prevent horizontal overflow. The form SHALL NOT include manual input fields for image filename or video URL, as these SHALL be automatically set to default values (".jpg" and ".mp4" respectively). The muscle group dropdown SHALL contain ONLY the following standardized muscle options: Deltoids, Biceps, Triceps, Upper Back, Lower Back, Abdominals, Obliques, Multifidus, Quadriceps, Hamstrings, Calf, Gluteals. The "Other Muscles" field SHALL be a dropdown (not a text field) containing the same standardized muscle options, automatically excluding the muscle selected as the primary muscle group.

#### Scenario: User creates custom exercise
- **WHEN** user selects "Create Custom Exercise" from the add exercise options
- **THEN** a form dialog appears with title "Custom Exercise" (to prevent overflow)
- **AND** fields include: exercise name, description, muscle group (dropdown with standardized list), pain level, functional goal, repetitions, sets, and other muscles (dropdown with standardized list excluding primary muscle)
- **AND** image filename and video URL fields are NOT displayed (automatically set to ".jpg" and ".mp4")
- **AND** all required fields are marked with validation indicators
- **AND** the form provides dropdown selections for standardized values (muscle groups, pain levels, goals)

#### Scenario: Primary muscle excluded from Other Muscles dropdown
- **WHEN** user selects a muscle group (e.g., "Deltoids") in the primary muscle dropdown
- **THEN** the "Other Muscles" dropdown automatically filters out "Deltoids" from its options
- **AND** only the remaining 11 muscles are available for selection in "Other Muscles"
- **AND** if the user changes the primary muscle group, the "Other Muscles" dropdown updates accordingly

#### Scenario: Form validation prevents invalid submissions
- **WHEN** user attempts to submit the form with missing required fields
- **THEN** validation errors are displayed for each invalid field
- **AND** the submit button remains disabled until all validation passes
- **AND** specific error messages guide the user to correct the issues

### Requirement: Custom Exercise Persistence
The system SHALL save custom exercises to both Hive local storage and Firebase cloud storage (customExercises collection). The HiveCustomExerciseAdapter (typeId: 13) SHALL be registered in both `main.dart` and `globals.dart` during application initialization to enable proper Hive persistence. All newly created custom exercises SHALL automatically have `imageUrl` set to ".jpg" and `videoUrl` set to ".mp4" by default. Custom exercises SHALL be made available in the exercise selection interface immediately after creation.

#### Scenario: Custom exercise is saved successfully
- **WHEN** user submits a valid custom exercise form
- **THEN** the exercise is saved to Hive local storage using HiveCustomExerciseAdapter
- **AND** the exercise is saved to Firebase customExercises collection (if user is authenticated)
- **AND** imageUrl is automatically set to ".jpg"
- **AND** videoUrl is automatically set to ".mp4"
- **AND** a success message is displayed to the user
- **AND** the form dialog closes automatically
- **AND** the custom exercise becomes immediately available in the exercise list
- **AND** no HiveError exceptions occur during save operation

#### Scenario: Hive adapter registered at startup
- **WHEN** the application initializes
- **THEN** HiveCustomExerciseAdapter (typeId: 13) is registered in `main.dart` after typeId 12
- **AND** HiveCustomExerciseAdapter (typeId: 13) is registered in `globals.dart` after typeId 12
- **AND** custom exercise save operations complete without adapter registration errors

#### Scenario: Custom exercises persist across app sessions
- **WHEN** the app is restarted after creating custom exercises
- **THEN** custom exercises remain available in the exercise selection
- **AND** they are merged with default exercises in the exercise list
- **AND** no data loss occurs during app restarts
- **AND** data is synchronized between Hive and Firebase on app startup (if authenticated)

## ADDED Requirements

### Requirement: Dialog Scrollability and Overflow Prevention
The system SHALL ensure that all dialogs render without overflow on any screen size. Dialogs with long content SHALL be scrollable to prevent vertical overflow. Dialog titles SHALL be concise to prevent horizontal overflow.

#### Scenario: Custom Exercise dialog renders without overflow
- **WHEN** user opens the custom exercise creation dialog
- **THEN** the dialog title "Custom Exercise" fits within the dialog header without horizontal overflow
- **AND** all form fields are visible and accessible on small screens
- **AND** the dialog content is scrollable if needed to accommodate all fields

#### Scenario: Medical Support dialog is scrollable
- **WHEN** user opens the Medical Support help dialog from the plan manager
- **THEN** all dialog content is contained within the dialog bounds
- **AND** the content is scrollable to prevent vertical overflow on any screen size
- **AND** all text and disclaimers are visible and accessible

### Requirement: Dialog Button Visibility
The system SHALL ensure that all dialog buttons have visible text that contrasts properly with the button background color, following accessibility guidelines.

#### Scenario: Remove Exercise confirmation dialog button is visible
- **WHEN** user clicks "Remove" button for an exercise
- **THEN** the confirmation dialog appears with a "Delete" button
- **AND** the "Delete" button text is white (or other high-contrast color) on a dark-red background
- **AND** the button text is clearly visible in both light and dark themes
- **AND** the button styling is consistent with the app's medical design system

