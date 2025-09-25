// Import packages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// For firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Import pages
import 'data/rehabilitation_plan.dart';
import 'data/globals.dart';
import 'data/data_persistence_service.dart';
import 'data/auth_persistence_service.dart';
import 'data/data_sync_service.dart';
import 'data/fast_loading_service.dart';
import 'data/asset_loading_service.dart';
import 'data/theme_controller.dart';
import 'welcome/login_page.dart';
import 'dashboard/dashboard_page.dart';
import 'assessment/preliminary.dart';
import 'exercise/edit_plan.dart';
import 'record/pre_record_page.dart';
// import 'progress_report.dart';
import 'profile/profile_page.dart';
import 'reports/report_page.dart';
import 'test_persistence_page.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'data/hive_models.dart';
// Main Function: To run the app
void main() async {
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: \\n${details.exceptionAsString()}');
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
      } catch (_) {}
    }

    // Initialize Firebase and Hive in parallel
    try {
      if (kIsWeb) {
        // On web, only initialize Firebase
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } else {
        // On mobile/desktop, initialize both Firebase and Hive
        await Future.wait([
          Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
          Hive.initFlutter(),
        ]);
      }
    } catch (e) {
      debugPrint('Main: Initialization failure (Firebase/Hive): $e');
    }
    
    // Register all Hive adapters (ignore if already registered) - skip on web
    if (!kIsWeb) {
      try {
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
      } catch (e) {
        debugPrint('Main: Hive adapter registration issue: $e');
      }
      
      // Open Hive box
      try {
        await Hive.openBox('rehabBox');
      } catch (e) {
        debugPrint('Main: Failed opening Hive box: $e');
      }
    }
    
    // Initialize services in parallel - skip Hive-dependent services on web
    try {
      if (kIsWeb) {
        // On web, only initialize Firebase-dependent services
        await Future.wait([
          DataSyncService.instance.initialize(),
          AuthPersistenceService.instance.initialize(),
        ]);
      } else {
        // On mobile/desktop, initialize all services
        await Future.wait([
          DataSyncService.instance.initialize(),
          AuthPersistenceService.instance.initialize(),
          FastLoadingService.instance.initialize(),
          AssetLoadingService.instance.initialize(),
        ]);
      }
    } catch (e) {
      debugPrint('Main: Service initialization problem: $e');
    }

    // Load saved theme - skip on web
    if (!kIsWeb) {
      try {
        await ThemeController.instance.loadFromHive();
      } catch (e) {
        debugPrint('Main: Theme load failed: $e');
      }
      
      // Load authentication state from Hive
      try {
        await AuthPersistenceService.instance.loadAuthStateFromHive();
      } catch (e) {
        debugPrint('Main: Auth state load failed: $e');
      }
      
      // Initialize the data persistence service
      try {
        DataPersistenceService.instance.initialize();
      } catch (e) {
        debugPrint('Main: DataPersistence init failed: $e');
      }
    }
    
    // Start the app immediately - critical data is already loading
    runApp(const ProviderScope(child: MyApp()));
    
    // Load background data and sync in background (non-blocking)
    _loadBackgroundDataAndSync();
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error');
  });
}

// Load background data and sync in background
void _loadBackgroundDataAndSync() async {
  try {
    if (kIsWeb) {
      // On web, only sync Firebase data if authenticated
      if (AuthPersistenceService.instance.isAuthenticated) {
        debugPrint('Main: User is authenticated, syncing data from Firebase in background...');
        AuthPersistenceService.instance.syncAllData().catchError((e) {
          debugPrint('Main: Background sync failed: $e');
        });
      } else {
        debugPrint('Main: User not authenticated, using Firebase data only');
      }
    } else {
      // On mobile/desktop, use full data loading
      // Wait for critical data to be loaded
      await FastLoadingService.instance.waitForCriticalData();
      
      // Load background data
      await FastLoadingService.instance.loadBackgroundData();
      
      // Sync data if user is authenticated
      if (AuthPersistenceService.instance.isAuthenticated) {
        debugPrint('Main: User is authenticated, syncing data from Firebase in background...');
        AuthPersistenceService.instance.syncAllData().catchError((e) {
          debugPrint('Main: Background sync failed: $e');
        });
      } else {
        debugPrint('Main: User not authenticated, using local data only');
      }
    }
  } catch (e) {
    debugPrint('Main: Error in background loading: $e');
  }
}

// Function to save all data to Hive
Future<void> saveAllDataToHive() async {
  if (kIsWeb) {
    debugPrint('Skipping Hive save on web platform');
    return;
  }
  
  try {
    debugPrint('Saving all data to Hive...');
    
    // Save rehabilitation plans and treatments
    await UserRehabilitation.instance.savePlansToHive();
    
    // Save pain history
    await PainHistory.saveToHive();
    
    // Save exercise history
    await ExerciseHistory.saveToHive();
    
    // Save user data
    await UserDetails.saveToHive();
    await UserProgress.saveToHive();
    await UserAssess.saveToHive();
    await UserSettings.saveToHive();
    await ActiveProgram.saveToHive();
    
    debugPrint('Successfully saved all data to Hive');
    
  } catch (e) {
    debugPrint('Error saving data to Hive: $e');
  }
}

// Professional Healthcare Color Theme
const Color kBackgroundColor = Color(0xFFF8FAFC); // Light background
const Color kMainColor = Color(0xFF8B2E2E); // Muscular maroon
const Color kSubColor = Color(0xFFC24A4A); // Lighter maroon
const Color kDetailColor = Color(0xFF6B7280); // Gray
const Color kTextHeading = Color(0xFF1F2937); // Dark gray
const Color kTextNormal = Color(0xFF4B5563); // Medium gray
const Color kSuccessColor = Color(0xFF10B981); // Green
const Color kWarningColor = Color(0xFFF59E0B); // Orange
const Color kErrorColor = Color(0xFFEF4444); // Red

// Stateless Widget: Main (Entry Point of the App)
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Save data when app goes to background or is terminated
        _saveDataOnAppPause();
        break;
      case AppLifecycleState.resumed:
        // Optionally reload data when app comes back to foreground
        _reloadDataOnAppResume();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning between states
        break;
    }
  }

  Future<void> _saveDataOnAppPause() async {
    try {
      debugPrint('App lifecycle: Saving data due to app pause/termination');
      
      if (!kIsWeb) {
        // Save all data to Hive (mobile/desktop only)
        await DataPersistenceService.instance.forceSave(reason: 'App pause/termination');
        
        // Save authentication state to Hive
        await AuthPersistenceService.instance.saveAuthStateToHive();
      }
      
      // Force save to Firebase if authenticated (works on all platforms)
      if (AuthPersistenceService.instance.isAuthenticated) {
        debugPrint('App lifecycle: Force saving to Firebase...');
        final saveResults = await DataSyncService.instance.forceSaveToFirebase();
        if (saveResults['success'] == true) {
          debugPrint('App lifecycle: Data successfully saved to Firebase');
        } else {
          debugPrint('App lifecycle: Failed to save to Firebase: ${saveResults['error']}');
        }
      }
      
    } catch (e) {
      debugPrint('Error saving data on app pause: $e');
    }
  }

  Future<void> _reloadDataOnAppResume() async {
    try {
      debugPrint('App lifecycle: Reloading data on app resume');
      
      // Check authentication status
      await AuthPersistenceService.instance.forceAuthCheck();
      
      if (!kIsWeb) {
        // Load data from Hive (mobile/desktop only)
        await DataPersistenceService.loadAllDataFromHive();
      }
      
      // Sync data if authenticated
      if (AuthPersistenceService.instance.isAuthenticated) {
        debugPrint('App lifecycle: User is authenticated, syncing data from Firebase...');
        await AuthPersistenceService.instance.syncAllData();
      } else {
        debugPrint('App lifecycle: User not authenticated, using ${kIsWeb ? 'Firebase' : 'local'} data only');
      }
      
    } catch (e) {
      debugPrint('Error reloading data on app resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackgroundColor,
        primaryColor: kMainColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: kMainColor,
          secondary: kSubColor,
          surface: kBackgroundColor,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: kMainColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textTheme: TextTheme(
          // Headings: Poppins
          displayLarge: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w700, // Bold
          ),
          displayMedium: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w600, // Semi-Bold
          ),
          headlineLarge: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w500, // Medium
          ),
          titleLarge: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w500,
          ),
          titleSmall: GoogleFonts.poppins(
            color: kTextHeading,
            fontWeight: FontWeight.w500,
          ),
          
          // Body: PT Sans
          bodyLarge: GoogleFonts.ptSans(color: kTextNormal),
          bodyMedium: GoogleFonts.ptSans(color: kTextNormal),
          bodySmall: GoogleFonts.ptSans(color: kTextNormal),
          labelLarge: GoogleFonts.ptSans(color: kTextNormal),
          labelMedium: GoogleFonts.ptSans(color: kTextNormal),
          labelSmall: GoogleFonts.ptSans(color: kTextNormal),
        ),
        iconTheme: const IconThemeData(color: kSubColor),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1012),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: kMainColor,
          secondary: kSubColor,
          surface: const Color(0xFF111315),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF111315),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(color: Colors.white),
          displayMedium: GoogleFonts.poppins(color: Colors.white),
          displaySmall: GoogleFonts.poppins(color: Colors.white),
          headlineLarge: GoogleFonts.poppins(color: Colors.white),
          headlineMedium: GoogleFonts.poppins(color: Colors.white),
          headlineSmall: GoogleFonts.poppins(color: Colors.white),
          titleLarge: GoogleFonts.poppins(color: Colors.white),
          titleMedium: GoogleFonts.poppins(color: Colors.white),
          titleSmall: GoogleFonts.poppins(color: Colors.white),
          bodyLarge: GoogleFonts.ptSans(color: Colors.white70),
          bodyMedium: GoogleFonts.ptSans(color: Colors.white70),
          bodySmall: GoogleFonts.ptSans(color: Colors.white70),
          labelLarge: GoogleFonts.ptSans(color: Colors.white70),
          labelMedium: GoogleFonts.ptSans(color: Colors.white70),
          labelSmall: GoogleFonts.ptSans(color: Colors.white70),
        ),
        iconTheme: const IconThemeData(color: kSubColor),
      ),
      themeMode: mode,

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScaffold(
              title: 'Loading PocketPT',
              subtitle: 'Please wait while we prepare your personalized experience',
            );
          }
          if (snapshot.hasData) {
            return const AuthWrapper();
          }
          return const LoginPage();
        },
      ),

        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LoadingScaffold({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Theme.of(context).colorScheme.surface : Colors.white;
    final titleColor = isDark ? Colors.white : kTextHeading;
    final bodyColor = isDark ? Colors.white70 : kTextNormal;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : kBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: bodyColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AuthWrapper to check assessment completion
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAssessmentStatus();
  }

  Future<void> _checkAssessmentStatus() async {
    try {
      if (kIsWeb) {
        // On web, skip FastLoadingService and use Firebase data directly
        debugPrint('AuthWrapper: Using Firebase data for assessment check on web');
      } else {
        // Wait for critical data to be loaded by FastLoadingService
        await FastLoadingService.instance.waitForCriticalData();
        
        // Check assessment status from local data (already loaded by FastLoadingService)
        debugPrint('AuthWrapper: Using cached user data for assessment check');
      }
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking assessment status: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingScaffold(
        title: 'Initializing Assessment',
        subtitle: 'Preparing your personalized rehabilitation plan',
      );
    }

    // If user hasn't completed assessment, show assessment
    if (!UserDetails.hasCompletedAssessment) {
      return const AssessPrelim();
    }

    // If user has completed assessment, show home page
    return const HomePage();
  }
}

// Stateful Widget: HomePage (Main Scaffold)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int count = 0;

  @override
  void initState() {
    super.initState();
  }

  // List: Pages (for Navigation)
  final List<Widget> _pages = const [
    DashboardPage(),
    ExerciseManagerPage(),
    PreRecordPage(),
    ReportPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFF800020),
      //   title: Image.asset(
      //     'assets/images/logo.png', // Ensure this path is correct for assets
      //     height: 60,
      //     fit: BoxFit.contain,
      //   ),
      //   centerTitle: true,
      //   iconTheme: const IconThemeData(
      //     color: Colors.white,
      //   ),
      // ),

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kMainColor, kSubColor],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'PocketPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Professional Rehabilitation',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Welcome to your personalized rehabilitation platform',
                style: TextStyle(
                  fontSize: 16,
                  color: kTextNormal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      floatingActionButton: kDebugMode ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: kMainColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TestPersistencePage(),
              ),
            );
          },
          backgroundColor: kMainColor,
          child: const Icon(Icons.bug_report, color: Colors.white),
          tooltip: 'Test Persistence',
        ),
      ) : null,

      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const PoseDetectionDemo(),
      //       ),
      //     );
      //   },
      //   backgroundColor: const Color(0xFF800020),
      //   icon: const Icon(Icons.camera_alt, color: Colors.white),
      //   label: Text(
      //     'Pose Demo',
      //     style: GoogleFonts.poppins(
      //       color: Colors.white,
      //       fontWeight: FontWeight.w600,
      //     ),
      //   ),
      // ),

      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => const PoseDetectionDemo(),
      //       ),
      //     );
      //   },
      //   backgroundColor: const Color(0xFF800020),
      //   icon: const Icon(Icons.camera_alt, color: Colors.white),
      //   label: Text(
      //     'Pose Demo',
      //     style: GoogleFonts.poppins(
      //       color: Colors.white,
      //       fontWeight: FontWeight.w600,
      //     ),
      //   ),
      // ),

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     setState(() {
      //       count++;
      //     });
      //   },
      //   child: const Icon(Icons.add),
      // ),

      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        onTap: (int index) {
          if (index == 2) {  // If it's the PreRecordPage index (index 2)
            // Use pushReplacement to completely navigate to PreRecordPage
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const PreRecordPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // SlideTransition
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          } else {
            setState(() {
              _currentIndex = index; 
            });
          }
        },
        backgroundColor: Colors.white,
        color: kMainColor,
        buttonBackgroundColor: kMainColor,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: [
          // Dashboard
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.dashboard, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  "Home", 
                  style: GoogleFonts.ptSans(
                    color: Colors.white, 
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Exercise
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  "Exercise", 
                  style: GoogleFonts.ptSans(
                    color: Colors.white, 
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Record (Center Button)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.radio_button_checked, color: Colors.white, size: 32),
                const SizedBox(height: 4),
                Text(
                  "Record", 
                  style: GoogleFonts.ptSans(
                    color: Colors.white, 
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Reports
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  "Report", 
                  style: GoogleFonts.ptSans(
                    color: Colors.white, 
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Profile
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  "Profile", 
                  style: GoogleFonts.ptSans(
                    color: Colors.white, 
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}