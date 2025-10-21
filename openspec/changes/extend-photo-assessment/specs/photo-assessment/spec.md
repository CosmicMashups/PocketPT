# Photo-Based ROM Assessment Specification

## ADDED Requirements

### Photo Processing Pipeline

#### Scenario: User captures photo for assessment
**Given** a user is on the upload screen and has selected a specific muscle group
**When** the user taps "Take Photo" and captures an image
**Then** the system should automatically process the photo with pose detection and muscle assessment
**And** display the results on a preview page with pose skeleton overlay
**And** show the detected pain level with appropriate color coding

#### Scenario: User uploads photo from gallery
**Given** a user is on the upload screen and has selected a specific muscle group
**When** the user taps "Upload from Gallery" and selects an existing photo
**Then** the system should automatically process the photo with pose detection and muscle assessment
**And** display the results on a preview page with pose skeleton overlay
**And** show the detected pain level with appropriate color coding

#### Scenario: Photo processing with pose detection
**Given** a captured or uploaded photo is available
**When** the system processes the photo for assessment
**Then** it should use the existing PoseDetectionService to detect poses
**And** extract landmarks using the same methodology as camera assessment
**And** apply the appropriate muscle assessment algorithm based on UserAssess.specificMuscle
**And** return an AssessmentResult with pain level and confidence scores

### Photo Preview Interface

#### Scenario: Display photo with pose skeleton overlay
**Given** a photo has been processed with pose detection
**When** the preview page is displayed
**Then** it should show the original photo with pose skeleton overlay
**And** display the detected pain level with color coding (Low/Moderate/Severe)
**And** show assessment confidence and additional details
**And** provide action buttons for user interaction

#### Scenario: User reviews assessment results
**Given** a photo preview page is displayed with assessment results
**When** the user reviews the results
**Then** they should see clear pain level indication with appropriate colors
**And** be able to view assessment confidence scores
**And** have options to retake/reselect photo, proceed, or adjust pain level

#### Scenario: User takes action on preview page
**Given** a photo preview page is displayed
**When** the user selects an action
**Then** "Retake Photo" should return to camera for new capture
**And** "Select Different Photo" should return to gallery selection
**And** "Proceed" should navigate to pain level screen with detected values
**And** "Adjust Pain Level" should allow manual pain level modification

### Integration with Existing System

#### Scenario: Seamless integration with assessment workflow
**Given** the photo assessment system is implemented
**When** a user completes photo assessment
**Then** the detected pain level should update UserAssess.painScale
**And** the assessment should integrate seamlessly with the existing assessment flow
**And** navigation should maintain consistency with camera assessment workflow

#### Scenario: Muscle assessment algorithm consistency
**Given** a user has selected a specific muscle group in previous screens
**When** photo assessment is performed
**Then** the system should use the same muscle-to-algorithm mapping as camera assessment
**And** apply the appropriate assessment algorithm for the selected muscle
**And** maintain consistency with real-time camera assessment results

## MODIFIED Requirements

### Enhanced Upload Functionality

#### Scenario: Extended photo capture with pose detection
**Given** the existing photo capture functionality
**When** a photo is captured
**Then** instead of showing basic success message, it should process the photo with pose detection
**And** navigate to the preview page with assessment results
**And** provide loading indicators during processing

#### Scenario: Enhanced gallery upload with assessment
**Given** the existing gallery upload functionality
**When** a photo is selected from gallery
**Then** instead of showing basic success message, it should process the photo with pose detection
**And** navigate to the preview page with assessment results
**And** provide loading indicators during processing

### Extended Pose Detection Service

#### Scenario: Image file processing optimization
**Given** the existing PoseDetectionService
**When** processing static image files for assessment
**Then** it should provide enhanced error handling for photo-specific scenarios
**And** validate image quality before processing
**And** return confidence scores for pose detection results

## Error Handling and Edge Cases

### Pose Detection Failures

#### Scenario: No poses detected in photo
**Given** a photo is processed for pose detection
**When** no poses are detected in the image
**Then** the system should display an error message
**And** provide option to retake or select different photo
**And** suggest better positioning or lighting

#### Scenario: Poor image quality
**Given** a photo with poor quality is processed
**When** pose detection fails due to image quality
**Then** the system should warn the user about image quality issues
**And** provide suggestions for better lighting or positioning
**And** offer option to retake photo

#### Scenario: Multiple poses detected
**Given** a photo with multiple people is processed
**When** multiple poses are detected
**Then** the system should use the most confident pose detection
**And** warn the user about multiple people in the image
**And** suggest taking a photo with only the subject

### Assessment Failures

#### Scenario: Invalid landmarks for assessment
**Given** pose detection returns insufficient landmarks
**When** muscle assessment is attempted
**Then** the system should fallback to manual pain level selection
**And** inform the user about incomplete pose detection
**And** allow manual pain level adjustment

#### Scenario: Unsupported muscle group
**Given** an unsupported muscle group is selected
**When** photo assessment is performed
**Then** the system should use the default assessment algorithm
**And** warn the user about unsupported muscle group
**And** proceed with assessment using fallback algorithm

### Performance and Reliability

#### Scenario: Large image processing
**Given** a large image file is selected for processing
**When** the system processes the image
**Then** it should show loading indicators during processing
**And** optimize image size for processing
**And** handle memory management appropriately

#### Scenario: Processing timeout
**Given** photo processing takes longer than expected
**When** processing exceeds timeout threshold
**Then** the system should show timeout error message
**And** provide option to retry processing
**And** offer fallback to manual pain level selection

## User Experience Requirements

### Professional Healthcare Styling

#### Scenario: Consistent healthcare design
**Given** the photo assessment interface
**When** users interact with the system
**Then** it should maintain professional healthcare styling
**And** use consistent color scheme with existing assessment screens
**And** apply appropriate typography and spacing

### Accessibility and Usability

#### Scenario: Accessible interface design
**Given** the photo preview interface
**When** users with accessibility needs interact with the system
**Then** it should provide proper contrast ratios
**And** include appropriate labels and descriptions
**And** support screen reader compatibility

#### Scenario: Responsive design
**Given** the photo assessment interface
**When** used on different screen sizes and orientations
**Then** it should adapt appropriately to screen dimensions
**And** maintain usability across different devices
**And** preserve functionality in both portrait and landscape modes

### Loading States and Feedback

#### Scenario: Processing feedback
**Given** photo processing is in progress
**When** users wait for processing completion
**Then** the system should show clear loading indicators
**And** provide progress feedback when possible
**And** display appropriate messages for different processing stages

#### Scenario: Error feedback
**Given** an error occurs during photo processing
**When** the system encounters an error
**Then** it should display clear error messages
**And** provide specific guidance for resolution
**And** offer appropriate recovery options
