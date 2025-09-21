# Pain Scale Mapping Analysis & Recommendations

## Current Issues Identified

### 1. **Inconsistent Pain Scale Ranges Across Assessment Modes**

| Assessment Mode | Current Pain Scales Used | Issues |
|---|---|---|
| Triceps | 2, 5, 8 | 3-point scale, gaps in range |
| Shoulders | 1, 4, 6, 9 | 4-point scale, inconsistent with others |
| Calf | 2, 5, 8 | Matches triceps but different from shoulders |
| Hamstring | 2, 6, 9 | Different from all others |

### 2. **Conflicting Logic in Pose Detection Service**

The `romToPainScale()` method in `pose_detection_service.dart` uses:
- severe = 8
- moderate = 5  
- low = 3
- good = 1

But camera files use different mappings for the same ROM levels.

### 3. **Medical Logic Assessment**

#### ✅ **Logically Correct:**
- **Shoulder Assessment**: Higher angles (arm down) = lower pain, lower angles (arm raised) = higher pain
- **Triceps Assessment**: Higher angles (extended) = lower pain, lower angles (flexed) = higher pain
- **Hamstring Assessment**: Higher angles (leg raised) = lower pain, lower angles (leg down) = higher pain

#### ⚠️ **Questionable:**
- **Calf Assessment**: Uses displacement rather than angle, but logic seems reasonable

## Recommended Standardized Pain Scale Mapping

### **Proposed 4-Tier System (0-10 scale):**

| ROM Level | Pain Scale | Description | Medical Rationale |
|---|---|---|---|
| **Severe** | 8-10 | Significant limitation/pain | Major ROM restriction indicates serious issue |
| **Moderate** | 5-7 | Partial limitation/pain | Some ROM loss, manageable but concerning |
| **Low** | 2-4 | Minor limitation/pain | Slight ROM restriction, minimal impact |
| **Good** | 0-1 | Normal ROM/no pain | Full range of motion, no issues |

### **Specific Recommendations by Assessment:**

#### **1. Triceps Assessment (Shoulder-Elbow-Wrist Angle)**
```dart
// Current: 2, 5, 8
// Recommended: 1, 4, 7, 10
if (angle < 90) return 10;    // Severe limitation (arm very bent)
if (angle < 120) return 7;    // Moderate limitation  
if (angle < 150) return 4;    // Low limitation
return 1;                     // Good ROM (arm extended)
```

#### **2. Shoulder Assessment (Hip-Shoulder-Elbow Angle)**
```dart
// Current: 1, 4, 6, 9
// Recommended: 1, 4, 7, 10
if (angle < 90) return 10;    // Severe pain (arm raised high)
if (angle < 120) return 7;    // Moderate pain
if (angle < 150) return 4;    // Low pain
return 1;                     // Good mobility (arm down)
```

#### **3. Calf Assessment (Normalized Displacement)**
```dart
// Current: 2, 5, 8
// Recommended: 1, 4, 7, 10
if (displacement < 0.10) return 10;  // Severe limitation
if (displacement < 0.20) return 7;   // Moderate limitation
if (displacement < 0.30) return 4;   // Low limitation
return 1;                            // Good ROM
```

#### **4. Hamstring Assessment (Vertical Angle)**
```dart
// Current: 2, 6, 9
// Recommended: 1, 4, 7, 10
if (angle < 45) return 10;    // Severe limitation (leg low)
if (angle < 60) return 7;     // Moderate limitation
if (angle < 80) return 4;     // Low limitation
return 1;                     // Good ROM (leg raised)
```

## Implementation Benefits

### **1. Consistency**
- All assessments use the same 4-tier system
- Eliminates confusion between different assessment modes
- Standardized pain scale interpretation

### **2. Medical Accuracy**
- Better reflects clinical pain assessment practices
- More granular assessment (4 levels vs 3)
- Covers full 0-10 pain scale range

### **3. User Experience**
- Predictable pain scale behavior across all assessments
- Easier to understand and interpret results
- Better integration with pain history tracking

## Priority Fixes Needed

1. **Standardize `romToPainScale()` method** in pose detection service
2. **Update all camera file mappings** to use consistent scale
3. **Align with clinical pain assessment standards**
4. **Test with real users** to validate logical consistency

## Conclusion

The current pain scale mappings have **significant inconsistencies** that could confuse users and reduce the clinical value of the assessments. Implementing a standardized 4-tier system would improve both accuracy and user experience.
