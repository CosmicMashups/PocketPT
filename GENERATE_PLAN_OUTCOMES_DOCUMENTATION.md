# Generate Plan Page - Complete Outcomes Documentation

This document comprehensively lists all possible results/outputs in the `generate_plan.dart` page based on different user input combinations.

## Required Inputs

The `GeneratePlanPage` relies on the following user assessment data from `UserAssess`:

### Primary Inputs
1. **`specificMuscle`** (String): The specific muscle selected for rehabilitation
   - Examples: "Shoulder", "Knee", "Back", etc.
   - Source: User selection in assessment flow

2. **`painLevel`** (String): Categorical pain level
   - Possible values: "Mild", "Moderate", "Severe"
   - Source: User selection in pain assessment

3. **`painDuration`** (String): Duration since pain/injury occurred
   - Possible values: "Less than 48 hours ago", "48 hours to 1 week", "1 week to 1 month", "More than 1 month"
   - Source: User selection in pain assessment

4. **`painScale`** (int): Numeric pain scale (0-10)
   - Used for determining severe pain threshold (>= 7)
   - Source: User input in pain scale assessment

5. **`rehabGoal`** (String): Functional rehabilitation goal
   - Examples: "Pain Relief", "Strength", "Flexibility", etc.
   - Source: User selection in initial assessment

### Secondary Inputs (Muscle Injury Assessment)
6. **`injuredMuscles`** (List<String>): List of muscles with previous injuries
   - Source: Muscle assessment page (`d_muscle.dart`)

7. **`musclePainLevels`** (Map<String, int>): Pain levels for each injured muscle (0-10)
   - Used for filtering exercises that target severely injured muscles (>= 8)
   - Source: Muscle assessment page

8. **`musclePainCategories`** (Map<String, String>): Pain categories for injured muscles
   - Source: Muscle assessment page

## Decision Flow Logic

The page follows this decision flow:

```
1. Check if exercise generation should be skipped
   ├─ IF (painLevel == "Severe" OR painDuration == "Less than 48 hours ago")
   │  └─ Skip exercise plan generation
   └─ ELSE
      └─ Attempt exercise plan generation

2. Always attempt treatment generation

3. Determine final state based on:
   ├─ IF (shouldShowExerciseWarning)
   │  └─ Show treatments only with warning
   ├─ ELSE IF (plan == null AND treatments == null/empty)
   │  └─ Show error state
   └─ ELSE
      └─ Show plan/treatments (or treatments only)
```

## Possible Outputs/Results

### Output State 1: Loading State
**Condition**: Initial state or during plan/treatment generation

**UI Display**:
- Loading indicator with message "Generating Your Treatment Plan"
- No content sections visible

**When It Occurs**:
- Page first loads (`initState()` calls `_loadPlan()`)
- User clicks "Try Again" button after an error

**Required Inputs**: Any combination (loading is initial state)

---

### Output State 2: Error State
**Condition**: 
- `plan == null` AND (`treatmentReferences == null` OR `treatmentReferences.isEmpty`)
- Exception thrown during plan/treatment generation

**UI Display**:
- Error icon and message
- Error text: "⚠️ Not enough matching exercises or treatments found." OR "❌ An error occurred: [error message]"
- "Try Again" button

**Required Inputs to Trigger**:
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`
- No matching exercises found in CSV (based on `specificMuscle`, `painLevel`, `rehabGoal`)
- No matching treatments found (based on `specificMuscle`, `painLevel`, `painDuration`)
- OR: Exception during generation process

**Example Scenarios**:
1. User selects uncommon muscle with no exercises in database
2. User selects pain level/goal combination with no matching exercises
3. CSV file loading fails
4. Network error during Firebase sync

---

### Output State 3: Treatments Only (With Exercise Warning)
**Condition**: 
- `painLevel == "Severe"` OR `painDuration == "Less than 48 hours ago"`
- `treatmentReferences` is not null and not empty

**UI Display**:
- Header: "Your Rehabilitation Plan" with week number and muscle name
- **Treatments Section**: List of treatment cards (if available)
- **Warning Message**: One of the following:
  - "Your assessed pain score is in the severe range (7-10). Exercises are not recommended at this time, so we will focus on treatments only."
  - "You reported pain within the last 48 hours, so we recommend resting before resuming exercises. Only treatments are available for now."
- **No Exercises Section**
- "Complete Assessment & Go Home" button

**Required Inputs**:
- `painLevel == "Severe"` OR `painDuration == "Less than 48 hours ago"`
- `specificMuscle` must match treatments in CSV
- `painLevel` must match treatment criteria
- `painDuration` must match treatment criteria

**Data Persistence**:
- Treatments saved to `UserRehabilitation.instance.treatmentReferences`
- Saved to both Hive and Firebase

**Example Scenarios**:
1. User reports severe pain (7-10 on scale) → Only treatments shown
2. User reports pain within last 48 hours → Only treatments shown
3. User has both severe pain AND recent injury → Only treatments shown

---

### Output State 4: Exercises + Treatments (Full Plan)
**Condition**: 
- `plan != null` (valid RehabilitationPlan generated)
- `treatmentReferences` is not null and not empty
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`

**UI Display**:
- Header: "Your Rehabilitation Plan" with week number and muscle name
- **Treatments Section**: List of treatment cards
- **Exercises Section**: List of exercise cards (3 exercises max)
- No warning message
- "Complete Assessment & Go Home" button

**Required Inputs**:
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`
- `specificMuscle` matches exercises in CSV
- `painLevel` matches exercise criteria
- `rehabGoal` matches exercise criteria
- At least 2 matching exercises found (after filtering)
- `specificMuscle` matches treatments in CSV
- `painLevel` matches treatment criteria
- `painDuration` matches treatment criteria

**Data Persistence**:
- Plan saved to `UserRehabilitation.instance.rehabPlans`
- Treatments saved to `UserRehabilitation.instance.treatmentReferences`
- Saved to both Hive and Firebase

**Example Scenarios**:
1. User has moderate pain, pain occurred 1 week ago, matching exercises and treatments found
2. User has mild pain, pain occurred 1 month ago, matching exercises and treatments found

---

### Output State 5: Exercises Only (No Treatments)
**Condition**: 
- `plan != null` (valid RehabilitationPlan generated)
- `treatmentReferences == null` OR `treatmentReferences.isEmpty`
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`

**UI Display**:
- Header: "Your Rehabilitation Plan" with week number and muscle name
- **Exercises Section**: List of exercise cards (3 exercises max)
- **No Treatments Section**
- Warning message: "No exercises or treatments available at this time. Please try again or contact support." (if no treatments)
- "Complete Assessment & Go Home" button

**Required Inputs**:
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`
- `specificMuscle` matches exercises in CSV
- `painLevel` matches exercise criteria
- `rehabGoal` matches exercise criteria
- At least 2 matching exercises found
- `specificMuscle` does NOT match treatments OR `painLevel`/`painDuration` do not match treatment criteria

**Data Persistence**:
- Plan saved to `UserRehabilitation.instance.rehabPlans`
- No treatments saved

**Example Scenarios**:
1. User has matching exercises but no matching treatments for their muscle/pain combination
2. Treatment CSV has no entries for the selected muscle

---

### Output State 6: Treatments Only (No Exercises, No Warning)
**Condition**: 
- `plan == null` (exercise generation skipped or failed)
- `treatmentReferences` is not null and not empty
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`

**UI Display**:
- Header: "Your Rehabilitation Plan" with week number and muscle name
- **Treatments Section**: List of treatment cards
- **No Exercises Section**
- Warning message: "No exercises or treatments available at this time. Please try again or contact support." (if no exercises)
- "Complete Assessment & Go Home" button

**Required Inputs**:
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`
- Exercise generation returns null (user cancelled muscle injury dialog, chose "treatments only", or < 2 exercises found)
- `specificMuscle` matches treatments in CSV
- `painLevel` matches treatment criteria
- `painDuration` matches treatment criteria

**Data Persistence**:
- No plan saved
- Treatments saved to `UserRehabilitation.instance.treatmentReferences`
- Saved to both Hive and Firebase

**Example Scenarios**:
1. User has muscle injuries that filter out all exercises, but chooses "treatments only" in dialog
2. User has < 2 matching exercises but has matching treatments
3. User cancels muscle injury dialog, but treatments are still generated

---

### Output State 7: Empty State (No Exercises, No Treatments, No Warning)
**Condition**: 
- `plan == null`
- `treatmentReferences == null` OR `treatmentReferences.isEmpty`
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`

**UI Display**:
- Header: "Your Rehabilitation Plan" with week number and muscle name
- **No Exercises Section**
- **No Treatments Section**
- Warning message based on reason:
  - If `_hasFilteredOtherMuscles()`: "Your selected "Other Muscles" filters removed all available exercises. You can unfilter those muscles from the History screen and try again, or continue with treatments only."
  - Otherwise: "No exercises or treatments available at this time. Please try again or contact support."
- "Complete Assessment & Go Home" button

**Required Inputs**:
- `painLevel != "Severe"` AND `painDuration != "Less than 48 hours ago"`
- No matching exercises found OR user cancelled/chose treatments only
- No matching treatments found

**Data Persistence**:
- No plan saved
- No treatments saved

**Example Scenarios**:
1. User has muscle injuries that filter out all exercises, and no matching treatments
2. User selects muscle/pain combination with no exercises or treatments in database
3. User cancels muscle injury dialog and no treatments match

---

## Special Cases: Muscle Injury Dialog

When exercise generation is attempted and the user has severely injured muscles (pain level >= 8), a dialog may appear:

### Dialog Conditions
- `filteredExercises.length < 3`
- `severelyInjuredMuscles.isNotEmpty` (muscles with pain level >= 8)

### Dialog Outcomes

**1. User Chooses "Include All Exercises"**
- **Result**: Plan generated with all matching exercises (ignoring muscle injury filter)
- **Output State**: State 4, 5, or 6 (depending on treatments)

**2. User Chooses "Keep Safe Exercises Only"**
- **Result**: Plan generated with only safe exercises (excluding severely injured muscles)
- **Output State**: State 4, 5, or 6 (depending on treatments)

**3. User Chooses "Treatments Only"**
- **Result**: `plan == null`, treatments still generated
- **Output State**: State 6 (Treatments Only, No Exercises)

**4. User Cancels Dialog**
- **Result**: `plan == null`, treatments still generated
- **Output State**: State 6 (Treatments Only, No Exercises) OR State 2 (Error) if no treatments

**5. Dialog Dismissed (Context Unmounted)**
- **Result**: Falls back to safe behavior
- **Output State**: State 4, 5, or 6 if >= 2 exercises found, otherwise State 2 or 6

---

## Input-Output Matrix

| Pain Level | Pain Duration | Exercises Found | Treatments Found | Muscle Injuries | Dialog Shown | Final Output State |
|------------|---------------|----------------|------------------|-----------------|--------------|-------------------|
| Severe | Any | N/A | Yes | Any | No | State 3 (Treatments Only with Warning) |
| Any | < 48 hours | N/A | Yes | Any | No | State 3 (Treatments Only with Warning) |
| Not Severe | > 48 hours | Yes (>=2) | Yes | None/Minor | No | State 4 (Exercises + Treatments) |
| Not Severe | > 48 hours | Yes (>=2) | No | None/Minor | No | State 5 (Exercises Only) |
| Not Severe | > 48 hours | No | Yes | Any | No | State 6 (Treatments Only) |
| Not Severe | > 48 hours | Yes (<3) | Any | Severe (>=8) | Yes | State 4/5/6 (Based on dialog choice) |
| Not Severe | > 48 hours | No | No | Any | No | State 7 (Empty with Message) |
| Not Severe | > 48 hours | Yes (>=2) | Yes | Severe (>=8) | Yes | State 4/5/6 (Based on dialog choice) |

---

## Status Messages

The page displays different status messages based on conditions:

1. **Severe Pain Message**: "Your assessed pain score is in the severe range (7-10). Exercises are not recommended at this time, so we will focus on treatments only."
   - Trigger: `UserAssess.painScale >= 7`

2. **Recent Pain Message**: "You reported pain within the last 48 hours, so we recommend resting before resuming exercises. Only treatments are available for now."
   - Trigger: `UserAssess.painDuration.toLowerCase() == 'less than 48 hours ago'`

3. **Filtered Muscles Message**: "Your selected "Other Muscles" filters removed all available exercises. You can unfilter those muscles from the History screen and try again, or continue with treatments only."
   - Trigger: `_hasFilteredOtherMuscles()` returns true (injured muscles with pain level >= 8)

4. **Generic Empty Message**: "No exercises or treatments available at this time. Please try again or contact support."
   - Trigger: No exercises and no treatments, and none of the above conditions

---

## Data Persistence Behavior

### When Data is Saved
- **State 3 (Treatments Only with Warning)**: Treatments saved to Hive and Firebase
- **State 4 (Exercises + Treatments)**: Both plan and treatments saved to Hive and Firebase
- **State 5 (Exercises Only)**: Plan saved to Hive and Firebase
- **State 6 (Treatments Only)**: Treatments saved to Hive and Firebase
- **State 2 (Error)**: No data saved
- **State 7 (Empty)**: No data saved

### Completion Flow
When user clicks "Complete Assessment & Go Home":
1. Sets `UserDetails.hasCompletedAssessment = true`
2. Marks assessment as completed in Firebase
3. Sets `UserAssess.isAssessed = true`
4. Saves all data to Hive and Firebase
5. Sets `ActiveProgram.startDate` if not set
6. Navigates to `AuthWrapper` (routes to Home page)

---

## Error Handling

### Exception Scenarios
1. **CSV Loading Error**: Shows error state with message "❌ An error occurred: [error]"
2. **Firebase Sync Error**: Shows snackbar with specific error message, but still navigates
3. **Context Unmounted**: Checks `mounted` before setState and navigation
4. **Network Error**: Assessment saved locally, sync attempted later

### Error Recovery
- User can click "Try Again" button to retry plan generation
- Error messages are user-friendly and actionable
- Local data is preserved even if Firebase sync fails

---

## Summary

The `GeneratePlanPage` can produce **7 distinct output states** based on combinations of:
- Pain level (Severe vs. Not Severe)
- Pain duration (Recent vs. Not Recent)
- Exercise availability (Found vs. Not Found)
- Treatment availability (Found vs. Not Found)
- Muscle injury status (None/Minor vs. Severe)
- User dialog choices (Include All, Keep Safe, Treatments Only, Cancel)

The page always attempts to generate treatments, but exercise generation is conditionally skipped based on pain severity and recency. The final UI state is determined by what data is successfully generated and what safety warnings need to be displayed.

