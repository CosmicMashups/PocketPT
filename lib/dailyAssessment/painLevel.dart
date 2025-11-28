import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/globals.dart';
import '../assessment/assessment_data.dart';
import 'cameraPose.dart';

class PainLevelPage extends StatefulWidget {
  const PainLevelPage({super.key});

  @override
  State<PainLevelPage> createState() => _PainLevelPageState();
}

class _PainLevelPageState extends State<PainLevelPage> {
  int selectedPainLevel = 0;
  String painLevel = UserAssess.painLevel;
  int painScale = UserAssess.painScale;

  String getPainEmoji(int value) {
    if (value <= 3) return "🙂";
    if (value <= 7) return "😟";
    return "😖";
  }

  String getPainDescription(int value) {
    if (value <= 3) return "Low";
    if (value <= 7) return "Moderate";
    return "Severe";
  }

  Color _getPainColor(int value) {
    // Low (0-3): Green
    if (value <= 3) return const Color(0xFF10B981);
    // Moderate (4-7): Yellow-Orange
    if (value <= 7) return const Color(0xFFF59E0B);
    // Severe (8-10): Red, with dark red/mahogany for most severe (9-10)
    if (value <= 8) return const Color(0xFFEF4444);
    return const Color(0xFF8B2E2E); // Dark red/mahogany for most severe (9-10)
  }

  String _getPainDescription(int level) {
    if (level == 0) return "No pain";
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

  // Convert numerical pain scale (0-10) to categorical for filtering
  String _getCategoricalPainLevel(int level) {
    if (level <= 3) return "Low";
    if (level <= 6) return "Moderate";
    return "Severe";
  }

  @override
  void initState() {
    super.initState();
    print('PainLevelPage: initState() called');
    print('PainLevelPage: Current AssessmentData.painScale = "${AssessmentData.painScale}"');
    print('PainLevelPage: Current UserAssess.painScale = "${UserAssess.painScale}"');
    
    // Initialize selectedPainLevel from local data
    selectedPainLevel = UserAssess.painScale;
    print('PainLevelPage: selectedPainLevel initialized to: $selectedPainLevel');
    print('PainLevelPage: initState() completed');
  }

  @override
  Widget build(BuildContext context) {
    print('PainLevelPage: build() called');
    print('PainLevelPage: Current AssessmentData.painScale in build = "${AssessmentData.painScale}"');
    print('PainLevelPage: Current UserAssess.painScale in build = "${UserAssess.painScale}"');
    print('PainLevelPage: selectedPainLevel in build = $selectedPainLevel');
    
    return _buildPageContent(context);
  }

  Widget _buildPageContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: _buildBody(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: const Color(0xFF8B2E2E),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const CameraPosePage(),
                  transitionsBuilder: (_, anim, __, child) {
                    return SlideTransition(
                      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          Expanded(
            child: Text(
              "Daily Assessment",
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
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSection(),
          const SizedBox(height: 32),
          _buildQuestionSection(),
          const SizedBox(height: 32),
          _buildPainScale(),
          const SizedBox(height: 32),
          _buildPainDescription(),
          const SizedBox(height: 40),
          _buildCompleteButton(context),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B2E2E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFF8B2E2E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pain Level Assessment",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Please rate your current pain level on a scale of 0-10",
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
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
                  color: const Color(0xFF8B2E2E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Color(0xFF8B2E2E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "How would you rate your current pain level?",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Use the slider below to select your pain level from 0 (no pain) to 10 (unbearable pain).",
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
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
              color: const Color(0xFF8B2E2E),
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
                  const Color(0xFF10B981), // Low (0-3): Green
                  const Color(0xFF10B981), // End of Low range (position 3)
                  const Color(0xFFF59E0B), // Moderate (4-7): Yellow-Orange
                  const Color(0xFFF59E0B), // End of Moderate range (position 7)
                  const Color(0xFFEF4444), // Severe (8): Bright red
                  const Color(0xFF8B2E2E), // Severe (9-10): Dark red/mahogany
                ],
                stops: const [0.0, 0.3, 0.4, 0.7, 0.8, 1.0],
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
                value: selectedPainLevel.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) {
                  final newValue = value.round();
                  print('PainLevelPage: Slider changed to: $newValue');
                  print('PainLevelPage: Before setState - AssessmentData.painScale = "${AssessmentData.painScale}"');
                  print('PainLevelPage: Before setState - UserAssess.painScale = "${UserAssess.painScale}"');
                  
                  setState(() {
                    selectedPainLevel = newValue;
                    UserAssess.painScale = newValue;
                    AssessmentData.painScale = newValue;
                    
                    // Set categorical pain level for filtering
                    UserAssess.painLevel = _getCategoricalPainLevel(newValue);
                  });
                  
                  print('PainLevelPage: Selected pain level: $newValue');
                  print('PainLevelPage: Categorical pain level: ${_getCategoricalPainLevel(newValue)}');
                  print('PainLevelPage: Final AssessmentData.painScale = "${AssessmentData.painScale}"');
                  print('PainLevelPage: Final UserAssess.painScale = "${UserAssess.painScale}"');
                  print('PainLevelPage: Final UserAssess.painLevel = "${UserAssess.painLevel}"');
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
              children: List.generate(11, (index) {
                return GestureDetector(
                  onTap: () {
                    print('PainLevelPage: Marker tapped - index: $index');
                    setState(() {
                      selectedPainLevel = index;
                      UserAssess.painScale = index;
                      AssessmentData.painScale = index;
                      UserAssess.painLevel = _getCategoricalPainLevel(index);
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selectedPainLevel == index 
                          ? _getPainColor(index) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedPainLevel == index 
                            ? _getPainColor(index) 
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selectedPainLevel == index 
                              ? Colors.white 
                              : const Color(0xFF6B7280),
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPainIcon(selectedPainLevel),
            color: color,
            size: 20,
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
    );
  }

  Widget _buildCategoricalIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCategoryIndicator("Low", 0, 3),
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
        return const Color(0xFF10B981); // Green
      case "Moderate":
        return const Color(0xFFF59E0B); // Yellow-Orange
      case "Severe":
        return const Color(0xFF8B2E2E); // Dark red/mahogany for severe
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildPainDescription() {
    final description = _getPainDescription(selectedPainLevel);
    final color = _getPainColor(selectedPainLevel);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPainIcon(selectedPainLevel),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              description,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return Container(
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
            color: const Color(0xFF8B2E2E).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            // Use addEntryAndSave to add entry without overwriting existing ones
            // This matches the sample data behavior and saves to both Hive and Firebase
            await PainHistory.addEntryAndSave(
              painScale: selectedPainLevel,
              painLevel: getPainDescription(selectedPainLevel),
              date: DateTime.now(), // Use current date/time
            );
            
            // Also update UserAssess for consistency
            UserAssess.painScale = selectedPainLevel;
            UserAssess.painLevel = _getCategoricalPainLevel(selectedPainLevel);
            AssessmentData.painScale = selectedPainLevel;
            
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } catch (e) {
            debugPrint('PainLevelPage: Error saving pain data: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving pain data: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(
          Icons.arrow_forward,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          "Complete Assessment",
          style: GoogleFonts.ptSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CustomSliderThumb extends SliderComponentShape {
  final int painLevel;
  final Color color;

  const _CustomSliderThumb({
    required this.painLevel,
    required this.color,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
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

    // Draw outer circle
    final Paint outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 12, outerPaint);

    // Draw inner circle
    final Paint innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8, innerPaint);

    // Draw pain level number
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '$painLevel',
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 10,
          fontWeight: FontWeight.w600,
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