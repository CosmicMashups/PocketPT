// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../data/ai_media_processing_service.dart';
import '../data/globals.dart';
import '../data/pose_detection_service.dart';
import 'assessment_data.dart';
import 'c_painlevel.dart';
import 'c_video.dart';
import 'c_preview.dart';

class AssessUpload extends StatefulWidget {
  const AssessUpload({super.key});

  @override
  State<AssessUpload> createState() => _AssessUploadState();
}

class _AssessUploadState extends State<AssessUpload> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  // Media capture state
  final ImagePicker _picker = ImagePicker();
  final AIMediaProcessingService _aiService = AIMediaProcessingService();
  final PoseDetectionService _poseService = PoseDetectionService();
  File? _capturedImage;
  File? _selectedVideo;
  bool _isProcessing = false;
  Map<String, dynamic>? _aiResults;

  @override
  void initState() {
    super.initState();
    print('AssessUpload: initState() called');
    print('AssessUpload: initState() completed');
  }

  /// Determine assessment algorithm based on UserAssess.specificMuscle
  /// Reuses the same logic from camera assessment
  String _getAssessmentMode() {
    final muscle = UserAssess.specificMuscle;
    if (muscle.isEmpty) {
      debugPrint('Warning: No muscle selected, using default (triceps)');
      return 'triceps';
    }
    
    // Use the same muscle-to-algorithm mapping from camera assessment
    const Map<String, String> muscleToAlgorithm = {
      // Upper Body
      'Deltoids': 'shoulders',
      'Biceps': 'biceps',
      'Triceps': 'triceps',
      'Cervical Muscle': 'shoulders',
      
      // Lower Body
      'Quadriceps': 'quadriceps',
      'Hamstrings': 'hamstrings',
      'Calf': 'calves',
      'Ankle': 'calves',
      'Gluteals': 'gluteals',
      
      // Core
      'Abdominals': 'abdominals',
      'Obliques': 'obliques',
      'Lower Back': 'lower back',
      'Multifidus': 'multifidus'
    };
    
    final mode = muscleToAlgorithm[muscle];
    if (mode == null) {
      debugPrint('Warning: Unknown muscle group: $muscle, using default (triceps)');
      return 'triceps';
    }
    
    debugPrint('Selected muscle: $muscle -> Assessment mode: $mode');
    return mode;
  }

  @override
  Widget build(BuildContext context) {
    print('AssessUpload: build() called');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessUpload: ERROR in build() - $e');
      return Container(
        color: backgroundColor,
        child: Center(
          child: Text(
            'Error loading page: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }


  Widget _buildPageContent(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: Column(
        children: [
          // Custom AppBar
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: mainColor,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    "Upload Evidence",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, color: Colors.transparent),
                ),
              ],
            ),
          ),
          // Body Content
          Flexible(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Section
                    _buildProgressSection(4, 8, "Evidence Upload"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "Upload Evidence",
                      "Help us better understand your condition by uploading photos or videos",
                      Icons.cloud_upload,
                    ),

                    const SizedBox(height: 24),

                    // Upload Options
                    _buildUploadOption(
                      'Take Photo',
                      'Capture a photo of the affected area',
                      Icons.camera_alt,
                      mainColor,
                      _isProcessing ? null : () => _takePhoto(),
                      isLoading: _isProcessing,
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      'Record Video',
                      'Record a video showing your range of motion',
                      Icons.videocam,
                      subColor,
                      () => _recordVideo(),
                    ),
                    const SizedBox(height: 16),
                    _buildUploadOption(
                      'Upload from Gallery',
                      'Select existing photos or videos from your device',
                      Icons.photo_library,
                      successColor,
                      _isProcessing ? null : () => _selectFromGallery(),
                      isLoading: _isProcessing,
                    ),
                    const SizedBox(height: 24),

                    // Media Preview Section
                    if (_capturedImage != null || _selectedVideo != null)
                      _buildMediaPreviewSection(),

                    const SizedBox(height: 16),

                    // AI Results Section
                    if (_aiResults != null)
                      _buildAIResultsSection(),

                    const SizedBox(height: 24),

                    // Skip Option
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const AssessPainLevel(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(position: offsetAnimation, child: child);
                            },
                          ),
                        );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: detailColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.skip_next,
                                  color: detailColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(
                                      "Skip for Now",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: detailColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Continue without uploading evidence",
                                      style: GoogleFonts.ptSans(
                                        fontSize: 14,
                                        color: detailColor.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: detailColor,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a progress section widget
  Widget _buildProgressSection(int currentStep, int totalSteps, String stepName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.track_changes,
              color: mainColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assessment Progress",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Step $currentStep of $totalSteps - $stepName",
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: detailColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build a question section widget
  Widget _buildQuestionSection(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: mainColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: detailColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption(String title, String description, IconData icon, Color color, VoidCallback? onTap, {bool isLoading = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading 
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: detailColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        final photoFile = File(photo.path);
        setState(() {
          _capturedImage = photoFile;
        });
        
        // Process photo with pose detection and assessment
        await _processPhotoWithAssessment(photoFile);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Process photo with pose detection and assessment
  /// Navigates to preview page with results
  Future<void> _processPhotoWithAssessment(File photoFile) async {
    try {
      // Show processing indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text('Processing photo for assessment...'),
            ],
          ),
          backgroundColor: mainColor,
          duration: const Duration(seconds: 3),
        ),
      );

      // Get assessment parameters
      final muscleGroup = _getAssessmentMode();
      final side = 'Right'; // Default side, could be made configurable
      
      // Process photo with pose detection
      final result = await _poseService.processPhotoForAssessment(
        photoFile: photoFile,
        muscleGroup: muscleGroup,
        side: side,
      );

      if (result['success'] == true) {
        // Navigate to preview page with results
        if (context.mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AssessPhotoPreview(
                photoFile: photoFile,
                assessmentResult: result['assessmentResult'],
                landmarks: result['landmarks'],
                muscleGroup: UserAssess.specificMuscle,
                side: side,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
        }
      } else {
        // Handle processing failure
        final errorMessage = result['error'] ?? 'Failed to process photo';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _takePhoto(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing photo with assessment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _recordVideo() {
    debugPrint('AssessUpload: Record video selected');
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AssessPainVideo(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  Future<void> _selectFromGallery() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Show dialog to choose between photo and video
      final String? mediaType = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Media Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo),
                  title: Text('Photo'),
                  onTap: () => Navigator.of(context).pop('photo'),
                ),
                ListTile(
                  leading: Icon(Icons.video_library),
                  title: Text('Video'),
                  onTap: () => Navigator.of(context).pop('video'),
                ),
              ],
            ),
          );
        },
      );

      if (mediaType == 'photo') {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (photo != null) {
          final photoFile = File(photo.path);
          setState(() {
            _capturedImage = photoFile;
          });
          
          // Process photo with pose detection and assessment
          await _processPhotoWithAssessment(photoFile);
        }
      } else if (mediaType == 'video') {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );

        if (video != null) {
          setState(() {
            _selectedVideo = File(video.path);
          });
          
          // TODO: Trigger AI model processing for the selected video
          _processCapturedMedia(_selectedVideo!);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video selected successfully!'),
              backgroundColor: successColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error selecting from gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting media: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Build media preview section
  Widget _buildMediaPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Media Captured",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_capturedImage != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _capturedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Photo: ${_capturedImage!.path.split('/').last}",
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: detailColor,
              ),
            ),
          ],
          if (_selectedVideo != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                color: Colors.black12,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library,
                      size: 48,
                      color: detailColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Video Selected",
                      style: GoogleFonts.ptSans(
                        fontSize: 14,
                        color: detailColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Video: ${_selectedVideo!.path.split('/').last}",
              style: GoogleFonts.ptSans(
                fontSize: 12,
                color: detailColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build AI results section
  Widget _buildAIResultsSection() {
    if (_aiResults == null) return const SizedBox.shrink();

    final painScore = (_aiResults!['overallPainScore'] as num?)?.toDouble() ?? 5.0;
    final painDesc = _aiResults!['painDescription'] as String? ?? 'Assessment completed';
    final hasError = _aiResults!.containsKey('error');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? Colors.red.withValues(alpha: 0.3) : successColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasError ? Colors.red.withValues(alpha: 0.1) : successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasError ? Icons.error : Icons.psychology,
                  color: hasError ? Colors.red : successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hasError ? "AI Analysis Error" : "AI Analysis Results",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasError) ...[
            Text(
              _aiResults!['error'] as String? ?? 'Unknown error',
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ] else ...[
            // Pain Score
            Row(
              children: [
                Text(
                  "Pain Level: ",
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: detailColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPainScoreColor(painScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${painScore.toStringAsFixed(1)}/10",
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getPainScoreColor(painScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Pain Description
            Text(
              "Assessment: $painDesc",
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            // Service Status
            if (_aiResults!.containsKey('pose') || _aiResults!.containsKey('cnn'))
              Text(
                "Analysis includes pose detection and CNN-based pain recognition",
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  color: detailColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Get color for pain score
  Color _getPainScoreColor(double score) {
    if (score <= 3) return Colors.green;
    if (score <= 6) return Colors.orange;
    return Colors.red;
  }

  // Save AI results to assessment data
  Future<void> _saveAIResultsToAssessment(Map<String, dynamic> aiResults) async {
    try {
      // Update AssessmentData with AI results
      AssessmentData.aiAnalysisResults = aiResults;
      AssessmentData.hasAIAnalysis = true;
      AssessmentData.aiAnalysisTimestamp = DateTime.now();
      
      // Update UserAssess with AI-derived pain scale if available
      final painScore = aiResults['overallPainScore'] as double?;
      if (painScore != null) {
        // Convert 0-10 scale to 1-10 scale for consistency
        final adjustedScore = (painScore + 1).clamp(1, 10).round();
        UserAssess.painScale = adjustedScore;
        
        // Update pain level based on score
        if (adjustedScore <= 3) {
          UserAssess.painLevel = 'Mild';
        } else if (adjustedScore <= 6) {
          UserAssess.painLevel = 'Moderate';
        } else {
          UserAssess.painLevel = 'Severe';
        }
      }
      
      // Save to Hive
      await UserAssess.saveToHive();
      
      debugPrint('AI results saved to assessment data');
    } catch (e) {
      debugPrint('Error saving AI results to assessment data: $e');
    }
  }

  // Process captured media with AI models
  Future<void> _processCapturedMedia(File mediaFile) async {
    try {
      debugPrint('Processing media file: ${mediaFile.path}');
      
      // Show processing indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processing media with AI models...'),
          backgroundColor: mainColor,
          duration: Duration(seconds: 3),
        ),
      );

      // Process with AI models
      Map<String, dynamic> results;
      if (mediaFile.path.toLowerCase().contains('.mp4') || 
          mediaFile.path.toLowerCase().contains('.mov') ||
          mediaFile.path.toLowerCase().contains('.avi')) {
        results = await _aiService.processVideo(mediaFile);
      } else {
        results = await _aiService.processImage(mediaFile);
      }

      // Store results
      setState(() {
        _aiResults = results;
      });

      // Save AI results to assessment data
      await _saveAIResultsToAssessment(results);

      // Show success message
      final painScore = results['overallPainScore'] as double? ?? 5.0;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI analysis complete! Pain level: ${painScore.toStringAsFixed(1)}/10'),
          backgroundColor: successColor,
          duration: Duration(seconds: 3),
        ),
      );

      debugPrint('AI processing results: $results');
    } catch (e) {
      debugPrint('Error processing media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing media: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}