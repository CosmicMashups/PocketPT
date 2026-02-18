# PocketPT Pose Estimation Test Cases - Contextual Interpretation Guide

This document provides contextual basis for interpreting pose estimation test cases in PocketPT. It defines what pose configurations are considered **Low**, **Moderate**, or **Severe** for each muscle group when performing Active Range of Motion (AROM) assessments.

## Overview

PocketPT uses pose estimation (YOLO11s-pose model) to assess muscle function by analyzing joint angles and body positions during AROM exercises. The system uses COCO format pose landmarks (17 keypoints) normalized to 0.0-1.0 range for calculations.

## Standardized Pain Scale Mapping

All assessments use the following standardized mapping:

| ROM Level | Pain Score | Pain Scale Range | Description |
|-----------|------------|------------------|-------------|
| **Severe** | 9 | 8-10 | Significant functional limitation/pain |
| **Moderate** | 6 | 5-7 | Noticeable functional impact |
| **Low** | 3 | 2-4 | Minimal functional impact |
| **Good** | 1 | 0-1 | Normal function (not used in test cases) |

## Pose Landmarks Reference

All assessments use COCO format landmarks:
- **Upper Body:** `leftShoulder`, `rightShoulder`, `leftElbow`, `rightElbow`, `leftWrist`, `rightWrist`
- **Lower Body:** `leftHip`, `rightHip`, `leftKnee`, `rightKnee`, `leftAnkle`, `rightAnkle`
- **Trunk:** Uses midpoints of left/right shoulder, hip, and knee landmarks

---

## Upper Body Muscles

### 1. Biceps

**Measurement Method:** Shoulder-Elbow-Wrist angle  
**Landmarks Used:** `${side}Shoulder`, `${side}Elbow`, `${side}Wrist`  
**Clinical Logic:** Higher angle = more extended arm = more pain/limitation

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle > 150° | Arm fully extended or nearly straight | Cannot flex elbow significantly, severe limitation |
| **Moderate** | 90° < Angle ≤ 150° | Arm partially flexed | Some elbow flexion possible, moderate limitation |
| **Low** | Angle ≤ 90° | Arm well flexed, elbow bent | Good elbow flexion, minimal limitation |

**Test Case Interpretation:**
- **Severe Test:** User's arm should be extended (elbow nearly straight) with angle > 150°
- **Moderate Test:** User's arm should be partially bent with angle between 90° and 150°
- **Low Test:** User's arm should be well flexed (elbow bent) with angle ≤ 90°

---

### 2. Triceps

**Measurement Method:** Hip-Shoulder-Elbow angle  
**Landmarks Used:** `${side}Hip`, `${side}Shoulder`, `${side}Elbow`  
**Clinical Logic:** Lower angle = more bent arm = more pain/limitation (Note: Logic appears reversed in code - higher angle = severe)

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle ≥ 135° | Arm extended (shoulder-elbow angle large) | Arm well extended, severe limitation |
| **Moderate** | 90° ≤ Angle < 135° | Arm partially extended | Some extension possible, moderate limitation |
| **Low** | Angle < 90° | Arm bent/flexed (shoulder-elbow angle small) | Limited extension, low limitation |

**Test Case Interpretation:**
- **Severe Test:** User's arm should be extended with hip-shoulder-elbow angle ≥ 135°
- **Moderate Test:** User's arm should be partially extended with angle between 90° and 135°
- **Low Test:** User's arm should be bent/flexed with angle < 90°

**Note:** The clinical logic for triceps appears reversed in the implementation. The code classifies higher extension angles as severe, which may indicate the assessment is measuring limitation differently than expected.

---

### 3. Shoulders (Deltoids)

**Measurement Method:** Hip-Shoulder-Elbow angle  
**Landmarks Used:** `${side}Hip`, `${side}Shoulder`, `${side}Elbow`  
**Clinical Logic:** Lower angle = arm raised higher = more pain/limitation

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle < 90° | Arm raised overhead or high | Cannot lower arm, severe limitation |
| **Moderate** | 90° ≤ Angle ≤ 110° | Arm at shoulder height (T-pose) | Arm at shoulder level, moderate limitation |
| **Low** | Angle > 110° | Arm lowered (below shoulder) | Arm can be lowered, minimal limitation |

**Test Case Interpretation:**
- **Severe Test:** User's arm should be raised overhead or high with angle < 90°
- **Moderate Test:** User's arm should be at shoulder height (T-pose) with angle between 90° and 110°
- **Low Test:** User's arm should be lowered below shoulder level with angle > 110°

---

### 4. Chest

**Measurement Method:** Hip-Shoulder-Wrist angle (forward elevation)  
**Landmarks Used:** `${side}Hip`, `${side}Shoulder`, `${side}Wrist`  
**Clinical Logic:** Higher angle = better forward elevation = less pain

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle < 45° | Limited forward arm elevation | Cannot raise arm forward, severe limitation |
| **Moderate** | 45° ≤ Angle < 90° | Partial forward elevation | Some forward movement, moderate limitation |
| **Low** | Angle ≥ 90° | Good forward elevation | Arm can be raised forward well, minimal limitation |

**Test Case Interpretation:**
- **Severe Test:** User's arm should be limited in forward elevation with angle < 45°
- **Moderate Test:** User's arm should show partial forward elevation with angle between 45° and 90°
- **Low Test:** User's arm should show good forward elevation with angle ≥ 90°

---

## Lower Body Muscles

### 5. Quadriceps

**Measurement Method:** Hip-Knee-Ankle angle (knee flexion)  
**Landmarks Used:** `${side}Hip`, `${side}Knee`, `${side}Ankle`  
**Clinical Logic:** Lower angle = better knee flexion = more pain/limitation (counterintuitive - well-bent leg indicates severe)

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle < 120° | Leg well bent (good knee flexion) | Knee can flex well, severe limitation (may indicate pain when flexing) |
| **Moderate** | 120° ≤ Angle < 140° | Leg partially bent (partial flexion) | Some knee flexion, moderate limitation |
| **Low** | Angle ≥ 140° | Leg nearly straight (poor flexion) | Limited knee flexion, low limitation |

**Test Case Interpretation:**
- **Severe Test:** User's leg should be well bent (knee flexed) with angle < 120°
- **Moderate Test:** User's leg should be partially bent with angle between 120° and 140°
- **Low Test:** User's leg should be nearly straight with angle ≥ 140°

**Note:** The logic for quadriceps is counterintuitive - a well-flexed knee (low angle) is classified as severe. This may indicate the assessment measures pain during flexion rather than range of motion limitation.

---

### 6. Hamstrings

**Measurement Method:** Shoulder-Hip-Knee angle  
**Landmarks Used:** `${side}Shoulder`, `${side}Hip`, `${side}Knee`  
**Clinical Logic:** Higher angle = leg more extended = more pain/limitation

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle ≥ 180° | Leg extended/straight | Leg fully extended, severe limitation |
| **Moderate** | 140° ≤ Angle < 160° | Leg partially extended | Some extension, moderate limitation |
| **Low** | Angle < 140° | Leg flexed/bent | Leg can flex, minimal limitation |

**Test Case Interpretation:**
- **Severe Test:** User's leg should be extended/straight with angle ≥ 180°
- **Moderate Test:** User's leg should be partially extended with angle between 140° and 160°
- **Low Test:** User's leg should be flexed/bent with angle < 140°

**Additional Assessment:** Pelvic compensation is checked by comparing vertical difference between left and right hips. If normalized difference > 0.05 (5% of torso height), pelvic tilt compensation is detected.

---

### 7. Gluteals

**Measurement Method:** Shoulder-Hip-Knee angle  
**Landmarks Used:** `${side}Shoulder`, `${side}Hip`, `${side}Knee`  
**Clinical Logic:** Higher angle = leg more extended = more pain/limitation

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle ≥ 180° | Leg extended/straight | Leg fully extended, severe limitation |
| **Moderate** | 140° ≤ Angle < 160° | Leg partially extended | Some extension, moderate limitation |
| **Low** | Angle < 140° | Leg flexed/bent | Leg can flex, minimal limitation |

**Test Case Interpretation:**
- **Severe Test:** User's leg should be extended/straight with angle ≥ 180°
- **Moderate Test:** User's leg should be partially extended with angle between 140° and 160°
- **Low Test:** User's leg should be flexed/bent with angle < 140°

**Note:** Gluteals and Hamstrings use the same measurement method and thresholds, as they are assessed together in the glute-ham assessment module.

---

### 8. Calves

**Measurement Method:** Normalized horizontal displacement (not angle-based)  
**Landmarks Used:** `${side}Hip`, `${side}Knee`, `${side}Ankle`  
**Calculation:** `(knee.dx - ankle.dx) / (hip.dy - ankle.dy)` (normalized by body segment height)  
**Clinical Logic:** Lower displacement = less dorsiflexion = more pain/limitation

#### Severity Classifications:

| Severity | Normalized Displacement | Pose Description | Clinical Context |
|----------|------------------------|------------------|-----------------|
| **Severe** | < 0.15 | Minimal knee-over-ankle displacement | Limited dorsiflexion, severe limitation |
| **Moderate** | 0.15 ≤ Displacement < 0.30 | Partial knee-over-ankle displacement | Some dorsiflexion, moderate limitation |
| **Low** | ≥ 0.30 | Good knee-over-ankle displacement | Good dorsiflexion, minimal limitation |

**Test Case Interpretation:**
- **Severe Test:** User's knee should be minimally forward of ankle (normalized displacement < 0.15)
- **Moderate Test:** User's knee should be partially forward of ankle (normalized displacement between 0.15 and 0.30)
- **Low Test:** User's knee should be well forward of ankle (normalized displacement ≥ 0.30)

**Additional Assessment:** Knee-over-ankle alignment is checked. If `knee.dx > ankle.dx`, alignment is "Knee Forward" (good); otherwise "Knee Behind/Inline" (may indicate compensation).

---

## Trunk Muscles

### 9. Abdominals, Obliques, Lower Back, Multifidus

**Measurement Method:** Shoulder-Hip-Knee angle (using midpoints)  
**Landmarks Used:** `leftShoulder`, `rightShoulder`, `leftHip`, `rightHip`, `leftKnee`, `rightKnee`  
**Calculation:** Uses midpoints of left/right landmarks to calculate trunk angle  
**Clinical Logic:** Higher angle = more upright/extended = more pain/limitation (for abdominals/obliques) or less pain (for lower back/multifidus)

#### Severity Classifications:

| Severity | Angle Range | Pose Description | Clinical Context |
|----------|-------------|------------------|-----------------|
| **Severe** | Angle ≥ 150° | Trunk upright or extended backward | Standing straight or extended, severe tension |
| **Moderate** | 80° ≤ Angle < 150° | Trunk partially flexed | Mid-level bend, moderate limitation |
| **Low** | Angle < 80° | Trunk flexed forward | Forward flexion, low limitation |

**Test Case Interpretation:**
- **Severe Test:** User's trunk should be upright or extended backward with angle ≥ 150°
- **Moderate Test:** User's trunk should be partially flexed with angle between 80° and 150°
- **Low Test:** User's trunk should be flexed forward with angle < 80°

**Note:** All four trunk muscles (Abdominals, Obliques, Lower Back, Multifidus) use the same unified assessment method and thresholds. The clinical interpretation may differ based on the specific muscle being assessed, but the measurement is the same.

---

## Test Case Creation Guidelines

### For Each Muscle Group:

1. **Severe Test Cases:**
   - Create poses that match the "Severe" angle/displacement ranges
   - Verify the pose estimation model can detect the required landmarks
   - Ensure the calculated angle/displacement falls within the severe threshold

2. **Moderate Test Cases:**
   - Create poses that match the "Moderate" angle/displacement ranges
   - Test boundary conditions (at threshold values)
   - Verify smooth transitions between severity levels

3. **Low Test Cases:**
   - Create poses that match the "Low" angle/displacement ranges
   - Test poses that are close to "Good" (normal function) but still classified as low
   - Verify the system correctly distinguishes low from good

### Common Test Scenarios:

- **Boundary Testing:** Test angles/displacements exactly at threshold values
- **Edge Cases:** Test very small angles (near 0°) and very large angles (near 180°)
- **Missing Landmarks:** Test scenarios where required landmarks are not detected
- **Compensation Detection:** For hamstrings, test pelvic compensation scenarios
- **Alignment Checks:** For calves, test knee-over-ankle alignment variations

---

## Pose Estimation Model Requirements

### Landmark Detection:
- All required landmarks must be visible and detected
- Landmarks are normalized to 0.0-1.0 range
- Missing landmarks result in "not visible" assessment

### Angle Calculation:
- Uses three-point angle calculation (vertex is middle point)
- Formula: `angle = arccos((v1 · v2) / (|v1| × |v2|)) × 180° / π`
- Angles are measured in degrees (0° to 180°)

### Normalized Displacement (Calves):
- Horizontal displacement normalized by vertical body segment height
- Formula: `displacement = (knee.dx - ankle.dx) / (hip.dy - ankle.dy)`
- Absolute value is used for severity classification

---

## Clinical Context Notes

### Important Considerations:

1. **Inverse Logic:** Some assessments (e.g., Quadriceps) use counterintuitive logic where better range of motion indicates severe limitation. This may indicate the assessment measures pain during movement rather than limitation of movement.

2. **Unified Assessments:** Trunk muscles (Abdominals, Obliques, Lower Back, Multifidus) all use the same measurement method. Clinical interpretation may differ, but the pose requirements are identical.

3. **Compensation Detection:** Hamstring assessment includes pelvic compensation detection, which may affect the overall assessment even if the angle suggests a different severity level.

4. **Side-Specific:** Most assessments are side-specific (left/right). Test cases should specify which side is being assessed.

5. **Position Requirements:** Some assessments (e.g., Calves) require specific body positioning. If landmarks are detected but position is incorrect, the system may request position adjustment.

---

## Summary Table: All Muscles

| Muscle | Measurement | Severe | Moderate | Low |
|--------|-------------|--------|----------|-----|
| **Biceps** | Shoulder-Elbow-Wrist angle | > 150° | 90°-150° | ≤ 90° |
| **Triceps** | Hip-Shoulder-Elbow angle | ≥ 135° | 90°-135° | < 90° |
| **Shoulders** | Hip-Shoulder-Elbow angle | < 90° | 90°-110° | > 110° |
| **Chest** | Hip-Shoulder-Wrist angle | < 45° | 45°-90° | ≥ 90° |
| **Quadriceps** | Hip-Knee-Ankle angle | < 120° | 120°-140° | ≥ 140° |
| **Hamstrings** | Shoulder-Hip-Knee angle | ≥ 180° | 140°-160° | < 140° |
| **Gluteals** | Shoulder-Hip-Knee angle | ≥ 180° | 140°-160° | < 140° |
| **Calves** | Normalized displacement | < 0.15 | 0.15-0.30 | ≥ 0.30 |
| **Trunk** | Shoulder-Hip-Knee (midpoints) | ≥ 150° | 80°-150° | < 80° |

---

## Test Case Validation Checklist

For each pose estimation test case, verify:

- [ ] Required landmarks are visible and detected
- [ ] Calculated angle/displacement matches expected severity level
- [ ] Pain score maps correctly (Severe=9, Moderate=6, Low=3)
- [ ] Categorical pain level is correct (Severe/Moderate/Low)
- [ ] Display label shows correct angle range
- [ ] Clinical context is appropriate
- [ ] Side-specific assessments specify correct side
- [ ] Compensation/alignment checks (if applicable) are performed
- [ ] Edge cases at threshold boundaries are tested
- [ ] Missing landmark scenarios are handled gracefully

---

## Notes

- All angle measurements are in degrees
- Normalized displacement for calves is unitless (ratio)
- Threshold values are defined in `assessment_constants.dart`
- Pain scale mapping is standardized across all assessments
- Some assessments may have counterintuitive logic based on clinical interpretation
- Trunk muscles share the same assessment method but may have different clinical meanings





