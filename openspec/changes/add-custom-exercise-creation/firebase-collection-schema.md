# Firebase Collection Schema for Custom Exercises

## Collection Structure

```
customExercises/{userId}/exercises/{exerciseId}
```

## Document Schema

Each custom exercise document follows this structure:

```json
{
  "exerciseId": "CE001",
  "name": "Custom Exercise Name",
  "description": "Detailed exercise description explaining how to perform the exercise",
  "muscle": "Primary muscle group (e.g., Deltoids, Biceps, Quadriceps)",
  "painLevel": "Low|Moderate|High",
  "goal": "Functional goal (e.g., Alleviate Pain, Build Strength, Improve Mobility)",
  "rep": 10,
  "set": 3,
  "imageUrl": "exercise.jpg",
  "videoUrl": "https://example.com/video",
  "otherMuscles": "Additional muscles involved",
  "createdAt": "2024-01-15T10:30:00Z",
  "lastModified": "2024-01-15T10:30:00Z",
  "userId": "user_uid_here"
}
```

## Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| exerciseId | string | Yes | Unique identifier with CE### format |
| name | string | Yes | Exercise name (3+ characters) |
| description | string | Yes | Detailed description (10+ characters) |
| muscle | string | Yes | Primary muscle group |
| painLevel | string | Yes | Pain level (Low/Moderate/High) |
| goal | string | Yes | Functional goal |
| rep | number | Yes | Number of repetitions (≥1) |
| set | number | Yes | Number of sets (≥1) |
| imageUrl | string | No | Image filename (defaults to "exercise.jpg") |
| videoUrl | string | No | Video URL (optional) |
| otherMuscles | string | No | Additional muscles involved |
| createdAt | timestamp | Yes | Creation timestamp |
| lastModified | timestamp | Yes | Last modification timestamp |
| userId | string | Yes | User ID for security validation |

## Example Documents

### Custom Exercise CE001
```json
{
  "exerciseId": "CE001",
  "name": "Custom Shoulder Stretch",
  "description": "A personalized shoulder stretch designed specifically for this patient's range of motion limitations",
  "muscle": "Deltoids",
  "painLevel": "Low",
  "goal": "Alleviate Pain",
  "rep": 8,
  "set": 2,
  "imageUrl": "custom_shoulder_stretch.jpg",
  "videoUrl": "",
  "otherMuscles": "Upper trapezius, Rotator cuff",
  "createdAt": "2024-01-15T10:30:00Z",
  "lastModified": "2024-01-15T10:30:00Z",
  "userId": "abc123def456"
}
```

### Custom Exercise CE002
```json
{
  "exerciseId": "CE002",
  "name": "Therapeutic Walking Pattern",
  "description": "A modified walking exercise to improve gait and reduce hip pain during movement",
  "muscle": "Quadriceps",
  "painLevel": "Moderate",
  "goal": "Improve Mobility",
  "rep": 15,
  "set": 3,
  "imageUrl": "exercise.jpg",
  "videoUrl": "https://example.com/walking_pattern_video",
  "otherMuscles": "Hamstrings, Glutes, Calves",
  "createdAt": "2024-01-15T14:45:00Z",
  "lastModified": "2024-01-15T14:45:00Z",
  "userId": "abc123def456"
}
```

## Integration with Existing System

- Custom exercises use the same data structure as predefined exercises for seamless integration
- Exercise IDs use "CE" prefix to distinguish from predefined "E" prefix
- All validation rules from the UI form apply to Firebase documents
- Documents are automatically timestamped for audit purposes
