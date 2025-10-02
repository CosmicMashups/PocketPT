import 'package:flutter/material.dart';

/// Helper class for responsive layout management
class ResponsiveLayoutHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < mobileBreakpoint;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= tabletBreakpoint;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) {
      return baseFontSize;
    } else if (isTablet(context)) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    if (isMobile(context)) {
      return baseIconSize;
    } else if (isTablet(context)) {
      return baseIconSize * 1.2;
    } else {
      return baseIconSize * 1.4;
    }
  }

  /// Get responsive column count for grid layouts
  static int getResponsiveColumnCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth - 32; // Full width minus padding
    } else if (isTablet(context)) {
      return (screenWidth - 48) / 2; // Half width minus padding
    } else {
      return (screenWidth - 64) / 3; // Third width minus padding
    }
  }
}

/// Responsive text widget that adjusts font size based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? baseFontSize;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.baseFontSize,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = baseFontSize != null
        ? ResponsiveLayoutHelper.getResponsiveFontSize(context, baseFontSize!)
        : null;

    return Text(
      text,
      style: style?.copyWith(fontSize: responsiveFontSize) ??
          TextStyle(fontSize: responsiveFontSize),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// Responsive container that adjusts padding and constraints
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? ResponsiveLayoutHelper.getResponsivePadding(context),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}

/// Responsive grid that adjusts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: WrapAlignment.start,
      children: children.map((child) {
        return SizedBox(
          width: ResponsiveLayoutHelper.getResponsiveCardWidth(context),
          child: child,
        );
      }).toList(),
    );
  }
}

/// Safe area wrapper that provides consistent safe area handling
class SafeAreaWrapper extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const SafeAreaWrapper({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

/// Scrollable wrapper that provides consistent scrolling behavior
class ScrollableWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const ScrollableWrapper({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? ResponsiveLayoutHelper.getResponsivePadding(context),
      physics: physics ?? const BouncingScrollPhysics(),
      child: child,
    );
  }
}
