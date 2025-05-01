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
  final IconData icon;

  const CustomRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.description,
    required this.onChanged,
    this.icon = Icons.circle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            subtitle: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF777777),
              ),
            ),
            trailing: Radio<T>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF800020),
              onChanged: onChanged,
            ),
            leading: Icon(
              icon,
              color: const Color(0xFF800020),
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
              child: image!, // Display image
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
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            leading: image != null
                ? GestureDetector(
                    onTap: () => _showImageDropdown(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: image,
                    ),
                  )
                : null,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            subtitle: Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF777777),
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
                    icon: const Icon(Icons.expand, color: Color(0xFF800020)),
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

class LocalVideoPlayer extends StatefulWidget {
  final String videoPath;

  const LocalVideoPlayer({super.key, required this.videoPath});

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  late VideoPlayerController _controller;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
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
    if (duration.inMilliseconds < 0 || duration.inMilliseconds > 86400000) {
      return '00:00';
    }
    return DateFormat('mm:ss').format(DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds));
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                const SizedBox(height: 8),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: const Color(0xFF800020),
                    backgroundColor: Colors.grey[300]!,
                    bufferedColor: Colors.grey[400]!,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: const Color(0xFF800020),
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                    Text(
                      '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12), // Balance layout
                  ],
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}

// Custom Widget: Dialog Box
class ReusableInfoDialog extends StatelessWidget {
  final String title;
  final List<String> contentParagraphs;
  final IconData icon;
  final String? imageAssetPath; // Optional image

  const ReusableInfoDialog({
    super.key,
    required this.title,
    required this.contentParagraphs,
    this.icon = Icons.info_outline_rounded,
    this.imageAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFFDFDFD),
      titlePadding: const EdgeInsets.only(top: 20, left: 24, right: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
      title: Row(
        children: [
          Icon(icon, size: 28, color: Colors.indigo.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.indigo.shade800,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageAssetPath != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageAssetPath!,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ...contentParagraphs.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  paragraph,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.close, color: Colors.grey),
          label: const Text(
            'Close',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          onPressed: () => Navigator.of(context).pop(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF5F5F5),
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: Color(0xFF800020)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(fieldLabels.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: controllers[index],
                  obscureText: title.toLowerCase().contains('password') &&
                      fieldLabels[index].toLowerCase().contains('password'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.text_fields_rounded, color: Color(0xFF800020)),
                    labelText: fieldLabels[index],
                    labelStyle: const TextStyle(color: Color(0xFF800020)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF800020)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF800020), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
            label: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded, color: Colors.white),
            label: const Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF800020),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              List<String> values = controllers.map((c) => c.text.trim()).toList();
              onSave(values);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// ============= OLD WIDGETS =================

// // Custom Widget: Radio Tile
// class CustomRadioTile<T> extends StatelessWidget {
//   final T value;
//   final T groupValue;
//   final String title;
//   final String description;
//   final ValueChanged<T?> onChanged;

//   const CustomRadioTile({
//     super.key,
//     required this.value,
//     required this.groupValue,
//     required this.title,
//     required this.description,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0),
//       child: Material(
//         elevation: 3,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: const Color(0xFF2E2E2E)),
//             borderRadius: BorderRadius.circular(8),
//             color: Colors.white,
//           ),
//           child: ListTile(
//             title: Text(
//               title,
//               style: GoogleFonts.ptSans(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: const Color(0xFF1E1E1E),
//               ),
//             ),
//             subtitle: Text(
//               description,
//               style: GoogleFonts.ptSans(
//                 fontSize: 14,
//                 color: const Color(0xFF555555),
//               ),
//             ),
//             trailing: Radio<T>(
//               value: value,
//               groupValue: groupValue,
//               activeColor: const Color(0xFF800020),
//               onChanged: onChanged,
//             ),
//             onTap: () {
//               onChanged(value);
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Custom Widget: Radio Tile with Image
// class CustomImageRadioTile<T> extends StatelessWidget {
//   final T value;
//   final T groupValue;
//   final String title;
//   final String description;
//   final ValueChanged<T?> onChanged;
//   final Widget? image;

//   const CustomImageRadioTile({
//     super.key,
//     required this.value,
//     required this.groupValue,
//     required this.title,
//     required this.description,
//     required this.onChanged,
//     this.image,
//   });

//   // Function to show the image in a dropdown (using PopupMenuButton)
//   void _showImageDropdown(BuildContext context) {
//     showMenu(
//       context: context,
//       position: RelativeRect.fromLTRB(200.0, 200.0, 0.0, 0.0),
//       items: [
//         PopupMenuItem(
//           child: SizedBox(
//             width: 300,
//             height: 300,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: image!,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0),
//       child: Material(
//         elevation: 3,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           decoration: BoxDecoration(
//             border: Border.all(color: const Color(0xFF2E2E2E)),
//             borderRadius: BorderRadius.circular(8),
//             color: Colors.white,
//           ),
//           child: ListTile(
//             leading: image != null
//                 ? GestureDetector(
//                     onTap: () => _showImageDropdown(context), // Tap to show dropdown with image
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(6),
//                       child: image,
//                     ),
//                   )
//                 : null,
//             title: Text(
//               title,
//               style: GoogleFonts.ptSans(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: const Color(0xFF1E1E1E),
//               ),
//             ),
//             subtitle: Text(
//               description,
//               style: GoogleFonts.ptSans(
//                 fontSize: 14,
//                 color: const Color(0xFF555555),
//               ),
//             ),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Radio<T>(
//                   value: value,
//                   groupValue: groupValue,
//                   activeColor: const Color(0xFF800020),
//                   onChanged: onChanged,
//                 ),
//                 if (image != null)
//                   IconButton(
//                     icon: Icon(Icons.expand),
//                     onPressed: () {
//                       _showImageDropdown(context); // Open dropdown to expand image
//                     },
//                   ),
//               ],
//             ),
//             onTap: () {
//               onChanged(value);
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }