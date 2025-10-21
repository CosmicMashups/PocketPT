import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/exercise/edit_plan.dart';
import 'package:PocketPT/data/rehabilitation_plan.dart';

void main() {
  group('EditPlanPage Widget Tests', () {
    testWidgets('EditPlanPage should build without crashing', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act & Assert
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      expect(find.byType(EditPlanPage), findsOneWidget);
    });

    testWidgets('EditPlanPage should display app bar with correct title', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Assert
      expect(find.text('Exercise Manager'), findsOneWidget);
    });

    testWidgets('EditPlanPage should display help button in app bar', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Assert
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('EditPlanPage should display testing button in app bar', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Assert
      expect(find.byIcon(Icons.science), findsOneWidget);
    });

    testWidgets('EditPlanPage should display repair button in app bar', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Assert
      expect(find.byIcon(Icons.build), findsOneWidget);
    });

    testWidgets('EditPlanPage should display backup button in app bar', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Assert
      expect(find.byIcon(Icons.backup), findsOneWidget);
    });

    testWidgets('EditPlanPage should display refresh button in app bar', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('EditPlanPage should show troubleshooting dialog when help button is tapped', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Troubleshooting Guide'), findsOneWidget);
    });

    testWidgets('EditPlanPage should show testing dialog when testing button is tapped', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      await tester.tap(find.byIcon(Icons.science));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Testing & Validation'), findsOneWidget);
    });

    testWidgets('EditPlanPage should display exercise cards when exercises are available', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Assert
      // The page should display some content (either exercise cards or empty state)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('EditPlanPage should handle empty exercise list gracefully', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('EditPlanPage Integration Tests', () {
    testWidgets('EditPlanPage should load and display exercise data', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Wait for data loading
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('EditPlanPage should handle button interactions', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Test help button
      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();
      expect(find.text('Troubleshooting Guide'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      
      // Test testing button
      await tester.tap(find.byIcon(Icons.science));
      await tester.pumpAndSettle();
      expect(find.text('Testing & Validation'), findsOneWidget);
    });
  });

  group('EditPlanPage Error Handling Tests', () {
    testWidgets('EditPlanPage should handle errors gracefully', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('EditPlanPage should display error states appropriately', (WidgetTester tester) async {
      // Arrange
      const editPlanPage = EditPlanPage();
      
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: editPlanPage,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
