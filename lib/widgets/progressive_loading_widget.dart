import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'branded_progressive_loading.dart';
import '../main.dart';

/// Progressive loading widget with clear status messages
class ProgressiveLoadingWidget extends StatefulWidget {
  final String initialMessage;
  final List<String> loadingSteps;
  final VoidCallback? onComplete;
  final VoidCallback? onError;
  final bool showLogo;

  const ProgressiveLoadingWidget({
    super.key,
    required this.initialMessage,
    required this.loadingSteps,
    this.onComplete,
    this.onError,
    this.showLogo = true,
  });

  @override
  State<ProgressiveLoadingWidget> createState() => _ProgressiveLoadingWidgetState();
}

class _ProgressiveLoadingWidgetState extends State<ProgressiveLoadingWidget> {

  @override
  Widget build(BuildContext context) {
    return BrandedProgressiveLoadingWidget(
      initialMessage: widget.initialMessage,
      loadingSteps: widget.loadingSteps,
      onComplete: widget.onComplete,
      onError: widget.onError,
      showLogo: widget.showLogo,
    );
  }
}

/// Simple loading overlay with progress support
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final double? progress;
  final bool showLogo;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.progress,
    this.showLogo = true,
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
                constraints: const BoxConstraints(maxWidth: 300),
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surface
                      : Colors.white,
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
                    // Logo
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
                    
                    // Message
                    if (message != null) ...[
                      Text(
                        message!,
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : kTextHeading,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Progress or Loading Indicator
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
                              valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                            ),
                            Center(
                              child: Text(
                                '${(progress! * 100).toInt()}%',
                                style: GoogleFonts.ptSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kMainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                        ),
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
