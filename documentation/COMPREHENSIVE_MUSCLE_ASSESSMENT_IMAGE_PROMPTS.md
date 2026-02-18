# Muscle Assessment Logic and Landmarks

This document outlines the assessment logic, measurement methods, and landmarks used for each muscle assessment in the PocketPT application.

---

## Google ML Kit Pose Detection Landmarks

Google ML Kit Pose Detection provides **33 body landmarks** that are used throughout the PocketPT application for pose analysis and ROM assessments. Below is the complete list of all landmarks available in the ML Kit Pose Detection API:

### Head and Face (5 landmarks)
- `nose` - Center of the nose
- `leftEye` - Left eye
- `rightEye` - Right eye
- `leftEar` - Left ear
- `rightEar` - Right ear

### Upper Body - Shoulders and Arms (12 landmarks)
- `leftShoulder` - Left shoulder joint
- `rightShoulder` - Right shoulder joint
- `leftElbow` - Left elbow joint
- `rightElbow` - Right elbow joint
- `leftWrist` - Left wrist joint
- `rightWrist` - Right wrist joint
- `leftThumb` - Left thumb tip
- `rightThumb` - Right thumb tip
- `leftIndex` - Left index finger tip
- `rightIndex` - Right index finger tip
- `leftPinky` - Left pinky finger tip
- `rightPinky` - Right pinky finger tip

### Lower Body - Hips and Legs (10 landmarks)
- `leftHip` - Left hip joint
- `rightHip` - Right hip joint
- `leftKnee` - Left knee joint
- `rightKnee` - Right knee joint
- `leftAnkle` - Left ankle joint
- `rightAnkle` - Right ankle joint
- `leftHeel` - Left heel
- `rightHeel` - Right heel
- `leftFootIndex` - Left foot index toe
- `rightFootIndex` - Right foot index toe

**Total: 27 landmarks** are currently extracted and used in the PocketPT codebase. Google ML Kit Pose Detection API provides additional landmarks (up to 33 total) including eye inner/outer corners and mouth corners, but these are not currently utilized in the application's pose detection service.

### Landmark Usage in Assessments

Different muscle assessments use specific combinations of these landmarks:

- **Biceps/Triceps**: `shoulder`, `elbow`, `wrist` (side-specific)
- **Shoulder**: `hip`, `shoulder`, `elbow` (side-specific)
- **Chest**: `hip`, `shoulder`, `wrist` (side-specific)
- **Trunk**: `shoulderMid` (from leftShoulder + rightShoulder), `hipMid` (from leftHip + rightHip), `kneeMid` (from leftKnee + rightKnee)
- **Quadriceps/Hamstrings/Gluteals**: `hip`, `knee`, `ankle` (side-specific)
- **Calves**: `hip`, `knee`, `ankle` (side-specific) with displacement calculations

**Note**: When assessments reference "side-specific" landmarks, they use either the left or right version based on the selected assessment side (e.g., `leftShoulder` vs `rightShoulder`).

---

## 1. BICEPS ASSESSMENT

### Assessment Logic
- **Measurement**: Shoulder-Elbow-Wrist angle
- **Severe** (Extended): Angle > 150° - Poor flexion, arm extended
- **Moderate**: 90° < angle ≤ 150° - Partial flexion
- **Low** (Good): Angle ≤ 90° - Good flexion, arm well bent

### Landmarks used
- shoulder (side-specific)
- elbow (side-specific)
- wrist (side-specific)

---

## 2. TRICEPS ASSESSMENT

### Assessment Logic
- **Measurement**: Shoulder-Elbow-Wrist angle
- **Severe** (Bent): Angle < 90° - Poor extension, arm heavily bent
- **Moderate**: 90° ≤ angle < 135° - Partial extension
- **Low**: Angle ≥ 135° - Good extension, arm nearly straight

### Landmarks used
- hip (side-specific)
- shoulder (side-specific)
- elbow (side-specific)

---

## 3. SHOULDER ASSESSMENT

### Assessment Logic
- **Measurement**: Hip-Shoulder-Elbow angle
- **Severe**: Angle < 90° - Arm raised high overhead, severe limitation
- **Moderate**: 90° ≤ angle ≤ 110° - Arm at shoulder height
- **Low**: 111° ≤ angle ≤ 150° - Arm partially raised
- **Low**: Angle > 150° - Arm down/low, good mobility

### Landmarks used
- hip (side-specific)
- shoulder (side-specific)
- elbow (side-specific)

---

## 4. CHEST ASSESSMENT

### Assessment Logic
- **Measurement**: Hip-Shoulder-Wrist angle
- **Severe**: Angle < 45° - Forward elevation very limited
- **Moderate**: 45° ≤ angle < 90° - Partial forward elevation
- **Low**: Angle ≥ 90° - Good forward elevation

### Landmarks used
- hip (side-specific)
- shoulder (side-specific)
- wrist (side-specific)

---

## 5. TRUNK ASSESSMENT (Abdominals, Obliques, Lower Back, Multifidus)

### Assessment Logic
- **Measurement**: Shoulder-Hip-Knee angle
- **Severe**: Angle ≥ 160° - Standing straight/extended backward, severe limitation
- **Moderate**: 60° ≤ angle < 160° - Mid-level bend
- **Low**: Angle < 60° - Fully flexed forward, good flexion

### Landmarks used
- leftShoulder, rightShoulder → shoulderMid (midpoint)
- leftHip, rightHip → hipMid (midpoint)
- leftKnee, rightKnee → kneeMid (midpoint)
- Measurement uses: shoulderMid-hipMid-kneeMid

---

## 6. QUADRICEPS ASSESSMENT

### Assessment Logic
- **Measurement**: Hip-Knee-Ankle angle
- **Severe**: Angle < 120° - Good flexion, leg well bent
- **Moderate**: 120° ≤ angle < 140° - Partial flexion
- **Low**: Angle ≥ 140° - Leg nearly straight, poor flexion

### Landmarks used
- hip (side-specific)
- knee (side-specific)
- ankle (side-specific)

---

## 8. HAMSTRING ASSESSMENT

### Assessment Logic
- **Measurement**: Hip-Knee-Ankle angle
- **Low**: Angle ≤ 130° - Leg extended, good flexion
- **Moderate**: 145° ≤ angle < 160° - Partial flexion
- **Severe**: Angle < 190° - Poor flexion

### Landmarks used
- hip (side-specific)
- knee (side-specific)
- ankle (side-specific)

---

## 9. GLUTEAL ASSESSMENT

### Assessment Logic
- **Measurement**: Hip-Knee-Ankle angle
- **Low**: Angle ≤ 130° - Leg extended, good flexion
- **Moderate**: 145° ≤ angle < 160° - Partial flexion
- **Severe**: Angle < 190° - Poor flexion

### Landmarks used
- hip (side-specific)
- knee (side-specific)
- ankle (side-specific)

---

## 10. CALVES ASSESSMENT

### Assessment Logic
- **Measurement**: Normalized displacement (knee-to-ankle horizontal distance / body segment height)
- **Severe**: < 0.15 - Minimal forward knee movement, severe dorsiflexion limitation
- **Moderate**: 0.15 ≤ displacement < 0.30 - Partial forward movement
- **Good**: ≥ 0.30 - Good forward knee movement over ankle

### Landmarks used
- hip (side-specific) – used for vertical body segment height with ankle
- knee (side-specific) – used for horizontal displacement vs ankle
- ankle (side-specific)
- Alignment cue: knee relative to ankle ("knee forward" vs "behind/inline")
