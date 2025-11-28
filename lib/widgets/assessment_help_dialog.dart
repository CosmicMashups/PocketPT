import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Comprehensive help dialog for muscle-specific ROM assessments
/// 
/// Provides detailed guidance for ROM assessments including:
/// - Muscle-specific overview and anatomy information
/// - Step-by-step positioning and movement instructions
/// - Camera positioning tips for optimal assessment
/// - Information about what measurements are taken
/// - Troubleshooting tips for common issues
/// 
/// Usage:
/// ```dart
/// AssessmentHelpDialog(
///   muscleGroup: 'Hamstrings',
///   side: 'Right',
/// )
/// ```
class AssessmentHelpDialog extends StatelessWidget {
  final String muscleGroup;
  final String side;

  const AssessmentHelpDialog({
    super.key,
    required this.muscleGroup,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF8B2E2E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assessment Help',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${muscleGroup.isNotEmpty ? muscleGroup : 'Muscle'} Assessment ($side Side)',
                          style: GoogleFonts.ptSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      'Overview',
                      Icons.info_outline,
                      _getOverviewContent(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Instructions',
                      Icons.list_alt,
                      _getInstructionsContent(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Positioning Tips',
                      Icons.place,
                      _getPositioningTips(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'What We Measure',
                      Icons.analytics,
                      _getMeasurementInfo(),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      'Troubleshooting',
                      Icons.build,
                      _getTroubleshootingTips(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF8B2E2E),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            content,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              height: 1.5,
              color: const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  String _getOverviewContent() {
    switch (muscleGroup.toLowerCase()) {
      case 'hamstrings':
        return 'The hamstring assessment measures the flexibility and range of motion of the muscles at the back of your thigh. These muscles are crucial for walking, running, and bending at the hip and knee.';
      case 'quadriceps':
        return 'The quadriceps assessment evaluates the strength and flexibility of the large muscles at the front of your thigh. These muscles are essential for standing, walking, and extending your knee.';
      case 'calves':
      case 'calf':
        return 'The calf assessment measures the flexibility of your lower leg muscles, particularly the gastrocnemius and soleus. These muscles are important for walking, running, and maintaining balance.';
      case 'gluteals':
        return 'The gluteal assessment evaluates the strength and flexibility of your buttock muscles. These muscles are crucial for hip extension, stability, and overall posture.';
      case 'triceps':
        return 'The triceps assessment measures the range of motion and flexibility of the muscles at the back of your upper arm. These muscles are important for pushing movements and arm extension.';
      case 'biceps':
        return 'The biceps assessment evaluates the flexibility and range of motion of the muscles at the front of your upper arm. These muscles are essential for pulling movements and arm flexion.';
      case 'shoulders':
      case 'deltoids':
        return 'The shoulder assessment measures the range of motion and flexibility of your shoulder joint and surrounding muscles. Good shoulder mobility is essential for daily activities and athletic performance.';
      case 'abdominals':
        return 'The abdominal assessment evaluates the strength and flexibility of your core muscles. These muscles are crucial for posture, stability, and protecting your spine.';
      case 'obliques':
        return 'The oblique assessment measures the flexibility and strength of the side abdominal muscles. These muscles are important for trunk rotation and lateral movement.';
      case 'lower back':
        return 'The lower back assessment evaluates the flexibility and strength of the muscles supporting your spine. These muscles are crucial for posture and preventing back pain.';
      case 'multifidus':
        return 'The multifidus assessment measures the deep stabilizing muscles of your spine. These small but important muscles help maintain spinal alignment and prevent injury.';
      case 'chest':
        return 'The chest assessment evaluates the flexibility and range of motion of your pectoral muscles. These muscles are important for pushing movements and shoulder stability.';
      default:
        return 'This assessment measures the range of motion and flexibility of your selected muscle group. Proper assessment helps identify any limitations and guides appropriate treatment.';
    }
  }

  String _getInstructionsContent() {
    switch (muscleGroup.toLowerCase()) {
      case 'hamstrings':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Lift your $side leg to 90° at the hip
• Slowly straighten your knee as much as possible
• Hold the position for 3 seconds
• Return to starting position slowly

3. REPETITIONS:
• Perform the movement 3-5 times
• Move slowly and controlled
• Don't force the movement''';
      case 'quadriceps':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Lift your $side leg to 90° at the hip
• Slowly extend your knee as much as possible
• Hold the position for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform the movement 3-5 times
• Keep your back straight
• Move in a controlled manner''';
      case 'calves':
      case 'calf':
        return '''1. POSITIONING:
• Stand side-on to the camera
• Position yourself 3-4 feet away
• Ensure your leg is fully visible

2. ASSESSMENT MOVEMENT:
• Step forward with your $side foot
• Keep your heel on the ground
• Lean forward from the ankle
• Move your knee over your toe
• Hold for 3 seconds

3. REPETITIONS:
• Perform 3-5 repetitions
• Maintain balance throughout
• Don't force the movement''';
      case 'gluteals':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Extend your $side leg backward
• Keep your knee straight
• Lift as high as comfortable
• Hold for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform 3-5 repetitions
• Keep your torso upright
• Don't lean forward excessively''';
      case 'triceps':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your arms are fully visible

2. ASSESSMENT MOVEMENT:
• Raise your $side arm overhead
• Bend your elbow behind your head
• Slowly straighten your arm
• Hold for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform 3-5 repetitions
• Keep your elbow pointing up
• Move slowly and controlled''';
      case 'biceps':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your arms are fully visible

2. ASSESSMENT MOVEMENT:
• Start with your $side arm at your side
• Slowly bend your elbow
• Bring your hand toward your shoulder
• Hold for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform 3-5 repetitions
• Keep your upper arm still
• Move in a controlled manner''';
      case 'shoulders':
      case 'deltoids':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your arms are fully visible

2. ASSESSMENT MOVEMENT:
• Start with your $side arm at your side
• Slowly raise your arm to the side
• Lift as high as possible
• Hold for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform 3-5 repetitions
• Keep your arm straight
• Don't shrug your shoulder''';
      case 'abdominals':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Place your hands on your hips
• Slowly bend forward from your waist
• Reach toward the ground
• Hold for 3 seconds
• Return to upright position

3. REPETITIONS:
• Perform 3-5 repetitions
• Keep your knees straight
• Move slowly and controlled''';
      case 'obliques':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Place your hands on your hips
• Slowly bend to the $side
• Reach as far as comfortable
• Hold for 3 seconds
• Return to center

3. REPETITIONS:
• Perform 3-5 repetitions
• Keep your shoulders aligned
• Don't rotate your torso''';
      case 'lower back':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Place your hands on your lower back
• Slowly bend backward
• Arch your back gently
• Hold for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform 3-5 repetitions
• Don't force the movement
• Keep your knees slightly bent''';
      case 'multifidus':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Place your hands on your hips
• Slowly rotate your torso to the $side
• Keep your hips facing forward
• Hold for 3 seconds
• Return to center

3. REPETITIONS:
• Perform 3-5 repetitions
• Move slowly and controlled
• Don't force the rotation''';
      case 'chest':
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your arms are fully visible

2. ASSESSMENT MOVEMENT:
• Start with your $side arm at your side
• Slowly raise your arm forward and up
• Lift as high as possible
• Hold for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform 3-5 repetitions
• Keep your arm straight
• Don't lean backward''';
      default:
        return '''1. POSITIONING:
• Stand 3-4 feet from the camera
• Face the camera directly
• Ensure your full body is visible

2. ASSESSMENT MOVEMENT:
• Follow the on-screen instructions
• Move slowly and controlled
• Hold positions for 3 seconds
• Return to starting position

3. REPETITIONS:
• Perform 3-5 repetitions
• Don't force any movement
• Stop if you feel pain''';
    }
  }

  String _getPositioningTips() {
    return '''• Stand 3-4 feet away from the camera
• Ensure good lighting on your body
• Wear form-fitting clothing for better visibility
• Keep the camera at eye level
• Ensure your full body is visible in the frame
• Maintain good posture throughout
• Don't rush the movements
• Stop if you feel any pain or discomfort''';
  }

  String _getMeasurementInfo() {
    switch (muscleGroup.toLowerCase()) {
      case 'hamstrings':
        return 'We measure the angle between your hip, knee, and ankle to assess hamstring flexibility and identify any compensatory movements in your pelvis.';
      case 'quadriceps':
        return 'We measure the angle between your hip, knee, and ankle to evaluate quadriceps strength and knee extension range of motion.';
      case 'calves':
      case 'calf':
        return 'We measure the displacement between your knee and ankle to assess calf flexibility and dorsiflexion range of motion.';
      case 'gluteals':
        return 'We measure the angle between your shoulder, hip, and knee to evaluate gluteal strength and hip extension range of motion.';
      case 'triceps':
        return 'We measure the angle between your hip, shoulder, and elbow to assess triceps flexibility and elbow extension range of motion.';
      case 'biceps':
        return 'We measure the angle between your shoulder, elbow, and wrist to evaluate biceps flexibility and elbow flexion range of motion.';
      case 'shoulders':
      case 'deltoids':
        return 'We measure the angle between your hip, shoulder, and elbow to assess shoulder mobility and range of motion.';
      case 'abdominals':
        return 'We measure trunk flexion angles to assess abdominal strength and spinal mobility.';
      case 'obliques':
        return 'We measure lateral trunk movement to assess oblique muscle flexibility and spinal rotation.';
      case 'lower back':
        return 'We measure trunk extension angles to assess lower back strength and spinal flexibility.';
      case 'multifidus':
        return 'We measure trunk rotation angles to assess multifidus muscle function and spinal stability.';
      case 'chest':
        return 'We measure forward elevation angles to assess chest muscle flexibility and shoulder mobility.';
      default:
        return 'We measure joint angles and movement patterns to assess your muscle flexibility, strength, and range of motion.';
    }
  }

  String _getTroubleshootingTips() {
    return '''COMMON ISSUES AND SOLUTIONS:

• Camera not detecting movement:
  - Ensure good lighting
  - Check that your full body is visible
  - Move slowly and deliberately
  - Stand closer to the camera if needed

• Assessment not starting:
  - Make sure you're positioned correctly
  - Check that the camera has permission
  - Restart the assessment if needed

• Unclear results:
  - Ensure consistent lighting
  - Wear contrasting clothing
  - Avoid busy backgrounds
  - Perform movements more slowly

• Pain or discomfort:
  - Stop the assessment immediately
  - Don't force any movements
  - Consult a healthcare provider if pain persists

• Technical issues:
  - Restart the app if needed
  - Check your internet connection
  - Ensure the app is up to date''';
  }
}
