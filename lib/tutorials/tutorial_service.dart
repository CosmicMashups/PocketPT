import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tutorial_models.dart';

typedef TutorialSequenceRunner = Future<void> Function(
  BuildContext context,
  List<TutorialStep> steps, {
  String? flowId,
  required TutorialEventEmitter emit,
});

typedef TutorialSingleStepRunner = Future<void> Function(
  BuildContext context,
  TutorialStep step, {
  String? flowId,
  required TutorialEventEmitter emit,
});

/// Central registry and coordinator for guided tutorials.
class TutorialService {
  TutorialService._();

  static final TutorialService instance = TutorialService._();

  final Map<String, TutorialStep> _stepsById = <String, TutorialStep>{};
  final Map<String, List<TutorialStep>> _flowSteps = <String, List<TutorialStep>>{};
  final Map<String, TutorialFeatureFlagResolver> _featureFlagResolvers =
      <String, TutorialFeatureFlagResolver>{};
  final Map<TutorialImplementation, TutorialSequenceRunner> _sequenceRunners =
      <TutorialImplementation, TutorialSequenceRunner>{};
  final Map<TutorialImplementation, TutorialSingleStepRunner> _singleRunners =
      <TutorialImplementation, TutorialSingleStepRunner>{};

  TutorialFeatureFlagResolver? defaultFeatureFlagResolver;
  TutorialGlobalFilter? globalStepFilter;
  TutorialAnalyticsHandler? analyticsHandler;
  bool enableDebugLogging = false;

  /// Registers a set of tutorial steps. Existing steps with the same id are replaced.
  void registerSteps(List<TutorialStep> steps) {
    for (final step in steps) {
      _stepsById[step.id] = step;
      if (step.flowId != null) {
        final flowSteps = _flowSteps.putIfAbsent(step.flowId!, () => <TutorialStep>[]);
        final existingIndex = flowSteps.indexWhere((element) => element.id == step.id);
        if (existingIndex >= 0) {
          flowSteps[existingIndex] = step;
        } else {
          flowSteps.add(step);
        }
        flowSteps.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      }
    }
  }

  /// Clears all registered steps and flows.
  void clearSteps() {
    _stepsById.clear();
    _flowSteps.clear();
  }

  /// Registers a feature flag resolver used to gate tutorial steps.
  void registerFeatureFlag(String flagId, TutorialFeatureFlagResolver resolver) {
    _featureFlagResolvers[flagId] = resolver;
  }

  /// Registers a sequence/single-step runner for a given implementation.
  void registerImplementation(
    TutorialImplementation implementation, {
    required TutorialSequenceRunner sequenceRunner,
    required TutorialSingleStepRunner singleStepRunner,
  }) {
    _sequenceRunners[implementation] = sequenceRunner;
    _singleRunners[implementation] = singleStepRunner;
  }

  /// Launches a multi-step tutorial flow.
  Future<void> startFlow(
    BuildContext context,
    String flowId, {
    TutorialImplementation implementation = TutorialImplementation.overlay,
  }) async {
    final steps = List<TutorialStep>.from(_flowSteps[flowId] ?? const <TutorialStep>[]);
    if (steps.isEmpty) {
      _logDebug('No tutorial steps registered for flow "$flowId".');
      return;
    }

    final eligibleSteps = await _filterEligibleSteps(context, steps, flowId: flowId);
    if (eligibleSteps.isEmpty) {
      _logDebug('All tutorial steps for flow "$flowId" were filtered out.');
      return;
    }

    final sequenceRunner = _sequenceRunners[implementation];
    if (sequenceRunner == null) {
      _logDebug('No sequence runner registered for implementation "$implementation".');
      return;
    }

    final TutorialStep firstStep = eligibleSteps.first;
    _emitEvent(
      TutorialEventType.tutorialStarted,
      flowId: flowId,
      step: firstStep,
      payload: <String, Object?>{
        'stepCount': eligibleSteps.length,
        'implementation': implementation.name,
      },
    );

    var wasSkipped = false;
    void emitter(
      TutorialEventType type,
      TutorialStep step, {
      String? flowId,
      Map<String, Object?>? payload,
    }) {
      if (type == TutorialEventType.tutorialSkipped) {
        wasSkipped = true;
      }
      _emitEvent(type, flowId: flowId, step: step, payload: payload);
    }

    await sequenceRunner(
      context,
      eligibleSteps,
      flowId: flowId,
      emit: emitter,
    );

    if (!wasSkipped) {
      final TutorialStep lastStep = eligibleSteps.last;
      _emitEvent(
        TutorialEventType.tutorialCompleted,
        flowId: flowId,
        step: lastStep,
        payload: <String, Object?>{
          'stepCount': eligibleSteps.length,
          'implementation': implementation.name,
        },
      );
    }
  }

  /// Displays an individual step on demand.
  Future<void> showStep(
    BuildContext context,
    String stepId, {
    TutorialImplementation implementation = TutorialImplementation.overlay,
    String? flowId,
  }) async {
    final step = _stepsById[stepId];
    if (step == null) {
      _logDebug('Tutorial step "$stepId" is not registered.');
      return;
    }

    if (!await _isStepEligible(context, step)) {
      _logDebug('Tutorial step "$stepId" filtered out by feature flag or predicate.');
      return;
    }

    final runner = _singleRunners[implementation];
    if (runner == null) {
      _logDebug('No single-step runner registered for implementation "$implementation".');
      return;
    }

    _emitEvent(
      TutorialEventType.tutorialStarted,
      flowId: flowId ?? step.flowId,
      step: step,
      payload: <String, Object?>{
        'stepCount': 1,
        'implementation': implementation.name,
        'singleStep': true,
      },
    );

    var wasSkipped = false;
    void emitter(
      TutorialEventType type,
      TutorialStep innerStep, {
      String? flowId,
      Map<String, Object?>? payload,
    }) {
      if (type == TutorialEventType.tutorialSkipped) {
        wasSkipped = true;
      }
      _emitEvent(type, flowId: flowId, step: innerStep, payload: payload);
    }

    await runner(
      context,
      step,
      flowId: flowId ?? step.flowId,
      emit: emitter,
    );

    if (!wasSkipped) {
      _emitEvent(
        TutorialEventType.tutorialCompleted,
        flowId: flowId ?? step.flowId,
        step: step,
        payload: const <String, Object?>{'stepCount': 1},
      );
    }
  }

  /// Returns a read-only view of registered steps.
  List<TutorialStep> listRegisteredSteps() => List<TutorialStep>.unmodifiable(_stepsById.values);

  /// Retrieves all steps for the provided flow identifier.
  List<TutorialStep> getFlowSteps(String flowId) =>
      List<TutorialStep>.unmodifiable(_flowSteps[flowId] ?? const <TutorialStep>[]);

  Future<List<TutorialStep>> _filterEligibleSteps(
    BuildContext context,
    List<TutorialStep> steps, {
    String? flowId,
  }) async {
    final List<TutorialStep> eligible = <TutorialStep>[];
    for (final step in steps) {
      if (await _isStepEligible(context, step)) {
        eligible.add(step);
      }
    }
    return eligible;
  }

  Future<bool> _isStepEligible(BuildContext context, TutorialStep step) async {
    if (step.featureFlagId != null) {
      final resolver = _featureFlagResolvers[step.featureFlagId!];
      if (resolver != null) {
        final enabled = await resolver();
        if (!enabled) {
          return false;
        }
      } else if (defaultFeatureFlagResolver != null) {
        final enabled = await defaultFeatureFlagResolver!.call();
        if (!enabled) {
          return false;
        }
      }
    } else if (defaultFeatureFlagResolver != null) {
      final enabled = await defaultFeatureFlagResolver!.call();
      if (!enabled) {
        return false;
      }
    }

    if (globalStepFilter != null) {
      final eligible = await globalStepFilter!.call(context, step);
      if (!eligible) {
        return false;
      }
    }

    if (step.shouldDisplay != null) {
      final shouldDisplay = await step.shouldDisplay!.call(context);
      if (!shouldDisplay) {
        return false;
      }
    }

    return true;
  }

  void _emitEvent(
    TutorialEventType type, {
    TutorialStep? step,
    String? flowId,
    Map<String, Object?>? payload,
  }) {
    if (enableDebugLogging) {
      debugPrint('[TutorialService] event=$type step=${step?.id} flow=$flowId payload=$payload');
    }
    analyticsHandler?.handle(
      TutorialAnalyticsEvent(
        type: type,
        step: step,
        flowId: flowId,
        payload: payload,
      ),
    );
  }

  void _logDebug(String message) {
    if (enableDebugLogging) {
      debugPrint('[TutorialService] $message');
    }
  }
}

