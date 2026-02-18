# Directory Fallback Fix for Model Loading

## Issue
Error: `Unsupported operation: _Namespace` when trying to use `Directory.systemTemp` as fallback.

## Root Cause
The `path_provider` plugin may not be properly initialized, and `Directory.systemTemp` may not be available on all platforms or in certain runtime environments.

## Solution Applied

### Multi-Level Fallback Strategy
1. **Primary**: `getTemporaryDirectory()` - Standard temp directory via path_provider
2. **Fallback 1**: `getApplicationDocumentsDirectory()` - App's documents directory
3. **Fallback 2**: `getApplicationSupportDirectory()` - App's support directory  
4. **Last Resort**: `Directory.systemTemp` - System temp (may fail on some platforms)

### Enhanced Error Handling
- Added directory existence check before writing
- Added file write error handling
- Added file verification after writing
- Added detailed logging at each step

## Files Modified

1. **`lib/data/facial_pain_recognition_service.dart`**:
   - Added multi-level fallback for directory selection
   - Added directory creation if it doesn't exist
   - Added file write error handling
   - Added file verification

2. **`lib/data/pose_model_manager.dart`**:
   - Same improvements as above

## Expected Behavior

### Success Path:
```
FacialPainRecognitionService: Loading ONNX model from assets...
FacialPainRecognitionService: Using application documents directory as fallback
FacialPainRecognitionService: ONNX model written to: /path/to/model.onnx
FacialPainRecognitionService: ✅ ONNX model copied to: /path/to/model.onnx (XXXX bytes)
```

### Failure Path (if all options fail):
```
FacialPainRecognitionService: ⚠️ getTemporaryDirectory failed: ...
FacialPainRecognitionService: ⚠️ getApplicationDocumentsDirectory failed: ...
FacialPainRecognitionService: ⚠️ getApplicationSupportDirectory failed: ...
FacialPainRecognitionService: ❌ All directory options failed
```

## Next Steps if Still Failing

If all directory options fail, consider:
1. **Check platform**: Ensure running on Android/iOS (not web)
2. **Rebuild app**: `flutter clean && flutter pub get && flutter run`
3. **Check permissions**: Ensure app has file system permissions
4. **Alternative**: Consider passing model bytes directly to native code (requires native code changes)




