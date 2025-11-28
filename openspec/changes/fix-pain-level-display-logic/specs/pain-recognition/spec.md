# Pain Recognition Capability

## MODIFIED Requirements

### Requirement: Real-Time Pain Level Display
The system SHALL display actual pain level values (0-10 scale) from model inference or AROM assessment, not hardcoded fallback values.

#### Scenario: Pain level updates from model output
- **WHEN** the facial pain recognition model produces a prediction
- **THEN** the pain level display updates to show the actual model output
- **AND** the displayed value reflects the model's confidence and prediction
- **AND** the value changes as facial expressions change

#### Scenario: Pain level uses AROM assessment as primary source
- **WHEN** both AROM assessment and facial recognition are available
- **THEN** the pain level display uses AROM assessment `painScore` (0-10) as primary source
- **AND** facial recognition provides supplementary categorical indicator
- **AND** the displayed value reflects actual assessment results

#### Scenario: No hardcoded fallback values
- **WHEN** model inference fails or is unavailable
- **THEN** the system SHALL NOT display hardcoded "2/10" value
- **AND** SHALL display "N/A" or last known valid value
- **AND** SHALL log error indicating model unavailability

### Requirement: Model Output Integration
The system SHALL ensure facial pain recognition model output correctly updates the UI pain level display.

#### Scenario: Model output reaches UI
- **WHEN** model inference completes successfully
- **THEN** `_currentPainLevel` is updated with model prediction
- **AND** UI display reflects the updated value
- **AND** state changes trigger UI rebuilds

#### Scenario: Model execution verification
- **WHEN** camera frames are processed
- **THEN** model inference function is called
- **AND** model output is logged for debugging
- **AND** output values vary based on input

### Requirement: Pain Level Mapping Logic
The system SHALL use dynamic pain level calculation based on model output and confidence, not static mappings.

#### Scenario: Dynamic pain scale calculation
- **WHEN** model provides categorical pain level and confidence
- **THEN** pain scale (0-10) is calculated using confidence-weighted mapping
- **AND** calculation reflects model certainty
- **AND** values are not hardcoded to fixed numbers

#### Scenario: AROM assessment integration
- **WHEN** AROM assessment provides `painScore`
- **THEN** pain level display uses AROM `painScore` directly
- **AND** facial recognition provides categorical label for context
- **AND** both sources are combined for comprehensive assessment

## ADDED Requirements

### Requirement: PyTorch Model Mobile Integration
The system SHALL properly integrate the PyTorch model file (`pain_recognition_model.pth`) for mobile deployment, following the same pattern as pose estimation model integration.

#### Scenario: Model file conversion
- **WHEN** PyTorch model needs to be deployed to mobile
- **THEN** model is converted to mobile-compatible format (ONNX or TorchScript)
- **AND** conversion handles mobile constraints (ops compatibility, quantization)
- **AND** exported model loads without exceptions

#### Scenario: Model loading verification
- **WHEN** pain recognition service initializes
- **THEN** PyTorch model file is loaded successfully
- **AND** model structure matches expected architecture
- **AND** model is ready for inference

### Requirement: Diagnostic Logging for Pain Level
The system SHALL provide comprehensive logging to diagnose pain level display issues.

#### Scenario: Model execution logging
- **WHEN** model inference is performed
- **THEN** logs show model input preparation
- **AND** logs show model output values
- **AND** logs show pain level calculation steps
- **AND** logs show UI update triggers

#### Scenario: Error diagnosis
- **WHEN** pain level display shows incorrect value
- **THEN** logs provide sufficient information to identify the issue
- **AND** logs show whether model is running
- **AND** logs show whether output is being parsed correctly





