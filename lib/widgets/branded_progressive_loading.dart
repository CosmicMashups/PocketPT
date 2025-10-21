import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Import color constants

/// Enhanced progressive loading widget with PocketPT branding
class BrandedProgressiveLoadingWidget extends StatefulWidget {
  final String initialMessage;
  final List<String> loadingSteps;
  final VoidCallback? onComplete;
  final VoidCallback? onError;
  final bool showLogo;
  final Duration stepDuration;

  const BrandedProgressiveLoadingWidget({
    super.key,
    required this.initialMessage,
    required this.loadingSteps,
    this.onComplete,
    this.onError,
    this.showLogo = true,
    this.stepDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<BrandedProgressiveLoadingWidget> createState() => _BrandedProgressiveLoadingWidgetState();
}

class _BrandedProgressiveLoadingWidgetState extends State<BrandedProgressiveLoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _logoAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _logoRotationAnimation;
  
  int _currentStep = 0;
  bool _isComplete = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _logoAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.linear,
    ));
    
    _animationController.forward();
    _logoAnimationController.repeat();
    _startProgressiveLoading();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  void _startProgressiveLoading() async {
    for (int i = 0; i < widget.loadingSteps.length; i++) {
      if (!mounted) return;
      
      setState(() {
        _currentStep = i;
      });
      
      // Simulate step duration
      await Future.delayed(widget.stepDuration);
    }
    
    if (mounted) {
      setState(() {
        _isComplete = true;
      });
      
      _logoAnimationController.stop();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    }
  }

  void showError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
      
      _logoAnimationController.stop();
      
      if (widget.onError != null) {
        widget.onError!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? screenSize.width * 0.9 : 400,
                maxHeight: screenSize.height * 0.8,
              ),
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              decoration: BoxDecoration(
                color: isDark 
                    ? Theme.of(context).colorScheme.surface 
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Section
                  if (widget.showLogo) ...[
                    _buildLogoSection(context, isDark, isMobile),
                    SizedBox(height: isMobile ? 24 : 32),
                  ],
                  
                  // Status Section
                  _buildStatusSection(context, isDark, isMobile),
                  
                  // Progress Section
                  if (widget.loadingSteps.isNotEmpty && !_hasError) ...[
                    SizedBox(height: isMobile ? 24 : 32),
                    _buildProgressSection(context, isDark, isMobile),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isDark, bool isMobile) {
    final logoSize = isMobile ? 80.0 : 100.0;
    
    return AnimatedBuilder(
      animation: _logoRotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _logoRotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kMainColor, kSubColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: kMainColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/pocketpt.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: logoSize * 0.6,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(BuildContext context, bool isDark, bool isMobile) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_hasError) {
      statusText = 'Error';
      statusColor = kErrorColor;
      statusIcon = Icons.error_outline;
    } else if (_isComplete) {
      statusText = 'Complete!';
      statusColor = kSuccessColor;
      statusIcon = Icons.check_circle;
    } else {
      statusText = widget.loadingSteps.isNotEmpty
          ? widget.loadingSteps[_currentStep]
          : widget.initialMessage;
      statusColor = kMainColor;
      statusIcon = Icons.hourglass_empty;
    }

    return Column(
      children: [
        // Status Icon
        Container(
          width: isMobile ? 60 : 80,
          height: isMobile ? 60 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withOpacity(0.1),
            border: Border.all(
              color: statusColor,
              width: 2,
            ),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: isMobile ? 30 : 40,
          ),
        ),
        
        SizedBox(height: isMobile ? 16 : 24),
        
        // Status Text
        Text(
          statusText,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : kTextHeading,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Error Message
        if (_hasError && _errorMessage.isNotEmpty) ...[
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            _errorMessage,
            style: GoogleFonts.ptSans(
              fontSize: isMobile ? 14 : 16,
              color: isDark ? Colors.white70 : kTextNormal,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, bool isDark, bool isMobile) {
    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: _isComplete
              ? 1.0
              : (_currentStep + 1) / widget.loadingSteps.length,
          backgroundColor: isDark ? Colors.white24 : Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
          minHeight: 8,
        ),
        
        SizedBox(height: isMobile ? 12 : 16),
        
        // Progress Text
        Text(
          '${_currentStep + 1} of ${widget.loadingSteps.length}',
          style: GoogleFonts.ptSans(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : kTextNormal,
          ),
        ),
      ],
    );
  }
}

/// Branded skeleton loader for content placeholders
class BrandedSkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool showLogo;
  
  const BrandedSkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.color,
    this.showLogo = false,
  });

  @override
  State<BrandedSkeletonLoader> createState() => _BrandedSkeletonLoaderState();
}

class _BrandedSkeletonLoaderState extends State<BrandedSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.color ?? 
        (isDark ? Colors.grey[800] : Colors.grey[300]);
    final highlightColor = isDark ? Colors.grey[700] : Colors.grey[100];
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor!,
                highlightColor!,
                baseColor,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
          child: widget.showLogo
              ? Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// Branded loading indicator with PocketPT styling
class BrandedLoadingIndicator extends StatelessWidget {
  final String message;
  final double? size;
  final Color? color;
  final bool showMessage;
  final bool isInline;
  final bool showLogo;
  
  const BrandedLoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.size,
    this.color,
    this.showMessage = true,
    this.isInline = false,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indicatorColor = color ?? kMainColor;
    final indicatorSize = size ?? (isInline ? 20.0 : 40.0);
    
    if (isInline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kMainColor, kSubColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/images/pocketpt.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 12,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (showMessage) ...[
            const SizedBox(width: 8),
            Text(
              message,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: isDark ? Colors.white70 : kTextNormal,
              ),
            ),
          ],
        ],
      );
    }
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kMainColor, kSubColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kMainColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/pocketpt.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 30,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (showMessage) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.ptSans(
                fontSize: 16,
                color: isDark ? Colors.white70 : kTextNormal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

