import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'branded_progressive_loading.dart';
import '../main.dart';

/// A specialized loading indicator widget for showing data loading states
class LoadingIndicator extends StatelessWidget {
  final String message;
  final double? size;
  final Color? color;
  final bool showMessage;
  final bool isInline;
  final bool showLogo;
  
  const LoadingIndicator({
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
    return BrandedLoadingIndicator(
      message: message,
      size: size,
      color: color,
      showMessage: showMessage,
      isInline: isInline,
      showLogo: showLogo,
    );
  }
}

/// A progress indicator widget that shows loading progress
class ProgressIndicator extends StatelessWidget {
  final double progress;
  final String message;
  final Color? color;
  final bool showPercentage;
  final bool showLogo;
  
  const ProgressIndicator({
    super.key,
    required this.progress,
    this.message = 'Loading...',
    this.color,
    this.showPercentage = true,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indicatorColor = color ?? kMainColor;
    
    return Center(
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
          
          // Progress Circle
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                // Background circle
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor.withOpacity(0.2),
                  ),
                ),
                // Progress circle
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: isDark ? Colors.white70 : kTextNormal,
            ),
            textAlign: TextAlign.center,
          ),
          if (showPercentage) ...[
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.ptSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: indicatorColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A skeleton loading widget for showing content placeholders
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool showLogo;
  
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.color,
    this.showLogo = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> {

  @override
  Widget build(BuildContext context) {
    return BrandedSkeletonLoader(
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
      color: widget.color,
      showLogo: widget.showLogo,
    );
  }
}

/// A list of skeleton loaders for showing multiple content placeholders
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final EdgeInsets? padding;
  
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 60,
    this.spacing = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
            child: SkeletonLoader(
              width: double.infinity,
              height: itemHeight,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card skeleton loader for showing card placeholders
class SkeletonCard extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  
  const SkeletonCard({
    super.key,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height ?? 120,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: double.infinity,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          SkeletonLoader(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 120,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
