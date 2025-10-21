## 1. Create Dialog Infrastructure
- [x] 1.1 Create enum for user choice tracking
  - [x] Add `MuscleInjuryChoice` enum with values: `includeAll`, `keepSafe`, `cancel`
  - [x] Place in `lib/assessment/models/muscle_injury_choice.dart`
- [x] 1.2 Create dialog service class
  - [x] Create `MuscleInjuryDialogService` in `lib/assessment/services/muscle_injury_dialog_service.dart`
  - [x] Implement `showConfirmationDialog()` method with proper parameters
  - [x] Add error handling and context validation
- [x] 1.3 Create dialog widget
  - [x] Create `MuscleInjuryConfirmationDialog` in `lib/assessment/widgets/muscle_injury_confirmation_dialog.dart`
  - [x] Follow existing app design patterns (cards, shadows, consistent colors)
  - [x] Implement accessibility features (semantic labels, 44px touch targets)
  - [x] Add responsive design for different screen sizes

## 2. Modify Exercise Generation Logic
- [x] 2.1 Update `generateRehabilitationPlanFromCSV()` function
  - [x] Add dialog trigger logic after exercise filtering (line 983)
  - [x] Check if filtered exercises < 3 and user has severe muscle injuries
  - [x] Implement user choice handling for different scenarios
  - [x] Add fallback logic for user cancellation
- [x] 2.2 Add exercise re-filtering logic
  - [x] Implement bypass of muscle injury filtering when user chooses "include all"
  - [x] Maintain original filtering when user chooses "keep safe"
  - [x] Handle edge cases and error scenarios
- [x] 2.3 Update logging and debugging
  - [x] Add comprehensive logging for dialog interactions
  - [x] Track user choices for analytics and debugging
  - [x] Maintain existing debug output patterns

## 3. Update GeneratePlanPage Integration
- [x] 3.1 Modify `_loadPlan()` method in `generate_plan.dart`
  - [x] Handle dialog result and update plan generation flow
  - [x] Add error handling for user cancellation scenarios
  - [x] Maintain loading states during dialog interaction
- [x] 3.2 Update error handling and user feedback
  - [x] Show appropriate error messages if user cancels
  - [x] Provide clear feedback about exercise limitations
  - [x] Maintain existing error handling patterns
- [x] 3.3 Ensure smooth navigation flow
  - [x] Handle navigation back to assessment if user cancels
  - [x] Maintain existing navigation patterns and transitions
  - [x] Test all navigation scenarios

## 4. Dialog Content and UX
- [x] 4.1 Implement dialog content
  - [x] Add clear title: "Insufficient Exercise Options"
  - [x] Create informative message explaining the situation
  - [x] List specific injured muscles that would be targeted
  - [x] Show pain levels of muscles that would be included
- [x] 4.2 Add safety warnings and recommendations
  - [x] Include healthcare consultation recommendation
  - [x] Add pain monitoring suggestions
  - [x] Emphasize potential discomfort warnings
- [x] 4.3 Implement user action buttons
  - [x] "Yes, Include All Exercises" button with clear styling
  - [x] "No, Keep Safe Exercises Only" button
  - [x] "Cancel" button to return to assessment
  - [x] Ensure proper button hierarchy and accessibility

## 5. Safety and Compliance
- [x] 5.1 Implement safety considerations
  - [x] Add clear warnings about potential discomfort
  - [x] Include healthcare provider consultation recommendations
  - [x] Provide easy exit options for users
- [x] 5.2 Ensure accessibility compliance
  - [x] Add semantic labels for screen readers
  - [x] Maintain minimum 44px touch targets
  - [x] Test with accessibility tools
- [x] 5.3 Add data privacy considerations
  - [x] Ensure user choices are properly logged for safety
  - [x] Maintain user consent tracking
  - [x] Follow existing privacy patterns

## 6. Testing and Validation
- [x] 6.1 Test dialog trigger scenarios
  - [x] Test with severe muscle injuries and < 3 exercises
  - [x] Test with moderate muscle injuries and sufficient exercises
  - [x] Test with no muscle injuries (normal flow)
- [x] 6.2 Test user choice scenarios
  - [x] Test "include all" choice and resulting plan generation
  - [x] Test "keep safe" choice with limited exercises
  - [x] Test "cancel" choice and navigation back to assessment
- [x] 6.3 Test edge cases and error handling
  - [x] Test with network connectivity issues
  - [x] Test with invalid user data
  - [x] Test dialog dismissal and recovery scenarios
- [x] 6.4 Validate UI consistency and accessibility
  - [x] Ensure design matches existing app patterns
  - [x] Test on different screen sizes and orientations
  - [x] Validate accessibility with screen readers
  - [x] Test dark/light theme compatibility

## 7. Integration and Documentation
- [x] 7.1 Update existing documentation
  - [x] Document new dialog flow in assessment documentation
  - [x] Update exercise generation documentation
  - [x] Add safety considerations to user guides
- [x] 7.2 Add code documentation
  - [x] Document dialog service methods and parameters
  - [x] Add inline comments for complex logic
  - [x] Update existing function documentation
- [x] 7.3 Validate integration with existing systems
  - [x] Ensure compatibility with existing assessment flow
  - [x] Test integration with Firebase and local storage
  - [x] Validate data persistence and synchronization
