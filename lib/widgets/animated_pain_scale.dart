import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/animations.dart';
import '../main.dart';

/// Enhanced animated pain scale for medical assessments
/// Provides smooth color transitions, scale animations, and haptic feedback
class AnimatedPainScale extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onSelectionChanged;
  final bool enabled;
  final String? title;
  final String? subtitle;

  const AnimatedPainScale({
    super.key,
    required this.onSelectionChanged,
    this.initialValue = 0,
    this.enabled = true,
    this.title,
    this.subtitle,
  });

  @override
  State<AnimatedPainScale> createState() => _AnimatedPainScaleState();
}

class _AnimatedPainScaleState extends State<AnimatedPainScale>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  int _selectedValue = 0;
  bool _isAnimating = false;

  // Medical pain scale colors (green to red)
  static const List<Color> _painColors = [
    Color(0xFF10B981), // Green - No pain
    Color(0xFF34D399), // Light green
    Color(0xFFFBBF24), // Yellow
    Color(0xFFF59E0B), // Orange
    Color(0xFFEF4444), // Red - Severe pain
  ];

  static const List<String> _painLabels = [
    'No Pain',
    'Mild',
    'Moderate',
    'Severe',
    'Very Severe',
  ];

  static const List<String> _painDescriptions = [
    '0 - No pain at all',
    '1-3 - Noticeable but not bothersome',
    '4-6 - Bothersome but manageable',
    '7-8 - Very bothersome',
    '9-10 - Unbearable pain',
  ];

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    
    _scaleController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.fast,
    );
    
    _colorController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    
    _scaleAnimation = PocketPTAnimations.createScaleTween(
      begin: 1.0,
      end: 1.1,
    ).animate(PocketPTAnimations.createCurvedAnimation(_scaleController));
    
    _colorAnimation = PocketPTAnimations.createColorTween(
      Colors.grey[300]!,
      _painColors[_selectedValue],
    ).animate(PocketPTAnimations.createCurvedAnimation(_colorController));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _onPainLevelSelected(int value) {
    if (!widget.enabled || _isAnimating || value == _selectedValue) return;

    setState(() {
      _selectedValue = value;
      _isAnimating = true;
    });

    // Haptic feedback for selection
    HapticFeedback.lightImpact();

    // Color transition animation
    _colorController.forward().then((_) {
      _colorController.reverse();
    });

    // Scale animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      setState(() {
        _isAnimating = false;
      });
    });

    // Notify parent
    widget.onSelectionChanged(value);
  }

  Color _getPainColor(int value) {
    if (value < 0 || value >= _painColors.length) return Colors.grey[300]!;
    return _painColors[value];
  }

  @override
  Widget build(BuildContext context) {
    if (!PocketPTAnimations.shouldAnimate(context)) {
      return _buildStaticPainScale(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextHeading,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: kTextNormal,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Pain scale visualization
        AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _colorAnimation.value ?? Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_colorAnimation.value ?? Colors.grey[300]!).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Current selection display
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getPainColor(_selectedValue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getPainColor(_selectedValue),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_hospital,
                                color: _getPainColor(_selectedValue),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pain Level: ${_painLabels[_selectedValue]}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _getPainColor(_selectedValue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pain scale buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_painColors.length, (index) {
                      return _buildPainButton(index);
                    }),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    _painDescriptions[_selectedValue],
                    style: GoogleFonts.ptSans(
                      fontSize: 12,
                      color: kTextNormal,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPainButton(int value) {
    final isSelected = value == _selectedValue;
    final color = _getPainColor(value);
    
    return GestureDetector(
      onTap: () => _onPainLevelSelected(value),
      child: AnimatedContainer(
        duration: PocketPTAnimations.fast,
        curve: PocketPTAnimations.medicalEase,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticPainScale(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kTextHeading,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: kTextNormal,
            ),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getPainColor(_selectedValue),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getPainColor(_selectedValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPainColor(_selectedValue),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_hospital,
                      color: _getPainColor(_selectedValue),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pain Level: ${_painLabels[_selectedValue]}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getPainColor(_selectedValue),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_painColors.length, (index) {
                  final isSelected = index == _selectedValue;
                  final color = _getPainColor(index);
                  
                  return GestureDetector(
                    onTap: () => _onPainLevelSelected(index),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                _painDescriptions[_selectedValue],
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  color: kTextNormal,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
