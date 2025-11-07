import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tutorial_models.dart';
import 'tutorial_preferences.dart';

/// Default analytics handler that logs tutorial lifecycle and persists completion state.
class DefaultTutorialAnalyticsHandler extends TutorialAnalyticsHandler {
  const DefaultTutorialAnalyticsHandler();

  @override
  FutureOr<void> handle(TutorialAnalyticsEvent event) async {
    final prefs = TutorialPreferences.instance;
    await prefs.ensureInitialized();

    if (kDebugMode) {
      debugPrint('TutorialAnalytics: ${event.type} step=${event.step?.id} flow=${event.flowId} payload=${event.payload}');
    }

    switch (event.type) {
      case TutorialEventType.stepShown:
        // No-op beyond logging.
        break;
      case TutorialEventType.stepAdvanced:
        final step = event.step;
        if (step != null && (step.metadata?['skip_if_seen'] as bool? ?? true)) {
          await prefs.markStepCompleted(step.id);
        }
        break;
      case TutorialEventType.tutorialSkipped:
        // Keep state unchanged so users can revisit tutorials later.
        break;
      case TutorialEventType.tutorialCompleted:
        final step = event.step;
        if (step != null) {
          await prefs.markStepCompleted(step.id);
        }
        await prefs.markFlowCompleted(event.flowId);
        break;
      case TutorialEventType.tutorialStarted:
        // Clear historical completion when flow restarts manually.
        if (event.payload?['singleStep'] == true && event.step != null) {
          await prefs.resetStep(event.step!.id);
        }
        break;
    }
  }
}

