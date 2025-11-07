import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'tutorial_models.dart';

/// Helper utilities for integrating third-party tutorial packages.
class TutorialPackageIntegration {
  const TutorialPackageIntegration._();

  /// Wraps the app with [ShowCaseWidget] to enable ShowcaseView sequences.
  static Widget showcaseRoot({required Widget child}) {
    return ShowCaseWidget(
      builder: (context) => child,
    );
  }

  /// Starts a ShowcaseView sequence using the registered step keys.
  static Future<void> startShowcase(
    BuildContext context,
    List<TutorialStep> steps,
    TutorialEventEmitter emit, {
    String? flowId,
  }) async {
    final controller = ShowCaseWidget.of(context);

    final keys = <GlobalKey>[];
    for (final step in steps) {
      keys.add(step.anchorKey);
    }

    // ShowcaseView runs asynchronously; schedule start after build.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    emit(
      TutorialEventType.stepShown,
      steps.first,
      flowId: flowId,
      payload: const <String, Object?>{'index': 1},
    );

    controller.startShowCase(keys);
  }

  /// Starts a TutorialCoachMark sequence for the provided steps.
  static Future<void> startCoachMark(
    BuildContext context,
    List<TutorialStep> steps,
    TutorialEventEmitter emit, {
    String? flowId,
  }) async {
    if (steps.isEmpty) return;

    final targets = <TargetFocus>[];
    for (var index = 0; index < steps.length; index++) {
      targets.add(_buildTargetFocus(steps[index], index, steps.length));
    }

    final coachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.7),
      textSkip: 'Skip',
      paddingFocus: 16,
      imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      onFinish: () {
        emit(
          TutorialEventType.tutorialCompleted,
          steps.last,
          flowId: flowId,
          payload: <String, Object?>{'stepCount': steps.length},
        );
      },
      onSkip: () {
        emit(
          TutorialEventType.tutorialSkipped,
          steps.first,
          flowId: flowId,
          payload: const <String, Object?>{'origin': 'coach_mark'},
        );
        return true;
      },
      onClickTarget: (target) {
        final index = targets.indexOf(target);
        if (index >= 0 && index < steps.length) {
          emit(
            TutorialEventType.stepAdvanced,
            steps[index],
            flowId: flowId,
            payload: <String, Object?>{'direction': 'next'},
          );
        }
      },
      onClickOverlay: (target) {
        final index = targets.indexOf(target);
        if (index >= 0 && index < steps.length) {
          emit(
            TutorialEventType.stepShown,
            steps[index],
            flowId: flowId,
            payload: <String, Object?>{'index': index + 1},
          );
        }
      },
    );

    emit(
      TutorialEventType.stepShown,
      steps.first,
      flowId: flowId,
      payload: const <String, Object?>{'index': 1},
    );

    coachMark.show(context: context);
  }

  static TargetFocus _buildTargetFocus(TutorialStep step, int index, int total) {
    return TargetFocus(
      keyTarget: step.anchorKey,
      identify: step.id,
      shape: _mapHighlightShape(step.highlightShape),
      alignSkip: Alignment.topRight,
      contents: [
        TargetContent(
          align: _mapPlacement(step.placement),
          builder: (context, controller) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: step.maxWidth),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ) ??
                          const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    if (step.longText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        step.longText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                            ) ??
                            const TextStyle(color: Colors.white60, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      '${index + 1} of $total',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static ContentAlign _mapPlacement(TutorialPlacement placement) {
    switch (placement) {
      case TutorialPlacement.top:
        return ContentAlign.top;
      case TutorialPlacement.bottom:
        return ContentAlign.bottom;
      case TutorialPlacement.left:
        return ContentAlign.left;
      case TutorialPlacement.right:
        return ContentAlign.right;
      case TutorialPlacement.auto:
        return ContentAlign.bottom;
    }
  }

  static ShapeLightFocus _mapHighlightShape(TutorialHighlightShape shape) {
    switch (shape) {
      case TutorialHighlightShape.circle:
        return ShapeLightFocus.Circle;
      case TutorialHighlightShape.roundedRect:
        return ShapeLightFocus.RRect;
      case TutorialHighlightShape.rect:
        return ShapeLightFocus.RRect;
    }
  }
}

