# Muscle Assessment Pose Analysis Summary

## Overview

This document summarizes the analysis of muscle assessment code to determine expected poses for each pain scale category (Low, Moderate, Severe) across all muscle groups in the PocketPT application.

## Analysis Methodology

### 1. Code Review Process

Analyzed the following assessment modules:
- `b_trunk_assessment.dart` - Trunk (Abdominals, Obliques, Lower Back, Multifidus)
- `biceps_assessment.dart` - Biceps
- `calves_assessment.dart` - Calves
- `chest_assessment.dart` - Chest
- `glute_ham_assessment.dart` - Gluteals and Hamstrings
- `hamstrings_assessment.dart` - Hamstrings (vertical angle method)
- `quadriceps_assessment.dart` - Quadriceps
- `shoulders_assessment.dart` - Shoulders
- `triceps_assessment.dart` - Triceps
- `assessment_constants.dart` - Clinical thresholds and pain scale mappings

### 2. Key Findings

#### Pain Scale Mapping
From `assessment_constants.dart`, the standardized mapping is:
- **Severe**: painScore = 9 (8-10 range) - Significant functional limitation
- **Moderate**: painScore = 6 (5-7 range) - Noticeable functional impact
- **Low**: painScore = 3 (2-4 range) - Minimal functional impact
- **Good**: painScore = 1 (0-1 range) - Normal function

#### Measurement Methods by Muscle Group

##### Upper Body Muscles

**Biceps**
- Measurement: Shoulder-Elbow-Wrist angle
- Logic: Higher angle = more extended = more pain
- Severe: Angle > 150° (arm extended)
- Moderate: 90° < angle ≤ 150° (partially flexed)
- Good: Angle ≤ 90° (well flexed)

**Triceps**
- Measurement: Shoulder-Elbow-Wrist angle
- Logic: Lower angle = more bent = more pain
- Severe: Angle < 90° (heavily bent)
- Moderate: 90° ≤ angle < 135° (partially extended)
- Good: Angle ≥ 135° (well extended)

**Shoulders**
- Measurement: Hip-Shoulder-Elbow angle
- Logic: Lower angle = arm raised higher = more pain
- Severe: Angle < 90° (arm overhead)
- Moderate: 90° ≤ angle ≤ 110° (shoulder height)
- Low: 111° ≤ angle ≤ 150° (partially raised)
- Good: Angle > 150° (arm down)

**Chest**
- Measurement: Hip-Shoulder-Wrist angle
- Logic: Lower angle = less forward elevation = more pain
- Severe: Angle < 45° (minimal elevation)
- Moderate: 45° ≤ angle < 90° (partial elevation)
- Good: Angle ≥ 90° (good elevation)

##### Trunk Muscles

**Trunk (Abdominals, Obliques, Lower Back, Multifidus)**
- Measurement: Shoulder-Hip-Knee angle
- Logic: Higher angle = more upright = more pain
- Severe: Angle ≥ 160° (standing upright/extended)
- Moderate: 60° ≤ angle < 160° (mid-level bend)
- Low: Angle < 60° (fully flexed forward)

##### Lower Body Muscles

**Quadriceps**
- Measurement: Hip-Knee-Ankle angle
- Logic: Higher angle = more extended = more pain
- Severe: Angle ≥ 160° (leg nearly straight)
- Moderate: 100° ≤ angle < 160° (partial flexion)
- Low: Angle < 100° (well bent)

**Hamstrings (Vertical Angle Method)**
- Measurement: Hip-to-Ankle vertical angle
- Logic: Lower angle = leg less raised = more pain
- Severe: Angle < 60° (leg barely raised)
- Moderate: 60° ≤ angle < 80° (partial elevation)
- Good: Angle ≥ 80° (good elevation)

**Hamstrings (Enhanced Hip-Knee-Ankle Method)**
- Measurement: Hip-Knee-Ankle angle
- Logic: Higher angle = more extended = more pain
- Severe: Angle ≥ 160° (leg extended)
- Moderate: 100° ≤ angle < 160° (partial flexion)
- Low: Angle < 100° (good flexion)

**Gluteals**
- Measurement: Shoulder-Hip-Knee angle
- Logic: Higher angle = more upright = more pain
- Severe: Angle ≥ 160° (upright posture)
- Moderate: 100° ≤ angle < 160° (partial forward lean)
- Low: Angle < 100° (good forward bend)

**Calves**
- Measurement: Normalized displacement (knee-to-ankle / body height)
- Logic: Lower displacement = knee less forward = more pain
- Severe: < 0.15 (knee behind ankle)
- Moderate: 0.15 ≤ displacement < 0.30 (knee partially forward)
- Good: ≥ 0.30 (knee well forward)

## Pose Characteristics for Each Pain Level

### Severe Pain Poses
- Show significant limitation and inability to achieve proper range of motion
- Demonstrate pain indicators through restricted movement
- Typically show opposite of optimal range (extended when should flex, upright when should bend, etc.)

### Moderate Pain Poses
- Show partial range of motion achievement
- Indicate some functional ability but with noticeable limitation
- Represent mid-point between severe and good ROM

### Low Pain/Good ROM Poses
- Show good to optimal range of motion
- Indicate healthy flexibility and muscle function
- Demonstrate proper form and full movement capacity

## AI Prompt Generation Strategy

For each muscle group and pain category, prompts were engineered to include:

1. **Specific anatomical landmarks** being measured
2. **Exact angle or displacement ranges** based on code thresholds
3. **Visual positioning** (profile, frontal, supine, etc.)
4. **Clinical context** (severe limitation, moderate limitation, good ROM)
5. **Consistent aesthetic** (medical illustration style, clean background)
6. **Clear anatomical alignment** (shoulder-to-wrist, hip-to-ankle, etc.)

## Usage of Generated Images

The AI-generated images will serve as:

1. **Visual Reference Materials** for users to understand expected assessment poses
2. **Educational Content** showing proper vs. limited ROM
3. **Documentation Aids** for clinical interpretation
4. **UI/UX Assets** for instruction screens and assessment guidance
5. **Training Materials** for users to prepare for assessments

## Files Created

- `COMPREHENSIVE_MUSCLE_ASSESSMENT_IMAGE_PROMPTS.md` - Complete set of prompts for all muscle groups and pain scales
- `MUSCLE_ASSESSMENT_POSE_ANALYSIS_SUMMARY.md` - This analysis document

## Next Steps

1. Use the prompts in `COMPREHENSIVE_MUSCLE_ASSESSMENT_IMAGE_PROMPTS.md` with Google Gemini or similar AI image generator
2. Generate images for each muscle group and pain scale category
3. Organize generated images by muscle group and pain level
4. Integrate images into the PocketPT application UI as needed
5. Use images for user education and assessment documentation

## Technical Notes

- All angle measurements are in degrees
- Displacement measurements are normalized ratios
- Pain scale uses 0-10 numeric range with categorical labels
- ROM levels map to pain scores as defined in `PainScaleMapping` class
- Assessment logic is consistent across all muscle groups through shared constants

