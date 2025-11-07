import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/tutorials/overlay_tooltip.dart';
import 'package:PocketPT/tutorials/tutorial_models.dart';
import 'package:PocketPT/tutorials/tutorial_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingAnalyticsHandler extends TutorialAnalyticsHandler {
  _RecordingAnalyticsHandler(this.events);

  final List<TutorialEventType> events;

  @override
  FutureOr<void> handle(TutorialAnalyticsEvent event) {
    events.add(event.type);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TutorialService.instance.clearSteps();
    TutorialService.instance.defaultFeatureFlagResolver = null;
    TutorialService.instance.globalStepFilter = null;
    TutorialService.instance.analyticsHandler = null;

    TutorialService.instance.registerImplementation(
      TutorialImplementation.overlay,
      sequenceRunner: (
        BuildContext context,
        List<TutorialStep> steps, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialOverlay.instance.showSequence(
        context: context,
        steps: steps,
        flowId: flowId,
        emit: emit,
      ),
      singleStepRunner: (
        BuildContext context,
        TutorialStep step, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialOverlay.instance.showStep(
        context: context,
        step: step,
        flowId: flowId,
        emit: emit,
      ),
    );
  });

  tearDown(() {
    TutorialService.instance.clearSteps();
    TutorialService.instance.analyticsHandler = null;
  });

  testWidgets('tutorial service plays multi-step flow and emits analytics', (tester) async {
    final stepOneKey = GlobalKey();
    final stepTwoKey = GlobalKey();

    final steps = <TutorialStep>[
      TutorialStep(
        id: 'flow_step_one',
        pageId: 'test',
        anchorKey: stepOneKey,
        title: 'Step One',
        description: 'First step description',
        flowId: 'test_flow',
        order: 1,
      ),
      TutorialStep(
        id: 'flow_step_two',
        pageId: 'test',
        anchorKey: stepTwoKey,
        title: 'Step Two',
        description: 'Second step description',
        flowId: 'test_flow',
        order: 2,
      ),
    ];

    TutorialService.instance.registerSteps(steps);

    final recordedEvents = <TutorialEventType>[];
    TutorialService.instance.analyticsHandler = _RecordingAnalyticsHandler(recordedEvents);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Container(
                  key: stepOneKey,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: Container(
                  key: stepTwoKey,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final scaffoldContext = tester.element(find.byType(Scaffold));

    // Start tutorial flow.
    unawaited(TutorialService.instance.startFlow(scaffoldContext, 'test_flow'));

    await tester.pumpAndSettle();

    expect(find.text('Step One'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Step Two'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(recordedEvents.first, TutorialEventType.tutorialStarted);
    expect(recordedEvents.where((event) => event == TutorialEventType.stepShown).length, 2);
    expect(recordedEvents.contains(TutorialEventType.tutorialCompleted), isTrue);
  });
}

