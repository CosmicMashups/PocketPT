import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'muscle_video_mapping.dart';

/// Local Muscle Video Player Widget
/// 
/// A widget that displays local video files based on the selected muscle.
/// Handles loading states, errors, and provides fallback mechanisms.
class LocalMuscleVideoPlayer extends StatefulWidget {
  /// The name of the muscle for which to display the video
  final String muscleName;
  
  /// The height of the video player (optional, will use aspect ratio if not provided)
  final double? height;
  
  /// Whether the video should autoplay
  final bool autoPlay;
  
  /// Whether to show video controls
  final bool showControls;
  
  /// Whether to show muscle information above the video
  final bool showMuscleInfo;

  /// Creates a local muscle video player widget
  const LocalMuscleVideoPlayer({
    super.key,
    required this.muscleName,
    this.height,
    this.autoPlay = false,
    this.showControls = true,
    this.showMuscleInfo = false,
  });

  @override
  State<LocalMuscleVideoPlayer> createState() => _LocalMuscleVideoPlayerState();
}

class _LocalMuscleVideoPlayerState extends State<LocalMuscleVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasTriedFallback = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(LocalMuscleVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muscleName != widget.muscleName) {
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    _disposeController();
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _hasTriedFallback = false;
    });

    // Get video path for the muscle
    final videoPath = MuscleVideoMapping.getVideoPath(widget.muscleName);
    _loadVideo(videoPath);
  }

  Future<void> _loadVideo(final String videoPath) async {
    try {
      final controller = VideoPlayerController.asset(videoPath);
      
      await controller.initialize();
      
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
        _hasError = false;
      });

      if (widget.autoPlay) {
        controller.play();
      }

      // Add listener for error handling
      controller.addListener(_videoListener);
    } catch (e) {
      debugPrint('LocalMuscleVideoPlayer: Error loading video $videoPath: $e');
      
      if (!mounted) return;

      // Try fallback if not already tried
      if (!_hasTriedFallback && videoPath != MuscleVideoMapping.defaultVideoPath) {
        _hasTriedFallback = true;
        debugPrint('LocalMuscleVideoPlayer: Trying fallback video');
        _loadVideo(MuscleVideoMapping.defaultVideoPath);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.hasError) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video playback error occurred.';
        });
      }
    }
  }

  void _disposeController() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_videoListener);
      controller.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showMuscleInfo) ...[
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFF8B2E2E), size: 20),
              const SizedBox(width: 8),
              Text(
                'ROM Assessment for ${widget.muscleName}',
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
        if (_isLoading)
          _buildLoadingState()
        else if (_hasError)
          _buildErrorState()
        else
          _buildVideoPlayer(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        // Try to use video aspect ratio if controller is initialized but still loading
        double aspectRatio = 16 / 9; // Default to 16:9
        if (_controller != null && _controller!.value.isInitialized) {
          final videoAspectRatio = _controller!.value.aspectRatio;
          if (videoAspectRatio > 0) {
            aspectRatio = videoAspectRatio;
          }
        }
        
        // Calculate height based on aspect ratio
        final calculatedHeight = availableWidth / aspectRatio;
        
        // Limit height to prevent overflow for tall videos
        final maxHeight = constraints.maxHeight > 0 
            ? constraints.maxHeight 
            : availableWidth * 2.5;
        
        // Use explicit height if provided, otherwise use calculated height clamped to maxHeight
        final finalHeight = widget.height ?? (calculatedHeight > maxHeight ? maxHeight : calculatedHeight);
        
        return Container(
          width: double.infinity,
          height: finalHeight,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        // Use a reasonable default aspect ratio for error state
        // If we have a controller with aspect ratio info, use it
        double aspectRatio = 16 / 9; // Default to 16:9
        if (_controller != null && _controller!.value.isInitialized) {
          final videoAspectRatio = _controller!.value.aspectRatio;
          if (videoAspectRatio > 0) {
            aspectRatio = videoAspectRatio;
          }
        }
        
        // Calculate height based on aspect ratio
        final calculatedHeight = availableWidth / aspectRatio;
        
        // Limit height to prevent overflow for tall videos
        final maxHeight = constraints.maxHeight > 0 
            ? constraints.maxHeight 
            : availableWidth * 2.5;
        
        // Use explicit height if provided, otherwise use calculated height clamped to maxHeight
        final finalHeight = widget.height ?? (calculatedHeight > maxHeight ? maxHeight : calculatedHeight);
        
        return Container(
          width: double.infinity,
          height: finalHeight,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Center(
            child: SingleChildScrollView(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _errorMessage ?? 'Failed to load video.',
                      style: GoogleFonts.ptSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _initializePlayer,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    final controller = _controller;
    if (controller == null) {
      return _buildLoadingState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Get the actual video aspect ratio
        final videoAspectRatio = controller.value.aspectRatio;
        final aspectRatio = videoAspectRatio > 0 ? videoAspectRatio : (16 / 9);
        
        // Calculate height based on aspect ratio and available width
        final availableWidth = constraints.maxWidth;
        final calculatedHeight = availableWidth / aspectRatio;
        
        // For very tall videos (9:16 or taller), limit the height to prevent overflow
        final maxHeight = constraints.maxHeight > 0 
            ? constraints.maxHeight 
            : availableWidth * 2.5; // Allow up to 2.5x width for tall videos (9:16 = 1.78x)
        
        // Use explicit height if provided, otherwise use calculated height clamped to maxHeight
        final finalHeight = widget.height ?? (calculatedHeight > maxHeight ? maxHeight : calculatedHeight);
        
        return Container(
          width: double.infinity,
          height: finalHeight,
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
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(controller),
                ),
                if (widget.showControls)
                  Positioned.fill(
                    child: _buildControlsOverlay(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlsOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Icon(
            _controller!.value.isPlaying
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color: Colors.white,
            size: 64,
          ),
        ),
      ),
    );
  }
}

