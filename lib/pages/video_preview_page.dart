import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/mediapipe_service.dart';
import '../widgets/pose_video_preview.dart';

class VideoPreviewPage extends StatefulWidget {
  final String videoPath;

  const VideoPreviewPage({Key? key, required this.videoPath}) : super(key: key);

  @override
  _VideoPreviewPageState createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _controller;
  final MediaPipeService _mediaPipeService = MediaPipeService();
  bool _isProcessing = false;
  bool _showPoseOverlay = false;
  String? _processedVideoPath;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  Future<void> _processVideo() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _mediaPipeService.initialize();
      final poses = await _mediaPipeService.processVideo(widget.videoPath);
      _processedVideoPath = await _mediaPipeService.saveProcessedVideo(widget.videoPath, poses);
      
      if (mounted) {
        setState(() {
          _showPoseOverlay = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video processed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _mediaPipeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Preview'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _controller.value.isInitialized
                ? _showPoseOverlay
                    ? PoseVideoPreview(
                        videoPath: widget.videoPath,
                        showPoseOverlay: true,
                      )
                    : AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processVideo,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Process Video'),
                ),
                if (_processedVideoPath != null)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showPoseOverlay = !_showPoseOverlay;
                      });
                    },
                    child: Text(_showPoseOverlay ? 'Hide Pose' : 'Show Pose'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 