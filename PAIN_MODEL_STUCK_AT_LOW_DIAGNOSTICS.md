# Pain Model Stuck at "Low" - Diagnostic Guide

## Issue
The pain recognition model is stuck displaying "Low" even though it works fine in Python.

## Possible Issues Identified

### 1. **Model File Loading**
- ✅ Model file name: `pain_recognition_model.onnx` (correct)
- ✅ Asset path: `assets/model/pain_recognition_model.onnx` (correct)
- ⚠️ Check: Model file size should be ~26KB (ONNX) + ~101MB (data file)

### 2. **Preprocessing Mismatch**
- ✅ Normalization: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225] (matches Python)
- ✅ Input size: 224x224 (matches Python)
- ✅ Channel order: NCHW (channel first) (matches PyTorch)
- ⚠️ **Potential Issue**: Face extraction may be providing constant input

### 3. **Face Extraction**
- ⚠️ **Current**: Uses center crop (simplified approach)
- ⚠️ **Issue**: If face is not centered, model gets wrong region
- ⚠️ **Issue**: If crop is always the same, model gets constant input
- **Fix**: Added diagnostic logging to detect constant input

### 4. **Model Output Parsing**
- ✅ Logits extraction: Correct
- ✅ Softmax: Correct implementation
- ✅ Argmax: Correct
- ✅ Class mapping: 0=Low, 1=Moderate, 2=Severe (correct)

### 5. **Model Inference**
- ⚠️ **Potential Issue**: Model may not be running (ONNX Runtime not initialized)
- ⚠️ **Potential Issue**: Model may be returning cached/stale values
- ⚠️ **Potential Issue**: Model output may be constant (all logits same)

## Diagnostic Logging Added

### 1. **Preprocessing Diagnostics**
- Logs preprocessed input samples (start, mid, end)
- Detects if input is all zeros
- Detects if input is constant (all same values)
- Logs min/max values to verify input varies

### 2. **Model Output Diagnostics**
- Logs raw logits from model
- Detects if all logits are identical (stuck model)
- Logs probabilities after softmax
- Detects if all probabilities are identical

### 3. **Prediction Diagnostics**
- Logs predicted class index and label
- Warns if consistently predicting Low with high confidence
- Suggests possible causes when stuck at Low

### 4. **Face Extraction Diagnostics**
- Logs image dimensions before extraction
- Logs crop coordinates and size
- Logs resized face dimensions

## How to Debug

### Step 1: Check Logs for Model Initialization
Look for:
```
FacialPainRecognitionService: ✅ ONNX Runtime session initialized successfully
FacialPainRecognitionService: ✅ ONNX Runtime verification successful
```

### Step 2: Check Logs for Preprocessing
Look for:
```
FacialPainRecognitionService: ✅ Preprocessed input varies: min=X.XXX, max=Y.YYY
```
If you see:
```
⚠️ DIAGNOSTIC - Preprocessed input is constant
```
→ **Issue**: Face extraction is providing constant input

### Step 3: Check Logs for Model Output
Look for:
```
FacialPainRecognitionService: Extracted logits: [X.XXX, Y.YYY, Z.ZZZ]
FacialPainRecognitionService: Probabilities: [X.XXX, Y.YYY, Z.ZZZ]
```
If you see:
```
⚠️ WARNING - All logits are nearly identical!
⚠️ WARNING - All probabilities are nearly identical!
```
→ **Issue**: Model is stuck or receiving constant input

### Step 4: Check Logs for Prediction
Look for:
```
FacialPainRecognitionService: ✅ REAL-TIME model prediction - Pain: [Low/Moderate/Severe]
```
If you see:
```
⚠️ DIAGNOSTIC - Model consistently predicting Low with high confidence
```
→ **Issue**: Model is stuck at Low (check preprocessing and input)

## Possible Fixes

### Fix 1: Face Detection
**Problem**: Center crop may not capture face correctly
**Solution**: Implement proper face detection (ML Kit, MediaPipe, or OpenCV)

### Fix 2: Input Variation
**Problem**: Preprocessed input is constant
**Solution**: 
- Verify camera is providing different frames
- Check face extraction is working correctly
- Verify preprocessing is not zeroing out values

### Fix 3: Model Loading
**Problem**: Wrong model file or model not loaded
**Solution**:
- Verify `pain_recognition_model.onnx` exists in assets
- Check model file size matches expected
- Verify ONNX Runtime initialization succeeds

### Fix 4: Normalization
**Problem**: Normalization values incorrect
**Solution**: Already correct, but verify they match Python training

### Fix 5: Channel Order
**Problem**: RGB vs BGR mismatch
**Solution**: Already using RGB (correct), but verify pixel extraction

## Next Steps

1. **Run the app and check logs** for diagnostic messages
2. **Identify which diagnostic fails** (preprocessing, model output, or prediction)
3. **Apply appropriate fix** based on diagnostic results
4. **Test with different facial expressions** to verify model responds

## Expected Behavior

When working correctly, you should see:
- Preprocessed input varies between frames
- Logits vary between frames
- Probabilities vary between frames
- Predicted class changes based on facial expression
- Display shows "Low", "Moderate", or "Severe" based on model output




