import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/globals.dart';
import 'c_camera.dart';
import 'c_paintype.dart';

class AssessPainLevel extends StatefulWidget {
  const AssessPainLevel({super.key});

  @override
  State<AssessPainLevel> createState() => _AssessPainLevelState();
}

class _AssessPainLevelState extends State<AssessPainLevel> {
  String painLevel = UserAssess.painLevel;
  int painScale = UserAssess.painScale;

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Professional blue
  static const subColor = Color(0xFFC24A4A); // Light blue
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green
  static const warningColor = Color(0xFFF59E0B); // Orange
  static const errorColor = Color(0xFFEF4444); // Red

  @override
  void initState() {
    super.initState();
    // Initialize painLevel and painScale from global variables
    if (UserAssess.painLevel.isNotEmpty) {
      painLevel = UserAssess.painLevel;
    }
    painScale = UserAssess.painScale;
  }

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

  Color getPainColor(int value) {
    if (value <= 3) return successColor;
    if (value <= 7) return warningColor;
    return errorColor;
  }

  @override
  Widget build(BuildContext context) {
    int sliderValue = UserAssess.painScale;
    
    return _buildContent(context, sliderValue);
  }
  
  Widget _buildContent(BuildContext context, int sliderValue) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text(
          "Pain Assessment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                mainColor,
                subColor,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const AssessPainCamera(),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Progress Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.health_and_safety, color: mainColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pain Assessment",
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: 0.6,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "3/5",
                    style: GoogleFonts.ptSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mainColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Clean Pain Assessment Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    "How intense is your current pain?",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Please rate your pain level using the scale below",
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: detailColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pain Display - Cleaner Design
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: getPainColor(sliderValue).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getPainColor(sliderValue).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          getPainEmoji(sliderValue),
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$sliderValue",
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: getPainColor(sliderValue),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          getPainDescription(sliderValue),
                          style: GoogleFonts.ptSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: getPainColor(sliderValue),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pain Scale Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "No Pain",
                        style: GoogleFonts.ptSans(
                          fontSize: 11,
                          color: detailColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "Severe Pain",
                        style: GoogleFonts.ptSans(
                          fontSize: 11,
                          color: detailColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: getPainColor(sliderValue),
                      inactiveTrackColor: const Color(0xFFE5E7EB),
                      thumbColor: getPainColor(sliderValue),
                      overlayColor: getPainColor(sliderValue).withOpacity(0.15),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      trackHeight: 5,
                    ),
                    child: Slider(
                      min: 0,
                      max: 10,
                      divisions: 10,
                      value: sliderValue.toDouble(),
                      label: sliderValue.toString(),
                      onChanged: (value) {
                        setState(() {
                          sliderValue = value.toInt();
                          UserAssess.painScale = sliderValue;
                          UserAssess.painLevel = getPainDescription(sliderValue);
                          PainHistory.recordToday(
                            painScale: UserAssess.painScale,
                            painLevel: UserAssess.painLevel,
                          );
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Confirm Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          mainColor,
                          subColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PainHistory.recordToday(
                          painScale: sliderValue,
                          painLevel: getPainDescription(sliderValue),
                        );
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const AssessPainType(),
                            transitionsBuilder: (_, anim, __, child) {
                              return SlideTransition(
                                position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      label: Text(
                        "Continue Assessment",
                        style: GoogleFonts.ptSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}