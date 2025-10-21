# Design: Muscle Injury Confirmation Dialog System

## Architecture Overview

The muscle injury confirmation dialog system extends the existing exercise generation flow to provide users with informed choice when exercise filtering results in insufficient options. The design maintains safety as the primary concern while providing flexibility for users with multiple muscle injuries.

## System Components

### 1. Dialog Service Layer
- **MuscleInjuryDialogService**: Centralized service for dialog management
- **MuscleInjuryChoice**: Enum for tracking user decisions
- **Dialog State Management**: Handles dialog lifecycle and result processing

### 2. UI Components
- **MuscleInjuryConfirmationDialog**: Main dialog widget with safety warnings
- **Responsive Design**: Adapts to different screen sizes and orientations
- **Accessibility Support**: Screen reader compatibility and touch target compliance

### 3. Integration Points
- **Exercise Generation**: Modified filtering logic in `generateRehabilitationPlanFromCSV()`
- **Plan Generation**: Updated flow in `GeneratePlanPage._loadPlan()`
- **Assessment Flow**: Navigation handling for user cancellation

## Design Decisions

### 1. Dialog Trigger Logic
**Decision**: Only show dialog when filtered exercises < 3 AND user has severe muscle injuries
**Rationale**: 
- Prevents unnecessary dialogs for users with sufficient safe exercises
- Focuses on cases where muscle injury filtering significantly limits options
- Maintains safety by only offering choice when truly needed

### 2. User Choice Options
**Decision**: Three clear options - Include All, Keep Safe, Cancel
**Rationale**:
- "Include All" provides maximum exercise options with informed consent
- "Keep Safe" maintains current safety-first approach
- "Cancel" allows users to reconsider their assessment data

### 3. Safety Communication
**Decision**: Prominent warnings about potential discomfort and healthcare consultation
**Rationale**:
- Ensures users understand the implications of their choice
- Maintains medical safety standards
- Provides clear guidance for users who may be unsure

### 4. Dialog Placement
**Decision**: Trigger dialog within exercise generation function, not in UI layer
**Rationale**:
- Keeps business logic centralized in data layer
- Maintains separation of concerns
- Allows for easier testing and maintenance

## Data Flow

```
1. User completes assessment with muscle injuries
2. Exercise generation begins with standard filtering
3. If filtered exercises < 3 AND severe injuries exist:
   a. Show confirmation dialog
   b. User makes choice
   c. Apply choice to exercise filtering
4. Continue with plan generation based on final exercise set
5. Handle navigation based on user choice
```

## Error Handling Strategy

### 1. Dialog Display Errors
- Fallback to safe exercise selection if dialog fails to display
- Log errors for debugging while maintaining user experience
- Provide clear error messages if dialog interaction fails

### 2. User Cancellation
- Return null from exercise generation function
- Show appropriate error message in plan generation UI
- Allow user to return to assessment to modify muscle injury data

### 3. Network/Storage Issues
- Maintain local state during dialog interaction
- Persist user choices locally before attempting cloud sync
- Graceful degradation if persistence fails

## Accessibility Considerations

### 1. Screen Reader Support
- Semantic labels for all dialog elements
- Clear announcement of dialog purpose and options
- Proper focus management during dialog interaction

### 2. Touch Accessibility
- Minimum 44px touch targets for all interactive elements
- Clear visual feedback for button states
- Support for keyboard navigation where applicable

### 3. Visual Accessibility
- High contrast text and button colors
- Clear visual hierarchy for dialog content
- Support for system font scaling

## Performance Considerations

### 1. Dialog Rendering
- Lazy loading of dialog content to avoid blocking main thread
- Efficient state management to prevent unnecessary rebuilds
- Minimal memory footprint for dialog components

### 2. Exercise Filtering
- Efficient re-filtering when user chooses "include all"
- Caching of filtered results to avoid redundant processing
- Background processing for large exercise datasets

## Security and Privacy

### 1. User Consent Tracking
- Log user choices for safety monitoring and analytics
- Maintain consent records for healthcare compliance
- Clear data retention policies for user choices

### 2. Data Protection
- No sensitive health data exposed in dialog logs
- Secure handling of user choice data
- Compliance with healthcare data protection standards

## Testing Strategy

### 1. Unit Testing
- Dialog service method testing
- Exercise filtering logic validation
- User choice handling verification

### 2. Integration Testing
- End-to-end dialog flow testing
- Exercise generation integration validation
- Navigation flow testing

### 3. User Acceptance Testing
- Safety communication effectiveness
- User choice clarity and usability
- Accessibility compliance validation

## Future Considerations

### 1. Enhanced Safety Features
- Integration with healthcare provider systems
- Advanced pain monitoring recommendations
- Personalized safety thresholds based on user history

### 2. Improved User Experience
- Progressive disclosure of safety information
- Contextual help and guidance
- Personalized recommendations based on user preferences

### 3. Analytics and Monitoring
- User choice pattern analysis
- Safety outcome tracking
- Exercise effectiveness correlation with user choices
