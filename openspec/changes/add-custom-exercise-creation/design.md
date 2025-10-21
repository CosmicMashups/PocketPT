## Context
The current exercise management system relies solely on a predefined CSV file (`assets/data/exercises.csv`) containing exercise data. Users can only select from existing exercises when building rehabilitation plans. This limitation prevents customization for specific patient needs or therapist preferences.

## Goals / Non-Goals
- Goals: 
  - Enable users to create custom exercises with full metadata
  - Persist custom exercises both locally and in Firebase for cross-device access
  - Integrate custom exercises seamlessly with existing exercise selection flow
  - Maintain data consistency with existing CSV structure
  - Sync custom exercises across user devices via Firebase
- Non-Goals:
  - Exercise sharing between users (user-specific only)
  - Advanced exercise editing capabilities (create-only for now)

## Decisions
- Decision: Use dual storage approach (local CSV + Firebase)
  - Alternatives considered: Local only, Firebase only, Hive database, SQLite
  - Rationale: Provides offline access via local CSV while enabling cross-device sync via Firebase
- Decision: Generate unique Exercise IDs using CE### format for custom exercises
  - Alternatives considered: UUID, timestamp-based, user-defined, E### format
  - Rationale: Distinguishes custom exercises from predefined ones (CE vs E), maintains consistency
- Decision: Show modal bottom sheet for exercise creation options
  - Alternatives considered: Separate page, inline form, popup dialog
  - Rationale: Better UX than navigation, maintains context, follows Material Design patterns
- Decision: Use Firebase collection structure: customExercises/{userId}/exercises/{exerciseId}
  - Alternatives considered: Flat collection, nested under users, separate collection
  - Rationale: Follows existing Firebase patterns, enables user-specific access control

## Risks / Trade-offs
- Risk: File system access limitations on some platforms → Mitigation: Use path_provider for cross-platform file access
- Risk: CSV corruption during concurrent writes → Mitigation: Implement file locking and error handling
- Risk: Large custom exercise files affecting performance → Mitigation: Implement lazy loading and caching

## Migration Plan
1. Implement custom exercise creation feature
2. Update exercise loading to merge default and custom exercises
3. Add proper error handling and user feedback
4. Test on multiple platforms for file system compatibility

## Firebase Integration

### Collection Structure
```
customExercises/{userId}/exercises/{exerciseId}
```

### Document Schema
```json
{
  "exerciseId": "CE001",
  "name": "Custom Exercise Name",
  "description": "Detailed exercise description",
  "muscle": "Primary muscle group",
  "painLevel": "Low|Moderate|High",
  "goal": "Functional goal",
  "rep": 10,
  "set": 3,
  "imageUrl": "exercise.jpg",
  "videoUrl": "https://example.com/video",
  "otherMuscles": "Additional muscles involved",
  "createdAt": "timestamp",
  "lastModified": "timestamp",
  "userId": "user_uid"
}
```

### Firestore Rules Addition
```javascript
// Custom exercises collection - User-specific custom exercises
match /customExercises/{userId}/exercises/{exerciseId} {
  allow read, write: if isOwner(userId) && 
    isValidUserId(request.resource.data.userId);
}
```

## Open Questions
- Should custom exercises be editable after creation?
- How should we handle custom exercise deletion?
- Should there be limits on the number of custom exercises?
- Should custom exercises sync immediately or batch sync?
