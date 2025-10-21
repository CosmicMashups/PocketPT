# Photo-Based ROM Assessment - Design Document

## Architecture Overview

The photo-based ROM assessment extends the existing camera assessment infrastructure to support static image processing while maintaining consistency with the current real-time assessment workflow.

## System Components

### 1. Extended Upload Module (`c_upload.dart`)

**Current State**: Basic photo capture and gallery selection with placeholder AI processing
**Target State**: Integrated pose detection and assessment pipeline

**Key Changes**:
- Integrate `PoseDetectionService.detectFromImageFile()` for photo processing
- Apply muscle assessment algorithms via `AssessmentService.assess()`
- Navigate to preview page instead of showing basic success messages
- Add loading states and error handling for photo processing

**Data Flow**:
```
Photo Capture/Upload → Pose Detection → Muscle Assessment → Preview Page
```

### 2. New Photo Preview Module (`c_preview.dart`)

**Purpose**: Display processed photos with pose skeleton overlay and assessment results

**Key Features**:
- Photo display with pose skeleton visualization
- Pain level indicator with color coding (Low/Moderate/Severe)
- Assessment confidence and details display
- User action controls (Retake, Proceed, Adjust)

**UI Components**:
- Photo viewer with skeleton overlay
- Assessment results panel
- Pain level indicator
- Action buttons with professional styling
- Loading states and error handling

### 3. Enhanced Pose Detection Service

**Current State**: Supports camera images and basic file processing
**Target State**: Optimized for photo assessment workflow

**Extensions**:
- Enhanced error handling for static images
- Image quality validation
- Performance optimization for photo processing
- Confidence scoring for pose detection results

## Data Flow Architecture

### Photo Processing Pipeline

```
1. Photo Capture/Upload (c_upload.dart)
   ↓
2. Image Validation & Preprocessing
   ↓
3. Pose Detection (PoseDetectionService)
   ↓
4. Landmark Extraction & Validation
   ↓
5. Muscle Assessment (AssessmentService)
   ↓
6. Pain Level Categorization
   ↓
7. Preview Display (c_preview.dart)
   ↓
8. User Confirmation/Adjustment
   ↓
9. Proceed to Pain Level (c_painlevel.dart)
```

### State Management

**Key State Variables**:
- `File photoFile`: Captured or uploaded photo
- `AssessmentResult assessmentResult`: Pose detection and muscle assessment results
- `String muscleGroup`: Selected muscle from previous assessment screens
- `String side`: Assessment side (Left/Right)
- `bool isProcessing`: Loading state for photo processing

**Data Persistence**:
- `UserAssess.specificMuscle`: Determines assessment algorithm
- `UserAssess.painScale`: Updated with detected pain level
- `AssessmentResult`: Contains pose data and pain assessment

## UI/UX Design Principles

### Professional Healthcare Styling

**Color Scheme**:
- Primary: `Color(0xFF8B2E2E)` (Healthcare Red)
- Success: `Color(0xFF10B981)` (Green for Low Pain)
- Warning: `Color(0xFFF59E0B)` (Orange for Moderate Pain)
- Error: `Color(0xFFEF4444)` (Red for Severe Pain)

**Typography**:
- Headers: Poppins (FontWeight.w700)
- Body: PT Sans (FontWeight.w500)
- Consistent with existing assessment screens

### User Experience Flow

**Photo Capture Flow**:
1. User taps "Take Photo" → Camera opens
2. User captures photo → Automatic processing begins
3. Loading indicator shown → Pose detection and assessment
4. Preview page displayed → User reviews results
5. User chooses action → Retake, Proceed, or Adjust

**Gallery Upload Flow**:
1. User taps "Upload from Gallery" → Gallery opens
2. User selects photo → Automatic processing begins
3. Loading indicator shown → Pose detection and assessment
4. Preview page displayed → User reviews results
5. User chooses action → Reselect, Proceed, or Adjust

### Error Handling Strategy

**Pose Detection Failures**:
- No poses detected: Show error message with retake option
- Poor image quality: Suggest better lighting/positioning
- Multiple poses: Use most confident detection
- Partial poses: Warn about incomplete assessment

**Assessment Failures**:
- Invalid landmarks: Fallback to manual pain level selection
- Unsupported muscle: Use default assessment algorithm
- Low confidence: Allow user to override results

## Performance Considerations

### Image Processing Optimization

**Memory Management**:
- Dispose of large images after processing
- Implement image compression before processing
- Use efficient image loading and caching

**Processing Performance**:
- Async processing with loading indicators
- Throttle processing to prevent UI blocking
- Cache pose detection results when possible

**User Experience**:
- Show progress indicators during processing
- Provide clear error messages and recovery options
- Optimize for mobile devices and low-end hardware

## Integration Points

### Existing System Integration

**Pose Detection Service**:
- Reuse `PoseDetectionService.detectFromImageFile()`
- Extend error handling for photo-specific scenarios
- Maintain compatibility with camera-based detection

**Assessment Service**:
- Leverage existing `AssessmentService.assess()` method
- Use current muscle-to-algorithm mapping
- Maintain consistency with camera assessment results

**Data Flow**:
- Integrate with `UserAssess.specificMuscle` selection
- Update `UserAssess.painScale` with detected levels
- Maintain assessment workflow continuity

### Navigation Integration

**Screen Transitions**:
- Consistent with existing assessment flow animations
- Professional slide transitions between screens
- Proper back navigation and state management

**Data Passing**:
- Pass photo file and assessment results to preview
- Maintain assessment context across screens
- Ensure proper cleanup and disposal

## Security and Privacy Considerations

### Image Handling

**Temporary Storage**:
- Store photos temporarily during processing
- Dispose of images after assessment completion
- Avoid persistent storage of sensitive health images

**Data Privacy**:
- Process images locally on device
- No cloud storage of assessment images
- Clear user consent for photo processing

### Error Handling

**Graceful Degradation**:
- Fallback to manual pain level selection
- Clear error messages for processing failures
- Maintain app functionality even with processing errors

## Testing Strategy

### Unit Testing

**Photo Processing**:
- Test pose detection with various image qualities
- Validate muscle assessment algorithm consistency
- Test error handling for edge cases

**UI Components**:
- Test preview interface functionality
- Validate user interaction flows
- Test responsive design across screen sizes

### Integration Testing

**End-to-End Workflows**:
- Test complete photo assessment workflow
- Validate data flow and state management
- Test navigation and screen transitions

**Performance Testing**:
- Test with various image sizes and formats
- Validate memory usage and cleanup
- Test on low-end devices

### User Experience Testing

**Usability Testing**:
- Test interface intuitiveness
- Validate error message clarity
- Test accessibility features

**Professional Standards**:
- Ensure healthcare-appropriate styling
- Validate professional user experience
- Test with healthcare professionals

## Future Considerations

### Potential Extensions

**Video Assessment**:
- Framework supports future video upload assessment
- Consistent architecture for video processing
- Reusable components for video preview interface

**Enhanced AI Integration**:
- Future integration with additional AI models
- Extensible architecture for new assessment algorithms
- Support for continuous learning and improvement

### Scalability

**Performance Scaling**:
- Architecture supports future performance optimizations
- Modular design allows for component upgrades
- Extensible error handling and recovery mechanisms

**Feature Scaling**:
- Design supports additional assessment types
- Flexible UI components for future enhancements
- Consistent data flow for new features
