## 1. Hive Adapter Registration

- [x] 1.1 Add HiveCustomExerciseAdapter registration check and registration in `lib/main.dart` after adapter typeId 12
- [x] 1.2 Add HiveCustomExerciseAdapter registration check and registration in `lib/data/globals.dart` after adapter typeId 12
- [x] 1.3 Test that custom exercises can be saved without HiveError exceptions

## 2. Custom Exercise Dialog UI Fixes

- [x] 2.1 Change dialog title from "Create Custom Exercise" to "Custom Exercise" in `_showCustomExerciseDialog()`
- [x] 2.2 Remove "Image Filename" TextFormField from the dialog
- [x] 2.3 Remove "Video URL" TextFormField from the dialog
- [x] 2.4 Update exercise creation code to automatically set `imageUrl` to ".jpg" and `videoUrl` to ".mp4"
- [x] 2.5 Test that dialog renders without horizontal overflow on all screen sizes

## 3. Muscle Group Dropdown Updates

- [x] 3.1 Define standardized muscle list constant: ['Deltoids', 'Biceps', 'Triceps', 'Upper Back', 'Lower Back', 'Abdominals', 'Obliques', 'Multifidus', 'Quadriceps', 'Hamstrings', 'Calf', 'Gluteals']
- [x] 3.2 Update muscle group dropdown items to use the standardized list (remove 'Chest', 'Back', 'Ankle', 'Cervical Muscle')
- [x] 3.3 Update default selected muscle to the first item in the standardized list if current default is not in list
- [x] 3.4 Test that all muscles in the list are selectable and displayed correctly

## 4. Other Muscles Dropdown Implementation

- [x] 4.1 Remove "Other Muscles" TextFormField from the dialog
- [x] 4.2 Add "Other Muscles" DropdownButtonFormField with the standardized muscle list
- [x] 4.3 Implement logic to filter out the selected primary muscle group from "Other Muscles" dropdown options
- [x] 4.4 Update state management to handle "Other Muscles" as a nullable String (since it's optional)
- [x] 4.5 Update exercise creation code to use selected "Other Muscles" value or empty string if none selected
- [x] 4.6 Test that primary muscle cannot be selected again in "Other Muscles" dropdown

## 5. Medical Support Dialog Scrollable Fix

- [x] 5.1 Wrap Medical Support dialog content in SingleChildScrollView or make dialog scrollable
- [x] 5.2 Test that all content is visible and scrollable on small screens
- [x] 5.3 Verify dialog doesn't overflow vertically on any device or screen size

## 6. Remove Exercise Dialog Button Fix

- [x] 6.1 Update "Delete" confirmation dialog button styling to use white text color on dark-red background
- [x] 6.2 Ensure button styling is consistent with app theme and remains accessible
- [x] 6.3 Test that button text is clearly visible in both light and dark themes

## 7. Firebase Storage Alignment

- [x] 7.1 Verify that default image/video URLs (".jpg", ".mp4") are correctly saved to Firebase customExercises collection
- [x] 7.2 Ensure data structure matches between Hive and Firebase for new default fields
- [x] 7.3 Test custom exercise creation, update, and deletion sync correctly with both Hive and Firebase

## 8. Validation and Testing

- [x] 8.1 Test custom exercise creation with all field combinations
- [x] 8.2 Verify Hive persistence works without errors
- [x] 8.3 Verify Firebase sync works correctly with default image/video URLs
- [x] 8.4 Test dialog rendering on multiple screen sizes (small, medium, large)
- [x] 8.5 Test muscle group selection and "Other Muscles" filtering
- [x] 8.6 Verify no visual overflow issues in any dialog
- [x] 8.7 Test exercise removal confirmation dialog button visibility

