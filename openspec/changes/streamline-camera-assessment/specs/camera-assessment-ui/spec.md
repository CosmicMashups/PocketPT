# Camera Assessment UI Capability

## Overview

The camera assessment UI capability provides an enhanced interface for ROM assessments using automatic muscle detection and comprehensive user guidance. This system eliminates manual muscle selection redundancy and provides professional healthcare-focused user experience.

## MODIFIED Requirements

### Requirement: Automatic Muscle Detection
The camera assessment interface SHALL automatically determine the assessment algorithm based on the user's previously selected muscle group, eliminating the need for manual muscle selection during camera assessment.

#### Scenario: User navigates from muscle selection to camera assessment
- **WHEN** a user has selected a specific muscle in previous assessment screens
- **THEN** the camera assessment interface automatically uses the correct assessment algorithm
- **AND** no manual muscle selection dropdown is presented
- **AND** the selected muscle is prominently displayed in the interface

#### Scenario: Unknown or empty muscle selection
- **WHEN** `UserAssess.specificMuscle` is empty or contains an unknown muscle group
- **THEN** the system falls back to a default assessment algorithm (triceps)
- **AND** displays a warning to the user about the fallback
- **AND** provides guidance for resolving the issue

#### Scenario: Muscle-to-algorithm mapping
- **WHEN** the system needs to determine the assessment algorithm
- **THEN** it maps the selected muscle to the appropriate AROM assessment algorithm
- **AND** supports all muscle groups: Deltoids, Biceps, Triceps, Cervical Muscle, Quadriceps, Hamstrings, Calf, Ankle, Gluteals, Abdominals, Obliques, Lower Back, Multifidus
- **AND** uses existing AssessmentService for algorithm execution

### Requirement: Enhanced User Interface Design
The camera assessment interface SHALL provide a professional healthcare-focused design with improved visual hierarchy and user guidance.

#### Scenario: Professional app bar design
- **WHEN** the camera assessment interface loads
- **THEN** the app bar displays the selected muscle prominently in the title
- **AND** uses professional healthcare color scheme (#8B2E2E primary, #C24A4A secondary)
- **AND** maintains side selection dropdown functionality
- **AND** includes a help button for user guidance

#### Scenario: Enhanced camera preview
- **WHEN** the camera preview is displayed
- **THEN** it features improved rounded corners and professional styling
- **AND** maintains skeleton overlay toggle functionality
- **AND** provides better positioned assessment results panel
- **AND** includes enhanced status indicators with improved contrast

#### Scenario: Improved layout hierarchy
- **WHEN** the interface is rendered
- **THEN** it follows a clear visual hierarchy with consistent spacing
- **AND** uses Poppins font for headers and PT Sans for body text
- **AND** maintains consistent 16px margins and 12px padding
- **AND** provides clear separation between interface sections

### Requirement: Comprehensive Help System
The camera assessment interface SHALL provide comprehensive help functionality with muscle-specific guidance and troubleshooting.

#### Scenario: Help button access
- **WHEN** a user needs guidance during assessment
- **THEN** they can access help via a prominent help button in the app bar
- **AND** the help dialog opens with muscle-specific content
- **AND** the dialog is responsive and accessible

#### Scenario: Muscle-specific help content
- **WHEN** the help dialog is opened
- **THEN** it displays detailed instructions for the selected muscle group
- **AND** includes step-by-step positioning guidance
- **AND** provides troubleshooting tips for common issues
- **AND** shows visual aids and illustrations where helpful

#### Scenario: Help content organization
- **WHEN** help content is displayed
- **THEN** it is organized into clear sections: Overview, Instructions, Positioning Tips, Troubleshooting
- **AND** content is specific to the selected muscle group and side
- **AND** instructions are detailed and actionable
- **AND** troubleshooting covers common user issues

## ADDED Requirements

### Requirement: Muscle-Specific Assessment Instructions
The system SHALL provide detailed, muscle-specific instructions that guide users through proper assessment positioning and movement.

#### Scenario: Detailed assessment instructions
- **WHEN** a user is performing an assessment for a specific muscle
- **THEN** they receive detailed instructions tailored to that muscle group
- **AND** instructions include proper positioning relative to the camera
- **AND** instructions specify the exact movements to perform
- **AND** instructions indicate what the system is measuring

#### Scenario: Positioning guidance
- **WHEN** help content is accessed
- **THEN** it provides specific guidance on how to position oneself for optimal assessment
- **AND** includes tips for maintaining proper posture during assessment
- **AND** explains how to ensure the camera captures the necessary landmarks
- **AND** provides guidance for different body sizes and flexibility levels

### Requirement: Enhanced Error Handling and User Feedback
The system SHALL provide clear feedback and error handling for assessment issues and user guidance.

#### Scenario: Assessment error feedback
- **WHEN** an assessment encounters an error or issue
- **THEN** the system provides clear, actionable feedback to the user
- **AND** explains what went wrong and how to resolve it
- **AND** maintains a professional, reassuring tone
- **AND** provides alternative approaches when possible

#### Scenario: Progress and status feedback
- **WHEN** an assessment is in progress
- **THEN** the system provides clear status indicators
- **AND** shows assessment progress when applicable
- **AND** indicates when the system is ready to capture data
- **AND** provides feedback on assessment quality and completeness

## REMOVED Requirements

### Requirement: Manual Muscle Selection Interface
The camera assessment interface SHALL NOT require manual muscle selection via dropdown menu, as this functionality is replaced by automatic detection.

#### Scenario: Removal of muscle selection dropdown
- **WHEN** the camera assessment interface loads
- **THEN** no muscle selection dropdown is presented
- **AND** the interface does not require user input for muscle selection
- **AND** the `_mode` state variable and related logic is removed
- **AND** the app bar layout is updated to remove the dropdown space

#### Scenario: Simplified user flow
- **WHEN** a user navigates to camera assessment
- **THEN** they proceed directly to assessment without additional muscle selection
- **AND** the assessment flow is streamlined and more intuitive
- **AND** the potential for user error in muscle selection is eliminated
