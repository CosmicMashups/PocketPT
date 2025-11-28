# Pain Recognition Capability

## ADDED Requirements

### Requirement: Real-Time Pain Level Detection
The system SHALL detect facial pain levels in real-time from camera input during assessments, updating the pain level and confidence values dynamically as facial expressions change.

#### Scenario: Pain level updates during assessment
- **WHEN** a user performs a ROM assessment with the camera active
- **THEN** the pain level indicator updates in real-time (at least every 200ms)
- **AND** the confidence value reflects the model's certainty
- **AND** the pain level changes when facial expressions change

#### Scenario: Pain level remains static (failure case)
- **WHEN** the pain recognition model is not functioning correctly
- **THEN** the system SHALL log diagnostic information
- **AND** SHALL display an error indicator to the user
- **AND** SHALL NOT return static/cached values without indication

## MODIFIED Requirements

### Requirement: Model Integration Alignment
The system SHALL align pain recognition model integration with the pose estimation integration patterns, ensuring consistent error handling, initialization, and diagnostic logging.

#### Scenario: Model initialization follows pose estimation pattern
- **WHEN** the pain recognition service initializes
- **THEN** it follows the same initialization pattern as pose estimation
- **AND** includes model verification on startup
- **AND** provides diagnostic logging similar to pose detection

#### Scenario: Error handling consistency
- **WHEN** the pain recognition model fails to initialize or run
- **THEN** error handling follows the same patterns as pose estimation
- **AND** errors are logged with sufficient detail for debugging
- **AND** user-visible error indicators are provided

## ADDED Requirements

### Requirement: Preprocessing Alignment with Training
The system SHALL preprocess input images using the exact same normalization values and procedures as the training script (`pain_train.py`).

#### Scenario: Normalization values match training
- **WHEN** an image is preprocessed for pain recognition
- **THEN** normalization uses mean=[0.485, 0.456, 0.406] and std=[0.229, 0.224, 0.225]
- **AND** image is resized to 224x224 pixels
- **AND** channel ordering is NCHW (batch, channels, height, width)

#### Scenario: Preprocessing validation
- **WHEN** preprocessing is performed
- **THEN** the system SHALL validate preprocessing output
- **AND** SHALL log preprocessing steps for debugging
- **AND** SHALL verify tensor shape matches model input requirements [1, 3, 224, 224]

## MODIFIED Requirements

### Requirement: Output Parsing and Postprocessing
The system SHALL correctly parse model outputs (logits) and apply softmax to obtain probability distribution, then select the predicted class using argmax.

#### Scenario: Logits extraction and softmax
- **WHEN** the model returns output
- **THEN** the system extracts raw logits (3 values for 3 classes)
- **AND** applies softmax to convert logits to probabilities
- **AND** uses argmax to select predicted class (0=Low, 1=Moderate, 2=Severe)
- **AND** confidence is the probability of the predicted class

#### Scenario: Output validation
- **WHEN** model output is parsed
- **THEN** probabilities sum to approximately 1.0
- **AND** confidence value is between 0.0 and 1.0
- **AND** predicted class index is valid (0, 1, or 2)

## ADDED Requirements

### Requirement: Model Export and Format
The system SHALL provide a script to export the trained PyTorch model to ONNX format, ensuring the exported model matches the training architecture and produces correct outputs.

#### Scenario: Model export script exists
- **WHEN** a developer needs to export the pain recognition model
- **THEN** an export script (`export_pain_to_onnx.py`) is available
- **AND** the script exports ResNet18/EfficientNet model to ONNX format
- **AND** the exported model has input shape [1, 3, 224, 224] and output shape [1, 3]

#### Scenario: Exported model verification
- **WHEN** a model is exported
- **THEN** the export script verifies the model format
- **AND** tests the model with sample input
- **AND** validates output shape and value ranges

## MODIFIED Requirements

### Requirement: Method Channel Communication
The system SHALL correctly communicate with the native ONNX Runtime implementation via method channel, passing preprocessed input tensors and receiving model outputs.

#### Scenario: Method channel initialization
- **WHEN** the pain recognition service initializes
- **THEN** it establishes method channel connection (`com.pocketpt/onnxruntime-pain`)
- **AND** loads the ONNX model file from assets
- **AND** verifies model initialization with test inference

#### Scenario: Inference via method channel
- **WHEN** pain detection is performed
- **THEN** preprocessed input tensor is passed via method channel
- **AND** input shape [1, 3, 224, 224] is correctly specified
- **AND** output is received as List<double> with 3 logit values
- **AND** errors are handled gracefully with appropriate logging

## MODIFIED Requirements

### Requirement: Frame Rate and Update Logic
The system SHALL process frames at a reasonable rate (approximately 5 FPS) while ensuring updates occur regularly and state changes trigger UI rebuilds.

#### Scenario: Frame rate limiting allows updates
- **WHEN** camera frames are received
- **THEN** frames are processed at approximately 5 FPS (every 200ms)
- **AND** frame rate limiting does not prevent all updates
- **AND** state updates trigger UI rebuilds to show new pain levels

#### Scenario: Update frequency validation
- **WHEN** pain recognition is active
- **THEN** pain level updates occur at least every 500ms
- **AND** updates reflect actual model output changes
- **AND** cached/static values are not returned indefinitely

