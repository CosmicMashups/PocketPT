// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import 'assessment_data.dart';
// Sync removed for assessment (local-only)
// removed unused import
import 'c_paintype.dart';

class AssessPainLevel extends StatefulWidget {
  const AssessPainLevel({super.key});

  @override
  State<AssessPainLevel> createState() => _AssessPainLevelState();
}

class _AssessPainLevelState extends State<AssessPainLevel> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  // static const subColor = Color(0xFFC24A4A); // Removed as not used in categorical version
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  int selectedPainLevel = 1;

  @override
  void initState() {
    super.initState();
    print('AssessPainLevel: initState() called');
    print('AssessPainLevel: Current AssessmentData.painScale = "${AssessmentData.painScale}"');
    print('AssessPainLevel: Current UserAssess.painScale = "${UserAssess.painScale}"');
    
    // Initialize selectedPainLevel from AROM assessment data (preferred) or UserAssess
    // AROM assessment values are set in c_camera.dart via AssessmentData and UserAssess
    // Ensure value is within valid range (1-10, not 0-10)
    // 0 is explicitly not allowed - clamp to minimum of 1
    
    // Prefer AssessmentData.painScale (from AROM) over UserAssess.painScale
    final initialValue = AssessmentData.painScale > 0 ? AssessmentData.painScale : UserAssess.painScale;
    
    print('AssessPainLevel: Initializing from AROM assessment');
    print('AssessPainLevel: AssessmentData.painScale = ${AssessmentData.painScale}');
    print('AssessPainLevel: UserAssess.painScale = ${UserAssess.painScale}');
    print('AssessPainLevel: Using initialValue = $initialValue');
    
    if (initialValue < 1) {
      selectedPainLevel = 1;
      // Also update the stored values to prevent 0 from persisting
      UserAssess.painScale = 1;
      AssessmentData.painScale = 1;
    } else if (initialValue > 10) {
      selectedPainLevel = 10;
    } else {
      selectedPainLevel = initialValue;
    }
    print('AssessPainLevel: selectedPainLevel initialized to: $selectedPainLevel');
    print('AssessPainLevel: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('AssessPainLevel: build() called');
    print('AssessPainLevel: Current AssessmentData.painScale in build = "${AssessmentData.painScale}"');
    print('AssessPainLevel: Current UserAssess.painScale in build = "${UserAssess.painScale}"');
    print('AssessPainLevel: Current selectedPainLevel = $selectedPainLevel');
    
    try {
      return _buildPageContent(context);
    } catch (e) {
      print('AssessPainLevel: ERROR in build() - $e');
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
                    "Pain Level",
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
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress Section
                    _buildProgressSection(4, 8, "Pain Level Assessment"),
                    
                    const SizedBox(height: 24),

                    // Question Section
                    _buildQuestionSection(
                      "Pain Intensity",
                      "On a scale of 1-10, how would you rate your current pain level?",
                      Icons.sentiment_neutral,
                    ),

                    const SizedBox(height: 24),

                    // Pain Scale
                    _buildPainScale(),

                    const SizedBox(height: 32),

                    // Next Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: selectedPainLevel >= 1 ? () {
            Navigator.push(
              context,
              PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => AssessPainType(),
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
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Continue Assessment",
                              style: GoogleFonts.ptSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
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
            color: Colors.black.withOpacity(0.04),
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
                      color: mainColor.withOpacity(0.1),
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
            color: Colors.black.withOpacity(0.04),
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
                  color: mainColor.withOpacity(0.1),
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


  Color _getPainColor(int level) {
    // Low (1-3): Green
    if (level <= 3) return successColor;
    // Moderate (4-7): Yellow-Orange
    if (level <= 7) return const Color(0xFFF59E0B);
    // Severe (8-10): Red, with dark red/mahogany for most severe (9-10)
    if (level <= 8) return const Color(0xFFEF4444);
    return mainColor; // Dark red/mahogany for most severe (9-10)
  }

  String _getPainDescription(int level) {
    if (level <= 2) return "Mild pain - barely noticeable";
    if (level <= 4) return "Moderate pain - noticeable but manageable";
    if (level <= 6) return "Moderately severe pain - interferes with daily activities";
    if (level <= 8) return "Severe pain - makes it difficult to concentrate";
    return "Unbearable pain - bed rest required";
  }

  IconData _getPainIcon(int level) {
    if (level <= 2) return Icons.sentiment_very_satisfied;
    if (level <= 4) return Icons.sentiment_neutral;
    if (level <= 6) return Icons.sentiment_dissatisfied;
    if (level <= 8) return Icons.sentiment_very_dissatisfied;
    return Icons.sick;
  }

  // Convert numerical pain scale (1-10) to categorical for filtering
  String _getCategoricalPainLevel(int level) {
    if (level <= 3) return "Low";
    if (level <= 6) return "Moderate";
    return "Severe";
  }

  Widget _buildPainScale() {
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pain scale header
          Text(
            "Select your pain level:",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 24),
          
          // Aesthetic Slider
          _buildAestheticSlider(),
          
          const SizedBox(height: 20),
          
          // Pain level display
          _buildPainLevelDisplay(),
          
          const SizedBox(height: 16),
          
          // Categorical indicators
          _buildCategoricalIndicators(),
        ],
      ),
    );
  }

  Widget _buildAestheticSlider() {
    return Container(
      height: 60,
      child: Stack(
        children: [
          // Background track with gradient
          Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                colors: [
                  successColor, // Low (1-3): Green
                  successColor, // End of Low range (position 3)
                  const Color(0xFFF59E0B), // Moderate (4-7): Yellow-Orange
                  const Color(0xFFF59E0B), // End of Moderate range (position 7)
                  const Color(0xFFEF4444), // Severe (8): Bright red
                  mainColor, // Severe (9-10): Dark red/mahogany
                ],
                stops: const [0.0, 0.222, 0.333, 0.667, 0.778, 1.0],
              ),
            ),
          ),
          
          // Slider
          Positioned.fill(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: _getPainColor(selectedPainLevel),
                thumbShape: _CustomSliderThumb(
                  painLevel: selectedPainLevel,
                  color: _getPainColor(selectedPainLevel),
                ),
                overlayColor: _getPainColor(selectedPainLevel).withOpacity(0.2),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackHeight: 8,
              ),
              child: Slider(
                value: selectedPainLevel.clamp(1, 10).toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  final newValue = value.round().clamp(1, 10); // Ensure 0 is never allowed
                  print('AssessPainLevel: Slider changed to: $newValue');
                  print('AssessPainLevel: Before setState - AssessmentData.painScale = "${AssessmentData.painScale}"');
                  print('AssessPainLevel: Before setState - UserAssess.painScale = "${UserAssess.painScale}"');
                  
                  setState(() {
                    selectedPainLevel = newValue;
                    // Ensure 0 is never set in data storage
                    UserAssess.painScale = newValue.clamp(1, 10);
                    AssessmentData.painScale = newValue.clamp(1, 10);
                    
                    // Set categorical pain level for filtering
                    UserAssess.painLevel = _getCategoricalPainLevel(newValue);
                  });
                  
                  print('AssessPainLevel: Selected pain level: $newValue');
                  print('AssessPainLevel: Categorical pain level: ${_getCategoricalPainLevel(newValue)}');
                  print('AssessPainLevel: Final AssessmentData.painScale = "${AssessmentData.painScale}"');
                  print('AssessPainLevel: Final UserAssess.painScale = "${UserAssess.painScale}"');
                  print('AssessPainLevel: Final UserAssess.painLevel = "${UserAssess.painLevel}"');
                },
              ),
            ),
          ),
          
          // Scale markers
          Positioned(
            left: 20,
            right: 20,
            top: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (index) {
                final painLevel = index + 1; // Convert 0-9 index to 1-10 pain level
                return GestureDetector(
                  onTap: () {
                    print('AssessPainLevel: Marker tapped - painLevel: $painLevel');
                    // Ensure painLevel is always >= 1 (painLevel is already 1-10 from index conversion)
                    final clampedLevel = painLevel.clamp(1, 10);
                    setState(() {
                      selectedPainLevel = clampedLevel;
                      UserAssess.painScale = clampedLevel;
                      AssessmentData.painScale = clampedLevel;
                      UserAssess.painLevel = _getCategoricalPainLevel(clampedLevel);
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selectedPainLevel == painLevel 
                          ? _getPainColor(painLevel) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedPainLevel == painLevel 
                            ? _getPainColor(painLevel) 
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$painLevel',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selectedPainLevel == painLevel 
                              ? Colors.white 
                              : detailColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainLevelDisplay() {
    final categoricalLevel = _getCategoricalPainLevel(selectedPainLevel);
    final color = _getPainColor(selectedPainLevel);
    final description = _getPainDescription(selectedPainLevel);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Pain level header with icon and number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPainIcon(selectedPainLevel),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Pain Level: $selectedPainLevel",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  categoricalLevel,
                  style: GoogleFonts.ptSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pain description
          Text(
            description,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoricalIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCategoryIndicator("Low", 1, 3),
        _buildCategoryIndicator("Moderate", 4, 6),
        _buildCategoryIndicator("Severe", 7, 10),
      ],
    );
  }

  Widget _buildCategoryIndicator(String category, int startRange, int endRange) {
    final isInRange = selectedPainLevel >= startRange && selectedPainLevel <= endRange;
    final color = _getPainColorFromLevel(_getCategoricalPainLevel(selectedPainLevel));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInRange ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInRange ? color : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: GoogleFonts.ptSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isInRange ? color : Colors.grey.shade600,
        ),
      ),
    );
  }

  // Helper method to get color from categorical level
  Color _getPainColorFromLevel(String level) {
    switch (level) {
      case "Low":
        return successColor; // Green
      case "Moderate":
        return const Color(0xFFF59E0B); // Yellow-Orange
      case "Severe":
        return mainColor; // Dark red/mahogany for severe
      default:
        return detailColor;
    }
  }
}

// Custom slider thumb that shows the pain level number
class _CustomSliderThumb extends SliderComponentShape {
  final int painLevel;
  final Color color;

  const _CustomSliderThumb({
    required this.painLevel,
    required this.color,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(32, 32);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    // Draw outer ring
    final Paint outerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20, outerPaint);
    
    // Draw main thumb
    final Paint thumbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 16, thumbPaint);
    
    // Draw white border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 16, borderPaint);
    
    // Draw pain level number
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '$painLevel',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
}