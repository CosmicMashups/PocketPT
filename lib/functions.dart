// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart'; // For formatting duration

// Route: Animation
Route createMorphRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 600),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );

      return FadeTransition(
        opacity: curvedAnimation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

class CustomRadioTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final String description;
  final ValueChanged<T?> onChanged;

  const CustomRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2E2E2E)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: ListTile(
            title: Text(
              title,
              style: GoogleFonts.ptSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            subtitle: Text(
              description,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: const Color(0xFF555555),
              ),
            ),
            trailing: Radio<T>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF800020),
              onChanged: onChanged,
            ),
            onTap: () {
              onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

// Custom Widget: Radio Tile with Image
class CustomImageRadioTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final String description;
  final ValueChanged<T?> onChanged;
  final Widget? image;

  const CustomImageRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.description,
    required this.onChanged,
    this.image,
  });

  // Function to show the image in a dropdown (using PopupMenuButton)
  void _showImageDropdown(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(200.0, 200.0, 0.0, 0.0),
      items: [
        PopupMenuItem(
          child: SizedBox(
            width: 300,
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image!,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF2E2E2E)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: ListTile(
            leading: image != null
                ? GestureDetector(
                    onTap: () => _showImageDropdown(context), // Tap to show dropdown with image
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: image,
                    ),
                  )
                : null,
            title: Text(
              title,
              style: GoogleFonts.ptSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            subtitle: Text(
              description,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: const Color(0xFF555555),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<T>(
                  value: value,
                  groupValue: groupValue,
                  activeColor: const Color(0xFF800020),
                  onChanged: onChanged,
                ),
                if (image != null)
                  IconButton(
                    icon: Icon(Icons.expand),
                    onPressed: () {
                      _showImageDropdown(context); // Open dropdown to expand image
                    },
                  ),
              ],
            ),
            onTap: () {
              onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

// Custom Widget: Video Player
class LocalVideoPlayer extends StatefulWidget {
  final String videoPath;

  const LocalVideoPlayer({super.key, required this.videoPath});

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  late VideoPlayerController _controller;
  late VoidCallback _listener;

  final bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {});
      });

    _listener = () {
      if (mounted) setState(() {});
    };
    _controller.addListener(_listener);
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    return DateFormat('mm:ss').format(DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds));
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying ? _controller.pause() : _controller.play();
                      });
                    },
                  ),
                  Text(
                    '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16), // Spacer if needed
                ],
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
  }
}