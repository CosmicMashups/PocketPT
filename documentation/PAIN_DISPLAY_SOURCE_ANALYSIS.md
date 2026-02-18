# Pain Display Source Analysis

## Current Implementation in Top-Right Corner (c_camera.dart lines 1948-2000)

### Pain Level Label (Line 1977-1979)
```dart
_currentAssessmentResult != null
    ? '${_currentAssessmentResult!.categoricalPainLevel} Pain (AROM)'
    : '${_currentPainLevel ?? 'Low'} Pain (Facial)'
```
**Source**: AROM assessment when available, falls back to facial recognition

### Pain Score (Line 1987-1989)
```dart
_getCurrentPainScore() > 0 
    ? '${_getCurrentPainScore()}/10'
    : (_currentPainLevel ?? 'N/A')
```
**Source**: Uses `_getCurrentPainScore()` which:
- Returns `_currentAssessmentResult!.painScore` if AROM is available (line 1291-1292)
- Falls back to `_mapFacialPainScore(_currentPainLevel)` if AROM is not available (line 1296)

### Background Color (Line 1952)
```dart
color: _getPainColor(_currentPainLevel).withOpacity(0.95)
```
**Source**: Always uses `_currentPainLevel` (facial recognition) - **POTENTIAL BUG**

## Answer

**The pain level and pain scale in the top-right corner:**
- **Label**: Uses AROM assessment when available (shows "(AROM)"), falls back to facial recognition (shows "(Facial)")
- **Score**: Uses AROM assessment `painScore` when available, falls back to facial recognition mapping
- **Color**: Always uses facial recognition `_currentPainLevel` - **This is inconsistent and should use AROM when available**

## Recommendation

The background color should also use AROM assessment when available for consistency:
```dart
color: _getPainColor(
  _currentAssessmentResult?.categoricalPainLevel ?? _currentPainLevel
).withOpacity(0.95)
```




