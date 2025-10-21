# Firestore Rules Addition for Custom Exercises

## Required Addition to firestore.rules

Add the following rule to the existing `firestore.rules` file, after the existing collections and before the default deny rule:

```javascript
// Custom exercises collection - User-specific custom exercises
match /customExercises/{userId}/exercises/{exerciseId} {
  allow read: if isOwner(userId);
  allow create: if isOwner(userId) && 
    isValidUserId(request.resource.data.userId);
  allow update: if isOwner(userId) && 
    isValidUserId(request.resource.data.userId);
  allow delete: if isOwner(userId);
}
```

## Integration Point

Insert this rule after line 135 (after the backup collections rule) and before line 136 (before the default deny rule) in the existing `firestore.rules` file.

## Rule Explanation

- **Collection Path**: `customExercises/{userId}/exercises/{exerciseId}`
  - `userId`: The authenticated user's UID
  - `exerciseId`: The unique identifier for the custom exercise (CE### format)

- **Access Control**:
  - `read`: Users can only read their own custom exercises
  - `create`: Users can only create exercises with their own userId
  - `update`: Users can only update exercises with their own userId
  - `delete`: Users can only delete their own exercises

- **Security**: Leverages existing helper functions (`isOwner`, `isValidUserId`) for consistent security validation

## Testing

After adding this rule, test with:
1. Authenticated user creating custom exercises
2. Attempting to access another user's custom exercises (should be denied)
3. Creating exercises with incorrect userId (should be denied)
