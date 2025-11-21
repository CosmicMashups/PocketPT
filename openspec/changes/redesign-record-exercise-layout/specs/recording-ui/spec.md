## MODIFIED Requirements

### Requirement: Exercise Recording Page Layout and Design
The system SHALL display the exercise recording page with a camera-centered, simplified layout that prioritizes the camera feed, uses a dark red top bar consistent with other pages, and optimizes all UI elements for a 9:16 aspect ratio without requiring scrolling.

#### Scenario: Dark red top bar display
- **WHEN** user views the exercise recording page
- **THEN** the page SHALL display a dark red AppBar using `RecordingDesignSystem.primaryMedical` background color
- **AND** the AppBar SHALL display the exercise name as the title
- **AND** the AppBar SHALL include a back button in the leading position with proper styling
- **AND** the top bar design SHALL be consistent with warmup_stretching_page.dart and cooldown_stretching_page.dart

#### Scenario: Camera-centered layout
- **WHEN** user views the exercise recording page
- **THEN** the camera preview SHALL be the primary visual focus
- **AND** the camera widget SHALL be properly centered in the layout
- **AND** the camera preview SHALL not exceed 50% of the screen height
- **AND** the camera preview SHALL maintain a 9:16 aspect ratio
- **AND** the camera preview SHALL be clearly visible and prominent

#### Scenario: Pain overlay positioning
- **WHEN** user views the exercise recording page with pain detection enabled
- **THEN** the pain detection overlay SHALL be positioned at the top-right corner within the camera widget bounds
- **AND** the overlay SHALL NOT be positioned at the screen edge
- **AND** the overlay SHALL remain visible and functional
- **AND** the overlay SHALL not interfere with camera controls

#### Scenario: Camera toggle functionality
- **WHEN** user is on the exercise recording page
- **THEN** the system SHALL provide a camera toggle button in the camera preview area
- **AND** the toggle button SHALL allow switching between front and rear cameras
- **AND** the camera switch SHALL work seamlessly without losing recording state
- **AND** the system SHALL handle errors gracefully when only one camera is available
- **AND** the system SHALL show appropriate loading indicators during camera switch if needed

#### Scenario: Simplified control buttons
- **WHEN** user views the exercise recording page
- **THEN** the control buttons (Back, Pause, Proceed) SHALL display only an icon on the left and text on the right
- **AND** the buttons SHALL NOT contain decorative containers, extra icons, or unnecessary padding
- **AND** the buttons SHALL maintain gradient backgrounds and color coding for visual hierarchy
- **AND** the buttons SHALL have minimum touch target size of 44x44 pixels
- **AND** all button functionality (navigation, pause, proceed) SHALL remain unchanged

#### Scenario: DraggableScrollableSheet readability
- **WHEN** user views the exercise recording page
- **THEN** the DraggableScrollableSheet SHALL use text colors that provide proper contrast
- **AND** the text SHALL use `RecordingDesignSystem.getTextPrimaryColor(context)` for proper theme adaptation
- **AND** the background SHALL adapt based on theme (dark/light mode)
- **AND** the text SHALL have sufficient font weight for readability
- **AND** the contrast ratio SHALL meet WCAG AA standards (minimum 4.5:1 for normal text)

#### Scenario: 9:16 layout optimization
- **WHEN** user views the exercise recording page
- **THEN** all UI elements SHALL fit within the 9:16 aspect ratio layout
- **AND** the main content SHALL NOT require scrolling
- **AND** the spacing between elements SHALL be optimized using RecordingDesignSystem constants
- **AND** excessive padding and margins SHALL be removed
- **AND** the layout SHALL be responsive across different screen sizes

## ADDED Requirements

### Requirement: Camera Toggle During Exercise Recording
The system SHALL provide the ability to switch between front and rear cameras during exercise recording without interrupting the recording session.

#### Scenario: Camera toggle available
- **WHEN** user is recording an exercise
- **THEN** the system SHALL display a camera toggle button in the camera preview area
- **AND** the toggle button SHALL be easily accessible
- **AND** the toggle button SHALL use an appropriate camera switch icon

#### Scenario: Successful camera switch
- **WHEN** user taps the camera toggle button
- **THEN** the system SHALL switch to the alternate camera (front to rear or vice versa)
- **AND** the camera preview SHALL update smoothly
- **AND** the recording state SHALL be preserved
- **AND** pain detection SHALL continue to function with the new camera

#### Scenario: Camera switch with single camera device
- **WHEN** user attempts to toggle camera on a device with only one camera
- **THEN** the system SHALL handle the error gracefully
- **AND** the system SHALL either hide the toggle button or show an appropriate message
- **AND** the exercise recording SHALL continue without interruption

#### Scenario: Camera switch initialization error
- **WHEN** camera switch fails due to initialization error
- **THEN** the system SHALL display an appropriate error message
- **AND** the system SHALL revert to the previous camera
- **AND** the exercise recording SHALL continue with the previous camera

### Requirement: Simplified Button Design for Exercise Recording
The system SHALL display simplified control buttons on the exercise recording page that contain only essential elements (icon and text) to optimize screen space and reduce visual clutter.

#### Scenario: Simplified button layout
- **WHEN** user views the exercise recording page
- **THEN** each control button SHALL display a single icon on the left
- **AND** each control button SHALL display text label on the right
- **AND** the buttons SHALL NOT contain decorative elements beyond gradients and borders
- **AND** the buttons SHALL use efficient spacing to minimize horizontal space usage

#### Scenario: Button functionality preservation
- **WHEN** user interacts with simplified control buttons
- **THEN** all button functionality SHALL remain unchanged
- **AND** navigation (back, proceed) SHALL work as expected
- **AND** pause/resume functionality SHALL work as expected
- **AND** button accessibility (screen readers, keyboard navigation) SHALL be maintained















