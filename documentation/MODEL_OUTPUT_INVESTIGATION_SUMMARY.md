# Pain Recognition Model Output Investigation

## Problem
The pain recognition model appears to be stuck on "Low" prediction. The user suspects the model might not be outputting text labels but something else (bounding boxes, numbers, etc.).

## Model Output Format Investigation

### Expected Output Format
Based on the training code (`pain_train.py`):
- **Model Architecture**: ResNet18 with custom classifier
- **Output Layer**: `nn.Linear(256, num_classes)` where `num_classes=3`
- **Output Shape**: `[batch_size, 3]` = `[1, 3]` for single image inference
- **Output Type**: **Logits** (raw scores before softmax)
  - Index 0 = Low pain
  - Index 1 = Moderate pain  
  - Index 2 = Severe pain

### Data Flow
1. **Model Forward Pass**: Returns logits tensor shape `[1, 3]`
2. **PyTorch Mobile (Kotlin)**: 
   - Receives tensor from `module.forward()`
   - Flattens using `dataAsFloatArray` → produces FloatArray of 3 values
   - Converts to List<Double> and returns to Dart
3. **Dart Service**:
   - Receives List<double> with 3 values (logits)
   - Applies softmax to convert logits → probabilities
   - Uses argmax to get predicted class index (0, 1, or 2)
   - Maps index to label: ['Low', 'Moderate', 'Severe']

## Changes Made

### 1. Enhanced Native (Kotlin) Logging
Added comprehensive logging in `MainActivity.kt` to track:
- Output tensor shape (should be `[1, 3]`)
- Total elements in tensor (should be 3)
- All output values before processing
- Final 3 logit values sent to Dart

### 2. Enhanced Dart Logging
Added detailed logging in `facial_pain_recognition_service.dart`:
- Raw output values received from native code
- All extracted logit values with full precision
- Logit range analysis (min, max, range)
- Warnings for identical logits, small ranges, or extreme values
- Diagnostic messages for common issues

### 3. Better Output Handling
- Explicitly handles different output sizes (3, >3, <3)
- Takes first 3 values if more are present
- Pads with zeros if fewer than 3 values
- Logs warnings for unexpected output sizes

## Diagnostic Information Now Available

When running the app, check logs for:

1. **Native (Android Logcat)**:
   ```
   Output Tensor Shape: [1, 3]
   Output Array Size: 3
   Output Array All Values: X.XXX, Y.YYY, Z.ZZZ
   Final Output (3 logits): [X.XXX, Y.YYY, Z.ZZZ]
   ```

2. **Dart Debug Logs**:
   ```
   Raw output values (first 10): [...]
   Extracted logits: [X.XXXXXX, Y.YYYYYY, Z.ZZZZZZ]
   Logits interpretation: Low=X.XXX, Moderate=Y.YYY, Severe=Z.ZZZ
   Logit range: min=..., max=..., range=...
   ```

## Possible Issues to Check

### If Model Always Predicts "Low":
1. **Check Logits**: Are all 3 logits nearly identical?
   - If yes: Model may not be learning or input preprocessing issue
   - If no: Check which logit is highest (should vary)

2. **Check Logit Values**: 
   - Are they all zeros? → Model not running correctly
   - Are they all the same? → Preprocessing issue or model stuck
   - Is first logit always highest? → Model bias or training issue

3. **Check Input Preprocessing**:
   - Are preprocessed values varying between frames?
   - Are values in reasonable range (not all zeros/ones)?

4. **Check Model File**:
   - Is `pain_recognition_model.ptl` the correct model?
   - Was it exported correctly from training script?
   - Is it loading without errors?

## Next Steps

1. Run the app and check logs for the diagnostic information above
2. Look for patterns:
   - Are logits varying between frames?
   - Is the highest logit always at index 0 (Low)?
   - Are logit values reasonable (not all zeros/same)?
3. Share log output to diagnose the specific issue

The enhanced logging should reveal exactly what the model is outputting and help identify why it's stuck on "Low".


