# PyTorch Mobile Multi-Model Support Fix

## Problem
After integrating the pain recognition model to use PyTorch Mobile, pose estimation stopped working in `c_camera.dart`. Both models were using the same PyTorch Mobile method channel (`com.pocketpt/pytorch`), but `MainActivity.kt` only stored a single `pytorchModule` variable. When the pain recognition service initialized, it overwrote the pose estimation model.

## Root Cause
- Both `PoseModelManager` and `FacialPainRecognitionService` use the same method channel: `com.pocketpt/pytorch`
- Native code (`MainActivity.kt`) had only one `pytorchModule: Module?` variable
- Second model initialization overwrote the first model, causing inference to use the wrong model

## Solution
Modified the native code to support multiple PyTorch models simultaneously by:
1. Changing from single variable to a Map: `pytorchModules: MutableMap<String, Module>`
2. Using model file path as the unique key to identify each model
3. Updating all method channel calls to include `modelPath` parameter

## Changes Made

### 1. Android Native Code (`MainActivity.kt`)
- **Changed:** `private var pytorchModule: Module? = null`
- **To:** `private val pytorchModules: MutableMap<String, Module> = mutableMapOf()`
- **Updated `initialize` method:** Stores models in map with model path as key
- **Updated `run` method:** Requires `modelPath` parameter to identify which model to use
- **Updated `dispose` method:** Can dispose specific model by path, or all models

### 2. Pose Model Manager (`lib/data/pose_model_manager.dart`)
- Updated all `invokeMethod('run')` calls to include `'modelPath': _modelPath`
- Updated `dispose()` to pass model path when disposing
- Updated test inference verification to include model path

### 3. Pain Recognition Service (`lib/data/facial_pain_recognition_service.dart`)
- Updated all `invokeMethod('run')` calls to include `'modelPath': _modelPath`
- Updated `dispose()` to pass model path when disposing
- Updated test inference verification to include model path

## Technical Details

### Model Storage
```kotlin
// Before (single model - conflicts)
private var pytorchModule: Module? = null

// After (multiple models - no conflicts)
private val pytorchModules: MutableMap<String, Module> = mutableMapOf()
```

### Model Identification
- Models are identified by their file path (e.g., `/data/user/0/.../pose_model.ptl`)
- Each service stores its model path in `_modelPath` variable
- Path is passed in all method channel calls to ensure correct model is used

### Initialization Flow
1. Pose service initializes → loads `pose_model.ptl` → stored in map with its path as key
2. Pain service initializes → loads `pain_recognition_model.ptl` → stored in map with its path as key
3. Both models can now coexist in memory

### Inference Flow
1. Service calls `invokeMethod('run', { 'modelPath': _modelPath, 'input': ..., 'inputShape': ... })`
2. Native code looks up model in map using `modelPath` as key
3. Runs inference on correct model
4. Returns results to Dart

## Benefits
- ✅ Both models can run simultaneously
- ✅ No model conflicts or overwrites
- ✅ Proper cleanup (models disposed independently)
- ✅ Backward compatible (if no modelPath provided in dispose, clears all models)

## Testing Checklist
- [ ] Pose estimation works in `c_camera.dart`
- [ ] Pain recognition works in `c_camera.dart`
- [ ] Both models work simultaneously
- [ ] Models can be disposed independently
- [ ] No memory leaks (models properly cleaned up)




