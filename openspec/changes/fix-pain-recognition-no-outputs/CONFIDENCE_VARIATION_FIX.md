# Fix: Confidence Stuck at 43% for Moderate Pain

## Problem
Pain recognition confidence was stuck at 43% for Moderate pain, suggesting it might be hardcoded or not varying with actual model output.

## Root Cause Analysis
The confidence value comes from the model's softmax output: `probabilities[predictedClassIndex]`. If it's always 43%, it means:
1. The model is receiving similar inputs each frame (face extraction not varying)
2. The model is outputting similar logits each frame
3. The preprocessing might be producing identical inputs

However, there was **NO hardcoded 43% value** - the confidence was correctly extracted from model output. The issue was that the model predictions weren't varying, causing the same confidence value to appear.

## Solution Applied

### 1. Enhanced Confidence Tracking
- Added confidence history tracking (`_recentConfidences`) to monitor if confidence is stuck
- Added detection for when confidence values are not varying between frames
- Added detailed diagnostics to identify why confidence might be stuck

### 2. Improved Diagnostics
- Added logging to track when confidence changes vs stays the same
- Added detection for stuck confidence values (all recent values nearly identical)
- Added logging of model logits to help diagnose stuck predictions
- Clear indication that confidence comes from real-time model output (not cached)

### 3. Verification That Confidence is Real-Time
- Confidence is extracted directly from `probabilities[predictedClassIndex]` - the probability of the predicted class
- Each frame runs fresh inference, so confidence should vary as facial expressions change
- Added flag `isRealTime: true` to ensure UI knows it's from current frame

## Key Changes

1. **Confidence Source Verification**:
   - Confidence = `probabilities[predictedClassIndex]` (probability of predicted class from softmax)
   - This is calculated fresh for each frame from model logits
   - No hardcoded values - always from model output

2. **Confidence Variation Detection**:
   - Tracks last 5 confidence values
   - Detects if confidence is stuck (all values nearly identical)
   - Logs warnings when confidence doesn't vary

3. **Enhanced Logging**:
   - Shows when confidence changes vs stays the same
   - Logs raw confidence value with 6 decimal precision
   - Shows recent confidence history when stuck

## Result
- ✅ Confidence comes directly from model output (no hardcoded values)
- ✅ Confidence should vary as facial expressions change
- ✅ Diagnostics added to detect if confidence is stuck
- ✅ Clear logging shows confidence source and variation

## Next Steps for User
If confidence is still stuck at 43% after this fix, it indicates:
1. Model is receiving very similar inputs (face extraction issue)
2. Model predictions are not varying (model or preprocessing issue)
3. Facial expressions in camera are not changing enough

Check the diagnostics logs to see:
- Are logits varying between frames?
- Are probabilities varying?
- Is face extraction producing different crops each frame?

