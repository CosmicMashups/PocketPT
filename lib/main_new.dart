import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Core imports
import 'core/app_initializer.dart';
import 'core/error_handler.dart';
import 'core/providers/app_providers.dart';

// UI imports
import 'welcome/login_page.dart';
import 'dashboard/dashboard_page.dart';

void main() async {
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('FlutterError: ${details.exceptionAsString()}');
    }
  };

  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Keep app in portrait by default (safer UX for health app) - skip on web
    if (!kIsWeb) {
      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to set orientation: $e');
        }
      }
    }

    // Initialize Firebase
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
      }
      // Continue anyway to prevent app from crashing
    }

    // Initialize core application components
    try {
      final initResult = await appInitializer.initialize();
      if (initResult.isError) {
        if (kDebugMode) {
          print('App initialization failed: ${initResult.errorMessage}');
        }
        // Continue anyway to prevent app from crashing
      } else {
        if (kDebugMode) {
          print('App initialization completed successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('App initialization error: $e');
      }
      // Continue anyway to prevent app from crashing
    }

    // Run the app
    runApp(const ProviderScope(child: PocketPTApp()));
  }, (error, stack) {
    if (kDebugMode) {
      print('Zone error: $error');
      print('Stack trace: $stack');
    }
    errorHandler.handleError('main', error, stack);
  });
}

class PocketPTApp extends ConsumerWidget {
  const PocketPTApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PocketPT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const AppRouter(),
    );
  }
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return switch (authState) {
      AuthState(isLoading: true) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      AuthState(isLoggedIn: true) => const DashboardPage(),
      AuthState(isLoggedIn: false) => const LoginPage(),
    };
  }
}

