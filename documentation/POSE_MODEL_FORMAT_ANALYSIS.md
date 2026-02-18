# Pose Estimation Model Format Analysis

## Current Implementation

### Model Format Used: **TORCHSCRIPT (.ptl - PyTorch Lite)**

The pose estimation model is using **PyTorch Mobile** with the **`.ptl` (PyTorch Lite)** format.

### Evidence:

1. **Code Reference** (`lib/data/pose_model_manager.dart`):
   - Line 94: `const modelAssetPath = 'assets/model/pose_model.ptl';`
   - Line 38: Uses `MethodChannel('com.pocketpt/pytorch')` - PyTorch Mobile channel
   - Line 155: `await _pytorchChannel.invokeMethod('initialize', ...)` - PyTorch Mobile initialization
   - Line 243: `await _pytorchChannel.invokeMethod('run', ...)` - PyTorch Mobile inference

2. **Native Code** (`android/app/src/main/kotlin/com/example/pocketpt/MainActivity.kt`):
   - Line 18: `private val PYTORCH_CHANNEL = "com.pocketpt/pytorch"`
   - Line 46-47: PyTorch Mobile method channel handler
   - Line 139-204: `handlePyTorchMethodCall` function handles PyTorch Mobile operations

3. **File System** (`assets/model/`):
   - ✅ `pose_model.ptl` (38MB) - **USED**
   - ❌ `pose_estimation_model.onnx` (38MB) - NOT used
   - ❌ `pose_estimation_model.pt` (19MB) - NOT used
   - ❌ `pose_estimation_model.torchscript` (38MB) - NOT used

## Model Format Comparison

| Format | File | Size | Status | Runtime |
|--------|------|------|--------|---------|
| **PyTorch Lite (.ptl)** | `pose_model.ptl` | 38MB | ✅ **USED** | PyTorch Mobile |
| ONNX | `pose_estimation_model.onnx` | 38MB | ❌ Not used | ONNX Runtime |
| PyTorch Checkpoint (.pt) | `pose_estimation_model.pt` | 19MB | ❌ Not used | N/A |
| TorchScript | `pose_estimation_model.torchscript` | 38MB | ❌ Not used | N/A |

## Implementation Details

### Model Loading Flow:
1. **Dart Code** (`pose_model_manager.dart`):
   - Loads `assets/model/pose_model.ptl` from assets
   - Copies to temporary directory
   - Initializes via PyTorch Mobile method channel

2. **Native Code** (`MainActivity.kt`):
   - Receives initialization request via `com.pocketpt/pytorch` channel
   - Loads `.ptl` file using PyTorch Mobile (`org.pytorch.Module.load()`)
   - Handles inference via `Module.forward()`

### Model Specifications:
- **Input**: 320x320 RGB images (NCHW format)
- **Output**: 17 COCO format keypoints [x, y, confidence]
- **Framework**: PyTorch Mobile (optimized for mobile)
- **Format**: `.ptl` (PyTorch Lite - mobile-optimized TorchScript)

## Why .ptl Instead of Other Formats?

1. **`.ptl` (PyTorch Lite)**:
   - ✅ Optimized for mobile deployment
   - ✅ Smaller file size (38MB vs 19MB .pt + overhead)
   - ✅ Better performance on mobile devices
   - ✅ Native PyTorch Mobile support

2. **`.onnx`**:
   - ❌ Requires ONNX Runtime (additional dependency)
   - ❌ May have compatibility issues
   - ❌ Not currently used in code

3. **`.pt` (PyTorch Checkpoint)**:
   - ❌ Not optimized for mobile
   - ❌ Requires full PyTorch runtime
   - ❌ Larger memory footprint

4. **`.torchscript`**:
   - ❌ Not optimized for mobile
   - ❌ Requires conversion to `.ptl` for mobile use

## Conclusion

**The pose estimation model uses TORCHSCRIPT format, specifically the `.ptl` (PyTorch Lite) variant, which is optimized for mobile deployment via PyTorch Mobile.**

The code does NOT use:
- ❌ `.pth` (PyTorch checkpoint)
- ❌ `.onnx` (ONNX format)
- ❌ `.onnx.data` (ONNX data file)
- ❌ `.torchscript` (standard TorchScript)

It ONLY uses:
- ✅ `.ptl` (PyTorch Lite - mobile-optimized TorchScript)




