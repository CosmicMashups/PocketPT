import 'dart:async';

import 'package:flutter/material.dart';

/// Supported tutorial delivery mechanisms.
enum TutorialImplementation {
  overlay,
  showcaseView,
  coachMark,
}

/// Preferred placement for tooltip bubbles relative to the anchor widget.
enum TutorialPlacement {
  top,
  bottom,
  left,
  right,
  auto,
}

/// Highlight shape for spotlight overlays.
enum TutorialHighlightShape {
  circle,
  roundedRect,
  rect,
}

/// Priority levels for tutorial steps.
enum TutorialPriority {
  critical,
  important,
  optional,
}

/// Lifecycle events emitted by tutorial interactions.
enum TutorialEventType {
  tutorialStarted,
  stepShown,
  stepAdvanced,
  tutorialSkipped,
  tutorialCompleted,
}

/// Handler signature to determine if a tutorial step should render.
typedef TutorialStepCondition = FutureOr<bool> Function(BuildContext context);

/// Global predicate invoked before rendering any tutorial step.
typedef TutorialGlobalFilter = FutureOr<bool> Function(
  BuildContext context,
  TutorialStep step,
);

typedef TutorialEventEmitter = void Function(
  TutorialEventType type,
  TutorialStep step, {
  String? flowId,
  Map<String, Object?>? payload,
});

/// Handler signature for feature-flag lookups.
typedef TutorialFeatureFlagResolver = FutureOr<bool> Function();

/// Metadata describing fallback positioning when an anchor cannot be located.
class TutorialFallback {
  const TutorialFallback({
    this.alignment = Alignment.topRight,
    this.margin = const EdgeInsets.all(24),
    this.message = 'Need help? Explore tutorials in Settings.',
    this.actionLabel,
    this.semanticLabel,
  });

  /// Alignment of the fallback tooltip within the viewport.
  final Alignment alignment;

  /// Margin applied around the fallback tooltip bubble.
  final EdgeInsets margin;

  /// Default fallback message when the anchor is missing.
  final String message;

  /// Optional call-to-action label displayed in the fallback tooltip.
  final String? actionLabel;

  /// Optional semantics label overriding [message] for screen readers.
  final String? semanticLabel;
}

/// Immutable definition of a tutorial step.
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.pageId,
    required this.anchorKey,
    required this.title,
    required this.description,
    this.longText,
    this.placement = TutorialPlacement.auto,
    this.highlightShape = TutorialHighlightShape.roundedRect,
    this.priority = TutorialPriority.important,
    this.flowId,
    this.order,
    this.fallback = const TutorialFallback(),
    this.featureFlagId,
    this.semanticsLabel,
    this.tags = const <String>[],
    this.cameraSafe = false,
    this.maxWidth = 320,
    this.shouldDisplay,
    this.metadata,
  });

  /// Unique identifier for analytics and manifest mapping.
  final String id;

  /// Logical page or route identifier.
  final String pageId;

  /// GlobalKey used to locate the anchor widget at runtime.
  final GlobalKey anchorKey;

  /// Short title displayed in the tooltip header.
  final String title;

  /// Concise description shown within the tooltip body.
  final String description;

  /// Optional extended help text surfaced in expandable sections or docs.
  final String? longText;

  /// Preferred tooltip placement relative to the anchor.
  final TutorialPlacement placement;

  /// Highlight shape for the anchor spotlight.
  final TutorialHighlightShape highlightShape;

  /// Priority used for manifest triage.
  final TutorialPriority priority;

  /// Flow identifier for multi-step sequences (e.g., onboarding_home).
  final String? flowId;

  /// Order within the associated flow.
  final int? order;

  /// Fallback strategy when [anchorKey] cannot be resolved.
  final TutorialFallback fallback;

  /// Optional feature flag identifier gating the step.
  final String? featureFlagId;

  /// Semantics label used by screen readers (defaults to [description]).
  final String? semanticsLabel;

  /// Additional tags used for manifest filtering (e.g., 'camera', 'analytics').
  final List<String> tags;

  /// Whether the tooltip should avoid covering the anchor (e.g., camera view).
  final bool cameraSafe;

  /// Maximum tooltip bubble width in logical pixels.
  final double maxWidth;

  /// Optional runtime condition that determines if the step should display.
  final TutorialStepCondition? shouldDisplay;

  /// Arbitrary metadata exposed to analytics or tests.
  final Map<String, Object?>? metadata;
}

/// Analytics payload describing a lifecycle event.
class TutorialAnalyticsEvent {
  TutorialAnalyticsEvent({
    required this.type,
    this.step,
    this.flowId,
    this.payload,
  });

  final TutorialEventType type;
  final TutorialStep? step;
  final String? flowId;
  final Map<String, Object?>? payload;
}

/// Analytics handler interface to allow dependency injection.
abstract class TutorialAnalyticsHandler {
  const TutorialAnalyticsHandler();

  FutureOr<void> handle(TutorialAnalyticsEvent event);
}

