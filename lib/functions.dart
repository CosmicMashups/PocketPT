// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart'; // For formatting duration
import 'dart:io';
import 'package:flutter/foundation.dart';

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

// Custom Widget: Radio Tile
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
  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Check if running on web
      if (kIsWeb) {
        // For web, use network controller with a data URL
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
        );
      } else {
        // For mobile, use file controller
        _controller = VideoPlayerController.file(File(widget.videoPath));
      }

      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      _listener = () {
        if (mounted) setState(() {});
      };

      _controller.addListener(_listener);
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load video: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  // Safely format the duration and position
  String _formatDuration(Duration duration) {
    // Ensure the duration is non-negative and within the valid range
    if (duration.inMilliseconds < 0 || duration.inMilliseconds > 86400000) {
      return '00:00';  // Return a default value if the duration is invalid
    }
    return DateFormat('mm:ss').format(DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds));
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Video player
        if (_isInitialized)
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        else
          const Center(
            child: CircularProgressIndicator(),
          ),

        // Play/Pause button overlay
        if (_isInitialized)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 50.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Custom Widget: Dialog Box
class ReusableInfoDialog extends StatelessWidget {
  final String title;
  final List<String> contentParagraphs;

  const ReusableInfoDialog({
    super.key,
    required this.title,
    required this.contentParagraphs,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentParagraphs
              .map((paragraph) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      paragraph,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

void showReusableDialog(BuildContext context, String title, List<String> paragraphs) {
  showDialog(
    context: context,
    builder: (context) => ReusableInfoDialog(
      title: title,
      contentParagraphs: paragraphs,
    ),
  );
}

// Custom Widget: Dialog Box with TextField
Future<void> showCustomInputDialog({
  required BuildContext context,
  required String title,
  required List<String> fieldLabels,
  required List<String> initialValues,
  required void Function(List<String>) onSave,
}) async {
  assert(fieldLabels.length == initialValues.length,
      'Each field must have a corresponding initial value');

  List<TextEditingController> controllers = List.generate(
    fieldLabels.length,
    (index) => TextEditingController(text: initialValues[index]),
  );

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            children: List.generate(fieldLabels.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controllers[index],
                  obscureText: title.toLowerCase().contains('password'),
                  decoration: InputDecoration(
                    labelText: fieldLabels[index],
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              List<String> values = controllers.map((c) => c.text.trim()).toList();
              onSave(values);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
} 