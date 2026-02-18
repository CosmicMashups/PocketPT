# Loading Indicators Implementation Guide

## Overview
This guide demonstrates the enhanced loading indicators implemented to show when data is still being loaded across the PocketPT application. The solution provides multiple types of loading indicators with progress tracking and visual feedback.

## Enhanced Features

### 1. Progress-Based Loading Indicators
- **Circular Progress**: Shows completion percentage with visual progress ring
- **Data Type Tracking**: Individual loading status for each data type
- **Real-time Updates**: Progress updates as each data type loads
- **Visual Feedback**: Check marks for completed data types

### 2. Multiple Loading Indicator Types

#### A. DataLoadingWrapper with Progress
```dart
DataLoadingWrapper(
  requiredDataTypes: ['userData', 'userProgress', 'userSettings'],
  showProgressIndicator: true,
  loadingMessage: 'Loading User Profile',
  child: YourPageWidget(),
)
```

#### B. UserDataLoadingWrapper with Progress
```dart
UserDataLoadingWrapper(
  showProgressIndicator: true,
  loadingMessage: 'Loading User Data',
  child: ProfilePage(),
)
```

#### C. RehabDataLoadingWrapper with Progress
```dart
RehabDataLoadingWrapper(
  showProgressIndicator: true,
  loadingMessage: 'Loading Rehabilitation Data',
  child: DashboardPage(),
)
```

### 3. Specialized Loading Components

#### A. LoadingIndicator Widget
```dart
// Basic loading indicator
LoadingIndicator(
  message: 'Loading data...',
  size: 40,
)

// Inline loading indicator
LoadingIndicator(
  message: 'Loading...',
  isInline: true,
  size: 20,
)
```

#### B. ProgressIndicator Widget
```dart
ProgressIndicator(
  progress: 0.7, // 70% complete
  message: 'Loading exercises...',
  showPercentage: true,
)
```

#### C. Skeleton Loading Components
```dart
// Single skeleton loader
SkeletonLoader(
  width: 200,
  height: 100,
  borderRadius: BorderRadius.circular(8),
)

// List of skeleton loaders
SkeletonList(
  itemCount: 5,
  itemHeight: 60,
  spacing: 8,
)

// Card skeleton loader
SkeletonCard(
  height: 120,
  padding: EdgeInsets.all(16),
)
```

## Implementation Examples

### 1. Dashboard Page Loading States

#### User Data Loading in Header
```dart
Flexible(
  child: UserDataNotifier.instance.shouldShowLoading
      ? Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading user data...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        )
      : Text(
          UserDataNotifier.instance.isEmpty 
            ? 'Welcome to PocketPT'
            : '${UserDataNotifier.instance.firstName} ${UserDataNotifier.instance.lastName}',
          // ... rest of the text styling
        ),
),
```

#### Treatment Plan Section Loading
```dart
Column(
  children: UserRehabilitation.instance.rehabPlans.isEmpty
      ? [
          // Show loading indicator if data is still loading
          if (UserDataNotifier.instance.shouldShowLoading)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                // ... styling
              ),
              child: const LoadingIndicator(
                message: 'Loading treatment plans...',
                size: 40,
              ),
            )
          else
            // Assessment Required Card
            Container(
              // ... assessment card content
            ),
        ]
      : UserRehabilitation.instance.rehabPlans.map((plan) {
          // ... plan content
        }).toList(),
)
```

### 2. Profile Page Loading States

#### Profile Information Loading
```dart
Flexible(
  child: UserDataNotifier.instance.shouldShowLoading
      ? Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(mainColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading profile...',
              style: TextStyle(
                fontSize: 16,
                color: detailColor,
              ),
            ),
          ],
        )
      : Text(
          UserDataNotifier.instance.isEmpty 
            ? 'User Profile'
            : '${UserDataNotifier.instance.firstName} ${UserDataNotifier.instance.lastName}',
          // ... rest of the text styling
        ),
),
```

### 3. Exercise Manager Loading States

#### Exercise Data Loading
```dart
if (_isLoadingExercises) {
  return Scaffold(
    backgroundColor: backgroundColor,
    appBar: _buildAppBar("Exercise Manager"),
    body: const Center(
      child: LoadingIndicator(
        message: 'Loading exercise data...',
        size: 40,
      ),
    ),
  );
}
```

### 4. Pre-Record Page Loading States

#### Camera Initialization Loading
```dart
_isCameraInitialized && _controller != null
    ? Container(
        // ... camera preview
      )
    : _isInitializingCamera
        ? const Center(
            child: LoadingIndicator(
              message: 'Initializing camera...',
              size: 40,
            ),
          )
        : Container(
            // ... camera not available
          ),
```

## Progress Tracking Features

### 1. Data Type Progress Display
The enhanced loading wrapper shows individual progress for each data type:

- **User Profile**: User data loading status
- **Progress Data**: User progress loading status  
- **Settings**: User settings loading status
- **Assessment**: User assessment loading status
- **Rehabilitation Plans**: Treatment plans loading status
- **Pain History**: Pain records loading status
- **Exercise History**: Exercise records loading status

### 2. Visual Progress Indicators
- **Circular Progress Ring**: Shows overall completion percentage
- **Individual Check Marks**: Green checkmarks for completed data types
- **Loading Spinners**: Small spinners for data types still loading
- **Progress Percentage**: Numerical percentage display

### 3. Loading State Management
- **shouldShowLoading**: Determines when to show loading indicators
- **isFullyLoaded**: Checks if user data is completely loaded
- **isEmpty**: Checks if user data is empty (not loaded yet)

## Customization Options

### 1. Loading Messages
```dart
DataLoadingWrapper(
  loadingMessage: 'Custom loading message...',
  child: YourWidget(),
)
```

### 2. Progress Display
```dart
DataLoadingWrapper(
  showProgressIndicator: true, // Show detailed progress
  child: YourWidget(),
)
```

### 3. Custom Loading Widgets
```dart
DataLoadingWrapper(
  loadingWidget: CustomLoadingWidget(),
  errorWidget: CustomErrorWidget(),
  child: YourWidget(),
)
```

### 4. Inline Loading Indicators
```dart
LoadingIndicator(
  message: 'Loading...',
  isInline: true,
  size: 20,
  showMessage: false, // Hide message for compact display
)
```

## Best Practices

### 1. Use Appropriate Loading Indicators
- **Full Page Loading**: Use `DataLoadingWrapper` for entire pages
- **Section Loading**: Use `LoadingIndicator` for specific sections
- **Inline Loading**: Use `LoadingIndicator` with `isInline: true`
- **Skeleton Loading**: Use skeleton components for content placeholders

### 2. Provide Meaningful Messages
- Be specific about what's loading
- Use user-friendly language
- Keep messages concise but informative

### 3. Handle Loading States Properly
- Always check `shouldShowLoading` before showing content
- Use `isEmpty` to determine if data needs to be loaded
- Provide fallback content for empty states

### 4. Optimize Performance
- Use `showProgressIndicator: false` for simple loading states
- Implement skeleton loading for better perceived performance
- Cache loading states to avoid unnecessary rebuilds

## Error Handling

### 1. Loading Errors
```dart
DataLoadingWrapper(
  errorWidget: CustomErrorWidget(),
  child: YourWidget(),
)
```

### 2. Retry Functionality
The default error widget includes retry functionality that automatically reloads the data.

### 3. Fallback Content
Always provide meaningful fallback content when data is empty or loading fails.

## Testing Loading States

### 1. Test Different Loading Scenarios
- Fresh app installation
- App restart with existing data
- Network connectivity issues
- Data corruption scenarios

### 2. Verify Loading Indicators
- Check that loading indicators appear
- Verify progress updates correctly
- Test error states and retry functionality
- Validate loading performance

### 3. Test User Experience
- Ensure loading states are not too long
- Verify smooth transitions between states
- Check accessibility of loading indicators
- Test on different device sizes

## Conclusion

The enhanced loading indicators provide comprehensive visual feedback when data is being loaded, ensuring users always know the application state and preventing confusion from blank or empty pages. The solution includes multiple loading indicator types, progress tracking, and customizable options to fit different use cases throughout the application.
