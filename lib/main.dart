// Import packages
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
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
// Removed fast/background preloaders to support lazy-loading
import 'data/auto_save_service.dart';
import 'data/asset_loading_service.dart';
import 'data/theme_controller.dart';
import 'data/navigation_service.dart';
import 'data/user_data_notifier.dart';
import 'data/local_notifications_service.dart';
import 'data/guest_mode_service.dart';
import 'welcome/login_page.dart';
import 'dashboard/dashboard_page.dart';
import 'assessment/preliminary.dart';
import 'exercise/edit_plan.dart';
import 'record/pre_record_page.dart';
import 'profile/profile_page.dart';
import 'reports/report_page.dart';
import 'test_persistence_page.dart';
import 'widgets/responsive_loading_screen.dart';
import 'core/animations.dart';

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
      debugPrint('Main: Starting Firebase and Hive initialization...');
      if (kIsWeb) {
        // On web, only initialize Firebase
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        debugPrint('Main: Firebase initialized successfully on web');
      } else {
        // On mobile/desktop, initialize both Firebase and Hive
        await Future.wait([
          Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
          Hive.initFlutter(),
        ]);
        debugPrint('Main: Firebase and Hive initialized successfully');
      }
    } catch (e) {
      debugPrint('Main: Initialization failure (Firebase/Hive): $e');
      // Continue anyway to prevent app from crashing
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
    
    // Initialize core services only (defer heavy data loading until Dashboard)
    try {
      debugPrint('Main: Starting service initialization...');
      if (kIsWeb) {
        // On web, only initialize Firebase-dependent services
        await Future.wait([
          DataSyncService.instance.initialize(),
          AuthPersistenceService.instance.initialize(),
        ]);
        debugPrint('Main: Web services initialized successfully');
      } else {
        // On mobile/desktop, initialize only lightweight services
        await Future.wait([
          DataSyncService.instance.initialize(),
          AuthPersistenceService.instance.initialize(),
          AssetLoadingService.instance.initialize(),
        ]);
        // Initialize local notifications (after Hive so we can use its box)
        await LocalNotificationsService.instance.initialize();
        debugPrint('Main: All services initialized successfully');
      }
    } catch (e) {
      debugPrint('Main: Service initialization problem: $e');
      // Continue anyway to prevent app from crashing
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
      
      // Initialize the auto-save service
      try {
        AutoSaveService.instance.initialize();
      } catch (e) {
        debugPrint('Main: AutoSaveService init failed: $e');
      }
    }
    
    // Start the app immediately - defer user data loading until Dashboard
    runApp(const ProviderScope(child: MyApp()));
    // Background preloading removed to honor lazy-loading architecture
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error');
  });
}

// Background preloading removed per lazy-loading design

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
    // Tune global image cache for low-end devices
    try {
      PaintingBinding.instance.imageCache.maximumSize = 200; // max number of images
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // ~50MB
    } catch (_) {}

    // Lightweight frame timing monitor for profiling jank during thesis measurements
    try {
      const int budgetMs = 16; // 60 FPS frame budget
      SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
        for (final t in timings) {
          final totalMs = t.totalSpan.inMilliseconds;
          if (totalMs > budgetMs * 2) { // flag frames > 32ms
            debugPrint('Perf: Slow frame ${totalMs}ms (build:${t.buildDuration.inMilliseconds}ms, raster:${t.rasterDuration.inMilliseconds}ms)');
          }
        }
      });
    } catch (_) {}
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
        // Save user details to Hive first (most critical)
        await UserDetails.saveToHive();
        debugPrint('App lifecycle: User details saved to Hive');
        
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
      
      // Defer full data loading to Dashboard; no-op here to preserve lazy-loading
      
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
            scrollBehavior: const AppScrollBehavior(),
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

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // Remove default glow to avoid extra layer work
    return child;
  }
}

class _LoadingScaffold extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LoadingScaffold({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLoadingScreen(
      title: title,
      subtitle: subtitle,
      showLogo: true,
      showProgress: false,
    );
  }
}

class _FallbackScaffold extends StatelessWidget {
  const _FallbackScaffold();

  @override
  Widget build(BuildContext context) {
    return ResponsiveLoadingScreen(
      title: 'Welcome to PocketPT',
      subtitle: 'Initializing your rehabilitation experience...',
      showLogo: true,
      showProgress: false,
      isError: false,
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
      debugPrint('AuthWrapper: Starting assessment status check...');
      
      // Set a timeout to prevent infinite loading
      await Future.any([
        _loadAssessmentData(),
        Future.delayed(const Duration(seconds: 10)),
      ]);
      
      debugPrint('AuthWrapper: Assessment status check completed');
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AuthWrapper: Error checking assessment status: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadAssessmentData() async {
    try {
      // Check if we're in guest mode first
      if (UserDetails.isGuest) {
        debugPrint('AuthWrapper: Guest mode detected, initializing guest data');
        await GuestModeService.instance.initialize();
        await GuestModeService.instance.loadData();
        
        // Initialize the user data notifier with current data
        UserDataNotifier.instance.initialize();
        
        // Force a refresh of the notifier to ensure UI updates
        UserDataNotifier.instance.refresh();
        return;
      }

      // Minimal assessment-only loading; avoid full user data until Dashboard
      await UserAssess.loadFromHive();
      
      // Initialize the user data notifier with current data
      UserDataNotifier.instance.initialize();
      
      // If user data is still empty, try to load it manually
      if (UserDataNotifier.instance.isEmpty) {
        debugPrint('AuthWrapper: User data is empty, attempting to load manually');
        try {
          await UserDetails.loadFromHive();
          UserDataNotifier.instance.refresh();
          
          // If still empty, try Firebase
          if (UserDataNotifier.instance.isEmpty) {
            await UserDetails.loadFromFirebase();
            UserDataNotifier.instance.refresh();
          }
        } catch (e) {
          debugPrint('AuthWrapper: Error loading user data manually: $e');
        }
      }
      
      // Ensure we have some basic data even if loading failed
      if (UserDataNotifier.instance.isEmpty) {
        debugPrint('AuthWrapper: Still no user data, using defaults');
        UserDataNotifier.instance.updateUserData(
          firstName: 'User',
          lastName: '',
          email: 'user@example.com',
          hasCompletedAssessment: false,
        );
      }
      
    } catch (e) {
      debugPrint('AuthWrapper: Error in _loadAssessmentData: $e');
      // Set default values to prevent blank screen
      UserDataNotifier.instance.updateUserData(
        firstName: 'User',
        lastName: '',
        email: 'user@example.com',
        hasCompletedAssessment: false,
      );
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

    // Ensure we have some basic data to prevent blank screen
    if (UserDataNotifier.instance.isEmpty) {
      debugPrint('AuthWrapper: No user data available, using fallback');
      return const _FallbackScaffold();
    }

      // If user hasn't completed assessment, show assessment (including guests)
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

  @override
  void initState() {
    super.initState();
  }

  // List: Pages (for Navigation) - const for better performance
  static const List<Widget> _pages = [
    DashboardPage(),
    EditPlanPage(),
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
        child: SafeArea(
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
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to your personalized rehabilitation platform',
                        style: GoogleFonts.ptSans(
                          fontSize: 16,
                          color: kTextNormal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Add navigation items here if needed
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      floatingActionButton: kDebugMode ? _buildDebugFab(context) : null,


      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        onTap: (int index) {
          // If leaving Dashboard (index 0), unload full dataset
          if (_currentIndex == 0 && index != 0) {
            DataPersistenceService.instance.unloadUserData();
          }
          if (index == 2) {  // If it's the PreRecordPage index (index 2)
            // Use pushReplacement to completely navigate to PreRecordPage
            Navigator.push(
              context,
              MedicalPageRoute(
                child: const PreRecordPage(),
                settings: const RouteSettings(name: '/pre-record'),
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
        items: _buildNavigationItems(),
      ),
    );
  }

  /// Builds the debug floating action button for testing
  Widget _buildDebugFab(BuildContext context) {
    return Container(
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
            MedicalPageRoute(
              child: const TestPersistencePage(),
              settings: const RouteSettings(name: '/test-persistence'),
            ),
          );
        },
        backgroundColor: kMainColor,
        child: const Icon(Icons.bug_report, color: Colors.white),
        tooltip: 'Test Persistence',
      ),
    );
  }

  /// Builds navigation items for the curved navigation bar
  List<Widget> _buildNavigationItems() {
    return [
      _buildNavItem(Icons.dashboard, "Home", 24, FontWeight.w500),
      _buildNavItem(Icons.fitness_center, "Exercise", 24, FontWeight.w500),
      _buildNavItem(Icons.radio_button_checked, "Record", 32, FontWeight.w600),
      _buildNavItem(Icons.analytics, "Report", 24, FontWeight.w500),
      _buildNavItem(Icons.person, "Profile", 24, FontWeight.w500),
    ];
  }

  /// Builds individual navigation item widget
  Widget _buildNavItem(IconData icon, String label, double iconSize, FontWeight fontWeight) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: iconSize),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.ptSans(
              color: Colors.white,
              fontSize: 10,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}