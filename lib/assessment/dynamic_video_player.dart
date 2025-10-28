import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'muscle_video_mapping.dart';

/// Dynamic Video Player Widget
/// 
/// A widget that displays YouTube videos based on the selected muscle.
/// Handles loading states, errors, and provides fallback mechanisms.
class DynamicVideoPlayer extends StatefulWidget {
  /// The name of the muscle for which to display the video
  final String muscleName;
  
  /// The height of the video player
  final double? height;
  
  /// Whether the video should autoplay
  final bool autoPlay;
  
  /// Whether to show video controls
  final bool showControls;
  
  /// Creates a dynamic video player widget
  const DynamicVideoPlayer({
    super.key,
    required this.muscleName,
    this.height,
    this.autoPlay = false,
    this.showControls = true,
  });

  @override
  State<DynamicVideoPlayer> createState() => _DynamicVideoPlayerState();
}

class _DynamicVideoPlayerState extends State<DynamicVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isYouTubeShort = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    // Test video ID extraction for debugging
    MuscleVideoMapping.testVideoIdExtraction();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(DynamicVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muscleName != widget.muscleName) {
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      final videoUrl = MuscleVideoMapping.getVideoUrl(widget.muscleName).trim();
      print('DynamicVideoPlayer: Loading video for muscle: ${widget.muscleName}');
      print('DynamicVideoPlayer: Video URL: $videoUrl');
      
      // Detect if this is a YouTube Short based on URL
      _isYouTubeShort = _detectYouTubeShort(videoUrl);
      print('DynamicVideoPlayer: Is YouTube Short: $_isYouTubeShort');
      
      // Prefer the package's robust parser (handles Shorts and multiple formats),
      // then fall back to our extractor if needed.
      String? videoId = YoutubePlayerController.convertUrlToId(videoUrl);
      print('DynamicVideoPlayer: Package parser video ID: $videoId');
      
      if (videoId == null || videoId.isEmpty) {
        videoId = MuscleVideoMapping.extractVideoId(videoUrl);
        print('DynamicVideoPlayer: Custom extractor video ID: $videoId');
      }
      
      if (videoId == null || videoId.isEmpty) {
        throw Exception('Invalid YouTube URL or video ID: $videoUrl');
      }
      
      print('DynamicVideoPlayer: Final video ID: $videoId');

      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: widget.autoPlay,
        params: YoutubePlayerParams(
          showControls: widget.showControls,
          mute: false,
          loop: false,
          enableCaption: true,
        ),
      );
      
      // Add listener for player state changes
      _controller.listen((event) {
        print('DynamicVideoPlayer: Player event: ${event.runtimeType}');
        print('DynamicVideoPlayer: Player state: ${event.playerState}');
        
        // Check for error states
        if (event.playerState == PlayerState.unknown) {
          print('DynamicVideoPlayer: Player error detected');
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Video unavailable - Error code 15';
              _isLoading = false;
            });
            // Try fallback video after a short delay if we haven't exceeded retry limit
            if (_retryCount < _maxRetries) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  _retryCount++;
                  _tryFallbackVideo();
                }
              });
            }
          }
        }
      });
      
      // Add a small delay to ensure the controller is properly initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  void _retryLoad() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      print('DynamicVideoPlayer: Retry attempt $_retryCount of $_maxRetries');
      // Try with a different video URL as fallback
      _tryFallbackVideo();
    } else {
      print('DynamicVideoPlayer: Max retries reached, showing error');
      setState(() {
        _hasError = true;
        _errorMessage = 'Unable to load video after multiple attempts. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  void _tryFallbackVideo() {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // Use the default video URL as fallback
      final fallbackUrl = MuscleVideoMapping.defaultVideoUrl;
      print('DynamicVideoPlayer: Trying fallback video: $fallbackUrl');
      
      // Detect if this is a YouTube Short based on URL
      _isYouTubeShort = _detectYouTubeShort(fallbackUrl);
      
      // Extract video ID
      String? videoId = YoutubePlayerController.convertUrlToId(fallbackUrl);
      if (videoId == null || videoId.isEmpty) {
        videoId = MuscleVideoMapping.extractVideoId(fallbackUrl);
      }
      
      if (videoId == null || videoId.isEmpty) {
        throw Exception('Invalid fallback video ID: $fallbackUrl');
      }
      
      print('DynamicVideoPlayer: Fallback video ID: $videoId');

      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: widget.autoPlay,
        params: YoutubePlayerParams(
          showControls: widget.showControls,
          mute: false,
          loop: false,
          enableCaption: true,
        ),
      );
      
      // Add listener for player state changes
      _controller.listen((event) {
        print('DynamicVideoPlayer: Fallback player state: ${event.playerState}');
        
        // Check for error states
        if (event.playerState == PlayerState.unknown) {
          print('DynamicVideoPlayer: Fallback video also failed');
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'All videos unavailable. Please try again later.';
              _isLoading = false;
            });
          }
        }
      });
      
      // Add a small delay to ensure the controller is properly initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load fallback video: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Detect if the URL is a YouTube Short
  bool _detectYouTubeShort(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.host.contains('youtube.com') && uri.path.contains('/shorts/');
    } catch (e) {
      return false;
    }
  }

  /// Get user-friendly error message
  String _getUserFriendlyErrorMessage() {
    if (_errorMessage == null) return 'Failed to load video';
    
    if (_errorMessage!.contains('Error code 15')) {
      return 'This video is unavailable. Trying alternative video...';
    } else if (_errorMessage!.contains('Playback OD')) {
      return 'Video playback error. Please try again later.';
    } else if (_errorMessage!.contains('Please try again later')) {
      return 'Video temporarily unavailable. Please try again later.';
    } else {
      return _errorMessage!;
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double? height = widget.height; // null means dynamic based on width
    
    if (_isLoading) {
      return _buildLoadingState(height);
    }
    
    if (_hasError) {
      return _buildErrorState(height);
    }
    
    return _buildVideoPlayer(height);
  }

  Widget _buildLoadingState(final double? height) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading video...',
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
    
    // Always use LayoutBuilder to ensure we get the actual available width
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final calculatedHeight = height ?? _calculateVideoHeight(availableWidth);
        return Container(
          width: double.infinity,
          height: calculatedHeight,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildErrorState(final double? height) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Video unavailable',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getUserFriendlyErrorMessage(),
            style: GoogleFonts.ptSans(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retryLoad,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2E2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
    
    // Always use LayoutBuilder to ensure we get the actual available width
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final calculatedHeight = height ?? _calculateVideoHeight(availableWidth);
        return Container(
          width: double.infinity,
          height: calculatedHeight,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildVideoPlayer(final double? height) {
    // Always use LayoutBuilder to ensure we get the actual available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the full available width (this accounts for parent margins/padding)
        final availableWidth = constraints.maxWidth;
        
        // Calculate height based on video type: 16:9 for normal videos, 9:16 for shorts
        final calculatedHeight = height ?? _calculateVideoHeight(availableWidth);
        
        return Container(
          width: double.infinity, // Ensure full width usage
          height: calculatedHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(
              controller: _controller,
            ),
          ),
        );
      },
    );
  }

  /// Calculate video height based on video type and available width
  double _calculateVideoHeight(double availableWidth) {
    if (_isYouTubeShort) {
      // For YouTube Shorts, use 9:16 aspect ratio (portrait)
      // Limit the width to ensure good mobile experience
      final maxWidth = availableWidth > 350 ? 350.0 : availableWidth;
      final calculatedHeight = maxWidth * (16 / 9);
      print('DynamicVideoPlayer: Shorts - width: $maxWidth, height: $calculatedHeight (9:16 aspect ratio)');
      return calculatedHeight;
    } else {
      // For normal videos, use 16:9 aspect ratio (landscape)
      final calculatedHeight = availableWidth * (9 / 16);
      print('DynamicVideoPlayer: Regular video - width: $availableWidth, height: $calculatedHeight (16:9 aspect ratio)');
      return calculatedHeight;
    }
  }
}

/// Video Player with Muscle Information
/// 
/// A wrapper widget that includes muscle information along with the video player
class MuscleVideoPlayer extends StatelessWidget {
  /// The name of the muscle for which to display the video
  final String muscleName;
  
  /// The height of the video player
  final double? height;
  
  /// Whether the video should autoplay
  final bool autoPlay;
  
  /// Whether to show video controls
  final bool showControls;
  
  /// Whether to show muscle information above the video
  final bool showMuscleInfo;

  /// Creates a muscle video player widget
  const MuscleVideoPlayer({
    super.key,
    required this.muscleName,
    this.height,
    this.autoPlay = false,
    this.showControls = true,
    this.showMuscleInfo = true,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMuscleInfo) ...[
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFF8B2E2E), size: 20),
              const SizedBox(width: 8),
              Text(
                'ROM Assessment for $muscleName',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        DynamicVideoPlayer(
          muscleName: muscleName,
          height: height,
          autoPlay: autoPlay,
          showControls: showControls,
        ),
      ],
    );
  }
}
