import 'package:flutter/material.dart';

/// Centralized animation configuration for PocketPT healthcare application
/// Provides consistent timing, curves, and transition builders across the app
class PocketPTAnimations {
  // Private constructor to prevent instantiation
  PocketPTAnimations._();

  // Standard durations for medical app
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Medical-appropriate curves
  static const Curve medicalEase = Curves.easeInOutCubic;
  static const Curve gentleBounce = Curves.elasticOut;
  static const Curve subtleEase = Curves.easeInOut;

  // Animation durations for specific use cases
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration microInteraction = Duration(milliseconds: 150);
  static const Duration loadingAnimation = Duration(milliseconds: 800);
  static const Duration staggeredDelay = Duration(milliseconds: 100);

  /// Check if animations should be disabled based on user preferences
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// Standard page transition with medical-appropriate timing
  static Widget medicalPageTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!shouldAnimate(context)) {
      return child;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: medicalEase)),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Subtle scale animation for interactive elements
  static Widget subtleScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    if (!shouldAnimate(context)) {
      return child;
    }

    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: subtleEase)),
      child: child,
    );
  }

  /// Fade animation for content reveals
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    if (!shouldAnimate(context)) {
      return child;
    }

    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Staggered animation delay calculator
  static Duration getStaggeredDelay(int index, {Duration baseDelay = const Duration(milliseconds: 100)}) {
    return Duration(milliseconds: baseDelay.inMilliseconds * index);
  }

  /// Create animation controller with standard configuration
  static AnimationController createController(
    TickerProvider vsync, {
    Duration? duration,
    Duration? reverseDuration,
  }) {
    return AnimationController(
      duration: duration ?? medium,
      reverseDuration: reverseDuration ?? fast,
      vsync: vsync,
    );
  }

  /// Create curved animation with medical-appropriate curve
  static CurvedAnimation createCurvedAnimation(
    Animation<double> parent, {
    Curve? curve,
  }) {
    return CurvedAnimation(
      parent: parent,
      curve: curve ?? medicalEase,
    );
  }

  /// Create tween with appropriate value range for medical UI
  static Tween<double> createScaleTween({double begin = 0.95, double end = 1.0}) {
    return Tween<double>(begin: begin, end: end);
  }

  static Tween<double> createOpacityTween({double begin = 0.0, double end = 1.0}) {
    return Tween<double>(begin: begin, end: end);
  }

  static Tween<Offset> createSlideTween({
    Offset begin = const Offset(0.0, 0.3),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end);
  }

  /// Color transition for medical UI elements
  static Tween<Color?> createColorTween(Color begin, Color end) {
    return Tween<Color?>(begin: begin, end: end);
  }

  /// Animation builder for staggered reveals
  static Widget staggeredBuilder({
    required int index,
    required Widget child,
    required AnimationController controller,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          (index * delay.inMilliseconds) / duration.inMilliseconds,
          1.0,
          curve: medicalEase,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Custom page route for medical applications with consistent animations
class MedicalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final RouteSettings settings;

  MedicalPageRoute({
    required this.child,
    required this.settings,
    Duration? transitionDuration,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return PocketPTAnimations.medicalPageTransition(
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
          transitionDuration: transitionDuration ?? PocketPTAnimations.pageTransition,
        );

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => false;
}

/// Animation utilities for common UI patterns
class AnimationUtils {
  static Widget createShimmerEffect({
    required double width,
    required double height,
    Color? baseColor,
    Color? highlightColor,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return _ShimmerWidget(
      width: width,
      height: height,
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      duration: duration,
    );
  }

  static Widget createPulseEffect({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double scale = 1.05,
  }) {
    return _PulseWidget(
      duration: duration,
      scale: scale,
      child: child,
    );
  }

  static Widget createBounceEffect({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    double bounceHeight = 10.0,
  }) {
    return _BounceWidget(
      duration: duration,
      bounceHeight: bounceHeight,
      child: child,
    );
  }
}

/// Shimmer loading effect widget
class _ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const _ShimmerWidget({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    required this.duration,
  });

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = PocketPTAnimations.createController(
      this,
      duration: widget.duration,
    );
    _animation = PocketPTAnimations.createCurvedAnimation(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PocketPTAnimations.shouldAnimate(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pulse effect widget
class _PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;

  const _PulseWidget({
    required this.child,
    required this.duration,
    required this.scale,
  });

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = PocketPTAnimations.createController(
      this,
      duration: widget.duration,
    );
    _animation = PocketPTAnimations.createCurvedAnimation(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PocketPTAnimations.shouldAnimate(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animation.value * (widget.scale - 1.0)),
          child: widget.child,
        );
      },
    );
  }
}

/// Bounce effect widget
class _BounceWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double bounceHeight;

  const _BounceWidget({
    required this.child,
    required this.duration,
    required this.bounceHeight,
  });

  @override
  State<_BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<_BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = PocketPTAnimations.createController(
      this,
      duration: widget.duration,
    );
    _animation = PocketPTAnimations.createCurvedAnimation(
      _controller,
      curve: PocketPTAnimations.gentleBounce,
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!PocketPTAnimations.shouldAnimate(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -widget.bounceHeight * _animation.value),
          child: widget.child,
        );
      },
    );
  }
}
