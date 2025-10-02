import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../data/globals.dart';
import 'cameraPose.dart';

class PainLevelPage extends StatefulWidget {
  const PainLevelPage({super.key});

  @override
  State<PainLevelPage> createState() => _PainLevelPageState();
}

class _PainLevelPageState extends State<PainLevelPage> {
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
    if (value <= 3) return const Color(0xFF10B981); // Green
    if (value <= 7) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    int sliderValue = UserAssess.painScale;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8B2E2E)),
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
        ),
        centerTitle: true,
        title: Text(
          "Daily Assessment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1F2937),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B2E2E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assessment, color: Color(0xFF8B2E2E), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Step 3 of 3",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B2E2E),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "100%",
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
                  ),
                ],
              ),
            ),

            // Main Content
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    "Pain Level Assessment",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please rate your current pain level on a scale of 0-10. This helps us track your progress and adjust your treatment plan.",
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pain Display
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _getPainColor(sliderValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getPainColor(sliderValue).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          getPainEmoji(sliderValue),
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "$sliderValue",
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: _getPainColor(sliderValue),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getPainDescription(sliderValue),
                          style: GoogleFonts.ptSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _getPainColor(sliderValue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF8B2E2E),
                      inactiveTrackColor: const Color(0xFFE5E7EB),
                      thumbColor: const Color(0xFF8B2E2E),
                      overlayColor: const Color(0xFF8B2E2E).withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      min: 0,
                      max: 10,
                      divisions: 10,
                      value: sliderValue.toDouble(),
                      label: sliderValue.toString(),
                      onChanged: (value) async {
                        setState(() {
                          sliderValue = value.toInt();
                          UserAssess.painScale = sliderValue;
                          UserAssess.painLevel = getPainDescription(sliderValue);
                        });
                        await PainHistory.recordTodayAndSave(
                          painScale: UserAssess.painScale,
                          painLevel: UserAssess.painLevel,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Complete Button
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
                          color: const Color(0xFF8B2E2E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await PainHistory.recordTodayAndSave(
                          painScale: sliderValue,
                          painLevel: getPainDescription(sliderValue),
                        );
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      label: Text(
                        "Complete Assessment",
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}