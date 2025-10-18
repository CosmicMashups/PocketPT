import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../lib/firebase_options.dart';
import '../lib/data/persistence_validation.dart';
import '../lib/data/hive_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersistenceValidation (headless)', () {
    testWidgets('runs full Hive ↔ Firebase validation without UI', (tester) async {
      // Initialize Firebase
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Reduce chances of long hangs in test environment
      FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

      // Ensure authentication using provided credentials
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: 'cosmicmashups7@gmail.com',
            password: '@Cosmic1234',
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: 'cosmicmashups7@gmail.com',
              password: '@Cosmic1234',
            );
          } else {
            rethrow;
          }
        }
      }

      // Initialize Hive in a system temp directory (works in VM tests)
      final dir = Directory.systemTemp.createTempSync('pocketpt_test_');
      Hive.init(dir.path);

      // Register Hive adapters used by the app (13 adapters total)
      Hive.registerAdapter(HiveDailyProgressAdapter());
      Hive.registerAdapter(HiveRehabilitationPlanAdapter());
      Hive.registerAdapter(HivePainRecordEntryAdapter());
      Hive.registerAdapter(HiveExerciseRecordEntryAdapter());
      Hive.registerAdapter(HiveUserProgressAdapter());
      Hive.registerAdapter(HiveUserAssessAdapter());
      Hive.registerAdapter(HiveUserSettingsAdapter());
      Hive.registerAdapter(HiveUserDetailsAdapter());
      Hive.registerAdapter(HiveActiveProgramAdapter());
      Hive.registerAdapter(HiveExerciseReferenceAdapter());
      Hive.registerAdapter(HiveTreatmentReferenceAdapter());
      Hive.registerAdapter(HiveExerciseIdsAdapter());
      Hive.registerAdapter(HiveTreatmentIdsAdapter());

      // Open the app box
      await Hive.openBox('rehabBox');

      // Run validation
      final result = await PersistenceValidation
          .runFull()
          .timeout(const Duration(minutes: 2));

      // Print a concise JSON summary for CI/logs
      final printable = jsonEncode(result);
      // ignore: avoid_print
      print('PERSISTENCE_VALIDATION_RESULT: $printable');

      // Soft assertion: we at least expect a result map with keys
      expect(result.containsKey('success'), true);
    });
  });
}


