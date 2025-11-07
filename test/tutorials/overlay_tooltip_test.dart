import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/tutorials/overlay_tooltip.dart';
import 'package:PocketPT/tutorials/tutorial_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('overlay renders fallback bubble when anchor is missing', (tester) async {
    final step = TutorialStep(
      id: 'missing_anchor',
      pageId: 'test',
      anchorKey: GlobalKey(),
      title: 'Fallback Title',
      description: 'Fallback description goes here.',
      placement: TutorialPlacement.auto,
      highlightShape: TutorialHighlightShape.roundedRect,
      fallback: const TutorialFallback(
        alignment: Alignment.topLeft,
      ),
    );

    final events = <TutorialEventType>[];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox.expand()),
      ),
    );

    final context = tester.element(find.byType(Scaffold));

    // Trigger the overlay.
    // ignore: unawaited_futures
    TutorialOverlay.instance.showStep(
      context: context,
      step: step,
      emit: (type, emittedStep, {flowId, payload}) {
        events.add(type);
      },
    );

    await tester.pumpAndSettle();

    expect(find.text('Fallback Title'), findsOneWidget);
    expect(find.text('Fallback description goes here.'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(events.first, equals(TutorialEventType.stepShown));
    expect(events.last, equals(TutorialEventType.tutorialCompleted));
  });
}

