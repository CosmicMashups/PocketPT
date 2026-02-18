# PocketPT Test Cases - Contextual Interpretation Guide

This document provides contextual basis for interpreting each test case in `PocketPT_TestCases_Extracted.txt`. It includes expected outputs, error messages, expected flows, and business logic rules.

## Application Overview

PocketPT is a physical therapy rehabilitation application that:
- Generates personalized rehabilitation plans based on user assessments
- Provides exercise and treatment recommendations
- Manages user authentication and registration
- Tracks rehabilitation progress

## Assessment System Context

### Assessment Flow

1. **User Input Collection:**
   - Rehab Goal: Alleviate Pain, Improve Mobility, or Strengthen Muscle
   - Muscle Selection: User selects the affected muscle group
   - Pain Level: 1-3 (Mild), 4-6 (Moderate), 7-10 (Severe)
   - Pain Duration: Time since injury/pain onset
   - Injury History: Related muscle groups with previous injuries

2. **Plan Generation Logic:**
   - **Exercises + Treatment Plan:** Generated when:
     - Pain level is 1-6 (Mild to Moderate), OR
     - Pain level is 7-10 (Severe) BUT there is related injury history
   - **Treatment Only Plan:** Generated when:
     - Pain level is 7-10 (Severe) AND no related injury history, OR
     - Pain level is 1-3 (Mild) AND pain duration is "Less than 48 hours ago"

3. **Special Rules:**
   - When pain is "Severe" (7-10) AND duration is "Less than 48 hours ago", exercises are NOT included (Treatment Only)
   - Related injury history triggers exercise inclusion even with severe pain
   - "Any" duration means any option EXCEPT "Less than 48 hours ago"

### Expected Assessment Outputs

**Exercises + Treatment Plan:**
- Contains rehabilitation exercises specific to the selected muscle
- Includes treatment recommendations (T001, T002, T003 - core treatments)
- Exercises are filtered by muscle group, pain level, and rehab goal
- Plan is displayed with exercise details (repetitions, sets, instructions)

**Treatment Only Plan:**
- Contains only treatment recommendations (T001, T002, T003)
- No exercises are included
- Warning message may be displayed: "Due to severe pain or recent injury, only treatments are recommended"
- User can still view and follow treatment instructions

### Assessment Error Scenarios

- **No Plan Generated:** System error message displayed, user can retry
- **Missing Data:** Validation errors if required fields are incomplete
- **Invalid Muscle Selection:** Error handling for unsupported muscle groups

---

## Login System Context

### Login Flow

1. **User Input:**
   - Email address (must be registered)
   - Password (must match registered password)

2. **Authentication Process:**
   - Email validation (format check)
   - Firebase authentication lookup
   - Password verification
   - Email verification status check
   - User data synchronization

3. **Success Flow:**
   - User authenticated successfully
   - User data loaded from Firebase/Hive
   - Navigation to home/dashboard
   - Session established

### Expected Login Error Messages

**Test Case 1: Registered email + Incorrect password**
- **Expected Error:** "Incorrect password"
- **Error Code:** `wrong-password`
- **User Action:** User can retry with correct password
- **UI Behavior:** Error message displayed below password field

**Test Case 2: Unregistered email + Any password**
- **Expected Error:** "No user found with this email"
- **Error Code:** `user-not-found`
- **User Action:** User should register or use correct email
- **UI Behavior:** Error message displayed, link to registration page may be shown

**Test Case 3: Registered email + Correct password**
- **Expected Result:** Login succeeds
- **Success Flow:**
  - Email verification check (if not verified, redirect to verification page)
  - User data synchronization
  - Navigation to main application
- **UI Behavior:** Loading indicator, then successful navigation

### Additional Login Error Scenarios

- **Invalid Email Format:** "Invalid email address"
- **Too Many Attempts:** "Too many attempts. Try again later"
- **Account Disabled:** "This account has been disabled"
- **Network Error:** "No internet connection. Please check your network and try again."
- **Connection Timeout:** "Connection timeout. Please check your internet connection and try again."

---

## Registration System Context

### Registration Flow

1. **User Input Collection:**
   - First Name (required, any value)
   - Last Name (required, any value)
   - Email Address (must be unregistered, valid format)
   - Password (must meet strength requirements)
   - Confirm Password (must match password)
   - Terms and Privacy Policy agreement (required)

2. **Validation Process:**
   - Form field validation (required fields)
   - Email format validation
   - Password strength validation
   - Password match validation
   - Email uniqueness check (Firebase)
   - Terms agreement check

3. **Success Flow:**
   - User account created in Firebase Auth
   - Email verification sent
   - User document created in Firestore
   - Redirect to email verification page
   - User must verify email before full access

### Password Validation Rules

Password must meet ALL of the following criteria:
- **Minimum Length:** At least 8 characters
- **Uppercase Letter:** At least one uppercase letter (A-Z)
- **Lowercase Letter:** At least one lowercase letter (a-z)
- **Number:** At least one digit (0-9)
- **Special Character:** At least one special character (!@#$%^&*(),.?":{}|<>)

### Expected Registration Error Messages

**Test Case 1: Missing lowercase letter**
- **Expected Error:** "Password must contain at least one lowercase letter"
- **Validation:** Fails at password strength check
- **UI Behavior:** Error message displayed below password field
- **User Action:** User must add lowercase letter to password

**Test Case 2: Missing uppercase letter**
- **Expected Error:** "Password must contain at least one uppercase letter"
- **Validation:** Fails at password strength check
- **UI Behavior:** Error message displayed below password field
- **User Action:** User must add uppercase letter to password

**Test Case 3: Missing symbol/special character**
- **Expected Error:** "Password must contain at least one special character"
- **Validation:** Fails at password strength check
- **UI Behavior:** Error message displayed below password field
- **User Action:** User must add special character to password

**Test Case 4: Missing number**
- **Expected Error:** "Password must contain at least one number"
- **Validation:** Fails at password strength check
- **UI Behavior:** Error message displayed below password field
- **User Action:** User must add number to password

**Test Case 5: Registered email address**
- **Expected Error:** "This email is already registered. Please use a different email or sign in."
- **Error Code:** `email-already-in-use`
- **Validation:** Fails at Firebase account creation
- **UI Behavior:** Error message displayed, link to login page may be shown
- **User Action:** User should use different email or sign in with existing account

**Test Case 6: Password mismatch**
- **Expected Error:** "Passwords do not match. Please ensure both passwords are identical."
- **Validation:** Fails at form validation (before Firebase call)
- **UI Behavior:** Error message displayed below confirm password field
- **User Action:** User must ensure both password fields match

**Test Case 7: Complete valid registration**
- **Expected Result:** Registration succeeds
- **Success Flow:**
  - Account created in Firebase Auth
  - Email verification email sent
  - User document created in Firestore with firstName, lastName, email
  - Redirect to email verification page
- **UI Behavior:** Loading indicator, then navigation to verification page
- **Next Steps:** User must verify email before full access

### Additional Registration Error Scenarios

- **Invalid Email Format:** "Please enter a valid email address"
- **Password Too Short:** "Password must be at least 8 characters long"
- **Missing First Name:** "First name is required"
- **Missing Last Name:** "Last name is required"
- **Terms Not Agreed:** "Please agree to the Terms and Privacy Policy"
- **Network Error:** "No internet connection. Please check your network and try again."
- **Connection Timeout:** "Connection timeout. Please check your internet connection and try again."

---

## Test Case Interpretation Guidelines

### Assessment Test Cases

For each assessment test case, verify:

1. **Input Validation:**
   - All required fields are provided
   - Muscle selection is valid
   - Pain level is within range (1-10)
   - Pain duration is a valid option

2. **Plan Generation Logic:**
   - Correct plan type is generated (Exercises + Treatment vs Treatment Only)
   - Plan matches expected output based on:
     - Rehab Goal
     - Pain Level
     - Pain Duration
     - Injury History

3. **Output Verification:**
   - Plan is successfully generated and displayed
   - Exercises (if included) are relevant to selected muscle
   - Treatments are included (always T001, T002, T003)
   - UI displays plan correctly with all details

4. **Edge Cases:**
   - "Less than 48 hours ago" with severe pain → Treatment Only
   - Related injury history with severe pain → Exercises + Treatment
   - "Any" duration should NOT select "Less than 48 hours ago"

### Login Test Cases

For each login test case, verify:

1. **Input Validation:**
   - Email format is validated
   - Password field is not empty

2. **Authentication Result:**
   - Correct error message is displayed for failures
   - Success flow navigates to correct page
   - Error messages are user-friendly and actionable

3. **Error Handling:**
   - Network errors are handled gracefully
   - Invalid credentials show appropriate messages
   - UI provides clear feedback

### Registration Test Cases

For each registration test case, verify:

1. **Input Validation:**
   - All required fields are validated
   - Email format is validated
   - Password strength is validated
   - Password match is validated

2. **Error Messages:**
   - Specific error messages for each validation failure
   - Error messages are displayed in appropriate fields
   - Error messages guide user to fix the issue

3. **Success Flow:**
   - Account is created successfully
   - Email verification is sent
   - User is redirected appropriately
   - User data is stored correctly

---

## Common UI Patterns

### Error Display
- Errors are displayed below the relevant input field
- Error messages are in red text
- Error icons may be displayed next to fields
- Form submission is prevented until errors are resolved

### Loading States
- Loading indicators are shown during async operations
- Buttons are disabled during loading
- User cannot submit multiple times

### Success States
- Success messages may be displayed briefly
- Navigation occurs after successful operations
- Data is persisted to local storage and/or Firebase

### Validation Timing
- **Real-time:** Email format, password strength (as user types)
- **On Submit:** Password match, terms agreement, all required fields
- **Server-side:** Email uniqueness, account creation

---

## Technical Implementation Notes

### Authentication Service
- Uses Firebase Authentication
- Password validation occurs client-side before Firebase call
- Email verification is required for full access
- Session management uses secure storage

### Assessment Service
- Plan generation reads from CSV files (exercises.csv, treatment.csv)
- Exercises are filtered by muscle, pain level, and goal
- Treatments are always the core three (T001, T002, T003)
- Plans are stored in Hive (local) and Firebase (cloud)

### Data Persistence
- User data: Firebase Firestore + Hive (local cache)
- Rehabilitation plans: Hive + Firebase
- Authentication state: Secure storage + Firebase

---

## Test Execution Checklist

### For Assessment Test Cases:
- [ ] All input fields are filled correctly
- [ ] Plan type matches expected output (Exercises + Treatment vs Treatment Only)
- [ ] Plan is successfully generated and displayed
- [ ] Exercises (if any) are relevant to selected muscle
- [ ] Treatments are included (T001, T002, T003)
- [ ] UI displays plan correctly

### For Login Test Cases:
- [ ] Correct error message is displayed for failures
- [ ] Success flow navigates correctly
- [ ] Error messages are user-friendly
- [ ] Network errors are handled

### For Registration Test Cases:
- [ ] Validation errors are displayed correctly
- [ ] Error messages are specific and actionable
- [ ] Success flow creates account and sends verification
- [ ] All validation rules are enforced

---

## Notes

- "Any" values in test cases mean any valid option EXCEPT "Less than 48 hours ago" (unless explicitly stated)
- Password validation is case-sensitive
- Email addresses are case-insensitive
- All dates/times are in user's local timezone
- Network connectivity is required for authentication and plan generation
- Offline mode may have limited functionality





