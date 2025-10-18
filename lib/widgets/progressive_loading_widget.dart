import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Progressive loading widget with clear status messages
class ProgressiveLoadingWidget extends StatefulWidget {
  final String initialMessage;
  final List<String> loadingSteps;
  final VoidCallback? onComplete;
  final VoidCallback? onError;

  const ProgressiveLoadingWidget({
    super.key,
    required this.initialMessage,
    required this.loadingSteps,
    this.onComplete,
    this.onError,
  });

  @override
  State<ProgressiveLoadingWidget> createState() => _ProgressiveLoadingWidgetState();
}

class _ProgressiveLoadingWidgetState extends State<ProgressiveLoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  
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
    
    _animationController.forward();
    _startProgressiveLoading();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startProgressiveLoading() async {
    for (int i = 0; i < widget.loadingSteps.length; i++) {
      if (!mounted) return;
      
      setState(() {
        _currentStep = i;
      });
      
      // Simulate step duration
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    
    if (mounted) {
      setState(() {
        _isComplete = true;
      });
      
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
      
      if (widget.onError != null) {
        widget.onError!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Loading indicator
                  if (!_hasError)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue[400]!,
                            Colors.blue[600]!,
                          ],
                        ),
                      ),
                      child: _isComplete
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 40,
                            )
                          : CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red[400],
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Status message
                  Text(
                    _hasError
                        ? 'Error'
                        : _isComplete
                            ? 'Complete!'
                            : widget.loadingSteps.isNotEmpty
                                ? widget.loadingSteps[_currentStep]
                                : widget.initialMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _hasError
                          ? Colors.red[600]
                          : _isComplete
                              ? Colors.green[600]
                              : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (_hasError) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Progress indicator
                  if (!_hasError && widget.loadingSteps.isNotEmpty)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _isComplete
                              ? 1.0
                              : (_currentStep + 1) / widget.loadingSteps.length,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[600]!,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_currentStep + 1} of ${widget.loadingSteps.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simple loading overlay with progress support
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final double? progress;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show progress indicator or circular progress
                    if (progress != null) ...[
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!,
                              ),
                            ),
                            Center(
                              child: Text(
                                '${(progress! * 100).toInt()}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
