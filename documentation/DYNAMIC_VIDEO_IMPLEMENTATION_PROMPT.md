# Dynamic Video Implementation Prompt

## Overview
Transform the static video display in `c_video.dart` into a dynamic system that displays muscle-specific YouTube videos based on the selected muscle from the assessment flow. The system should use the `youtube_player_iframe` package to display YouTube videos dynamically.

## Technical Requirements

### 1. Package Integration
- Add `youtube_player_iframe: ^3.0.0` to `pubspec.yaml` dependencies
- Import the package in `c_video.dart`
- Ensure proper initialization and disposal of YouTube player instances

### 2. Video Mapping System
Create a comprehensive mapping system that associates each muscle with its corresponding YouTube video URL:

```dart
class MuscleVideoMapping {
  static const Map<String, String> muscleVideos = {
    // Upper Body Muscles
    'Deltoids': 'https://youtu.be/am0-6R-ceEs',
    'Chest': 'https://youtu.be/am0-6R-ceEs',
    'Triceps': 'https://youtu.be/oyRbGqmOeB4',
    'Biceps': 'https://www.youtube.com/shorts/Hs6FQNoI2TM',
    'Cervical Muscle': 'https://youtu.be/am0-6R-ceEs', // Default to Deltoids video
    
    // Lower Body Muscles
    'Quadriceps': 'https://www.youtube.com/shorts/THG-qpHlP90',
    'Hamstrings': 'https://www.youtube.com/shorts/dkG8439CpVY',
    'Gluteals': 'https://www.youtube.com/shorts/dkG8439CpVY',
    'Calf': 'https://www.youtube.com/shorts/THG-qpHlP90', // Default to Quadriceps
    'Ankle': 'https://www.youtube.com/shorts/THG-qpHlP90', // Default to Quadriceps
    
    // Core Muscles
    'Abdominals': 'https://www.youtube.com/shorts/os2gPnQGIQs',
    'Obliques': 'https://www.youtube.com/shorts/os2gPnQGIQs',
    'Lower Back': 'https://www.youtube.com/shorts/os2gPnQGIQs',
    'Multifidus': 'https://www.youtube.com/shorts/os2gPnQGIQs',
  };
  
  static String getVideoUrl(String muscleName) {
    return muscleVideos[muscleName] ?? muscleVideos['Deltoids']!; // Fallback to Deltoids
  }
}
```

### 3. Dynamic Video Player Implementation
Replace the static `LocalVideoPlayer` with a dynamic YouTube player:

```dart
class DynamicVideoPlayer extends StatefulWidget {
  final String muscleName;
  
  const DynamicVideoPlayer({super.key, required this.muscleName});
  
  @override
  State<DynamicVideoPlayer> createState() => _DynamicVideoPlayerState();
}

class _DynamicVideoPlayerState extends State<DynamicVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  void _initializePlayer() {
    try {
      final videoUrl = MuscleVideoMapping.getVideoUrl(widget.muscleName);
      _controller = YoutubePlayerController.fromVideoId(
        videoId: YoutubePlayerController.convertUrlToId(videoUrl) ?? '',
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showLiveFullscreenButton: true,
          mute: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
      
      _controller.addListener(_onPlayerStateChange);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }
  
  void _onPlayerStateChange() {
    // Handle player state changes if needed
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'Video unavailable',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}
```

### 4. Integration with Assessment Data
Modify the `_buildVideoSection()` method in `c_video.dart` to use the dynamic player:

```dart
Widget _buildVideoSection() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.video_library, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              "Instructional Video",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DynamicVideoPlayer(
          muscleName: UserAssess.specificMuscle.isNotEmpty 
              ? UserAssess.specificMuscle 
              : AssessmentData.specificMuscle.isNotEmpty 
                  ? AssessmentData.specificMuscle 
                  : 'Deltoids', // Fallback
        ),
      ],
    ),
  );
}
```

### 5. Error Handling and Fallbacks
Implement comprehensive error handling:

- **Network Issues**: Display a retry button and offline message
- **Invalid URLs**: Fallback to a default video (Deltoids)
- **Missing Muscle**: Use the first available video as fallback
- **Player Initialization Failures**: Show error state with retry option

### 6. Performance Optimizations
- **Lazy Loading**: Only initialize the player when the video section is visible
- **Memory Management**: Properly dispose of controllers when not needed
- **Caching**: Cache video metadata to avoid repeated URL parsing

### 7. User Experience Enhancements
- **Loading States**: Show loading indicators while videos load
- **Error Recovery**: Provide retry mechanisms for failed loads
- **Accessibility**: Ensure proper ARIA labels and screen reader support
- **Responsive Design**: Maintain aspect ratio across different screen sizes

### 8. Testing Requirements
- **Unit Tests**: Test the muscle-to-video mapping logic
- **Widget Tests**: Test the dynamic video player widget
- **Integration Tests**: Test the complete flow from muscle selection to video display
- **Error Scenarios**: Test network failures, invalid URLs, and missing data

### 9. Implementation Checklist
- [ ] Add `youtube_player_iframe` dependency to `pubspec.yaml`
- [ ] Create `MuscleVideoMapping` class with all muscle-video associations
- [ ] Implement `DynamicVideoPlayer` widget with proper state management
- [ ] Replace static video in `_buildVideoSection()` with dynamic player
- [ ] Add comprehensive error handling and fallback mechanisms
- [ ] Implement loading states and user feedback
- [ ] Add proper disposal of YouTube player controllers
- [ ] Test all muscle selections and video mappings
- [ ] Verify error handling for network issues and invalid URLs
- [ ] Ensure proper memory management and performance

### 10. Missing Video Assignments
Based on the provided mapping, the following muscles need video assignments:
- **Cervical Muscle**: Currently defaults to Deltoids video
- **Calf**: Currently defaults to Quadriceps video  
- **Ankle**: Currently defaults to Quadriceps video

**Recommendation**: Either assign specific videos for these muscles or create generic ROM assessment videos that can be used for multiple muscle groups.

### 11. Code Structure
```
lib/assessment/
├── c_video.dart (modified)
├── muscle_video_mapping.dart (new)
└── dynamic_video_player.dart (new)
```

### 12. Dependencies Update
Add to `pubspec.yaml`:
```yaml
dependencies:
  youtube_player_iframe: ^3.0.0
```

This implementation will create a robust, dynamic video system that automatically displays the appropriate instructional video based on the user's selected muscle, with comprehensive error handling and fallback mechanisms.
