## ADDED Requirements

### Requirement: PyTorch Mobile Pain Recognition Model Integration
The system SHALL use PyTorch Mobile for pain recognition model inference, converting the trained PyTorch model (`pain_recognition_model.pth`) to PyTorch Lite format (`.ptl`) and deploying it through the existing PyTorch Mobile method channel infrastructure.

#### Scenario: Model Conversion and Asset Management
- **WHEN** the pain recognition model needs to be converted from `.pth` to `.ptl` format
- **THEN** the conversion script uses `torch.jit.script()` or `torch.jit.trace()` with proper input shape (1, 3, 224, 224)
- **AND** applies `torch.utils.mobile_optimizer.optimize_for_mobile()` to create optimized `.ptl` file
- **AND** the converted model is placed in `assets/model/pain_recognition_model.ptl`
- **AND** the asset is registered in `pubspec.yaml`

#### Scenario: Service Initialization
- **WHEN** the pain recognition service initializes
- **THEN** the service loads `pain_recognition_model.ptl` from assets
- **AND** copies the model file to a temporary directory
- **AND** initializes PyTorch Mobile module via `com.pocketpt/pytorch` method channel
- **AND** verifies initialization with a test inference
- **AND** the service reports initialization status and any errors

#### Scenario: Image Preprocessing
- **WHEN** a camera image is processed for pain recognition
- **THEN** the image is resized to 224x224 pixels (maintaining aspect ratio with appropriate padding/cropping)
- **AND** normalized using ImageNet statistics: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
- **AND** converted to NCHW format (batch=1, channels=3, height=224, width=224) as Float32 tensor
- **AND** preprocessing matches exactly the training pipeline from `pain_train.py`

#### Scenario: Model Inference
- **WHEN** a preprocessed image tensor is passed to the pain recognition model
- **THEN** the service invokes PyTorch Mobile inference via method channel
- **AND** the model returns logits for 3 classes (Low, Moderate, Severe)
- **AND** the service applies softmax to convert logits to probabilities
- **AND** the predicted class is determined using argmax
- **AND** the confidence is the probability of the predicted class
- **AND** the result is mapped to pain level labels: ['Low', 'Moderate', 'Severe']

#### Scenario: Error Handling
- **WHEN** model initialization fails
- **THEN** the service logs the error with detailed information
- **AND** returns an error state indicating initialization failure
- **WHEN** inference fails during runtime
- **THEN** the service returns the last known valid prediction (if available)
- **AND** logs the error without crashing the application
- **AND** the UI gracefully handles error states

#### Scenario: Performance Optimization
- **WHEN** processing camera frames for pain recognition
- **THEN** frame rate is limited to 5 FPS to manage performance
- **AND** skipped frames return cached prediction results
- **AND** inference timeouts are handled gracefully (5 second timeout)

## MODIFIED Requirements

### Requirement: Facial Pain Recognition Service Model Backend
The facial pain recognition service SHALL use PyTorch Mobile for model inference instead of ONNX Runtime, while maintaining the same external API and behavior.

#### Scenario: Backend Migration
- **WHEN** the service is initialized
- **THEN** it attempts to load the PyTorch Mobile model (`.ptl` format)
- **AND** uses the `com.pocketpt/pytorch` method channel for inference
- **AND** maintains backward compatibility with existing callers
- **AND** provides the same pain level predictions (Low, Moderate, Severe) with confidence scores




