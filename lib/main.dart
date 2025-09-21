// Import packages
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
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and Hive in parallel
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Hive.initFlutter(),
  ]);
  
  // Register all Hive adapters
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
  
  // Open Hive box
  await Hive.openBox('rehabBox');
  
  // Initialize services in parallel
  await Future.wait([
    DataSyncService.instance.initialize(),
    AuthPersistenceService.instance.initialize(),
    FastLoadingService.instance.initialize(),
    AssetLoadingService.instance.initialize(),
  ]);

  // Load saved theme
  await ThemeController.instance.loadFromHive();
  
  // Load authentication state from Hive
  await AuthPersistenceService.instance.loadAuthStateFromHive();
  
  // Initialize the data persistence service
  DataPersistenceService.instance.initialize();
  
  // Start the app immediately - critical data is already loading
  runApp(ProviderScope(child: MyApp()));
  
  // Load background data and sync in background (non-blocking)
  _loadBackgroundDataAndSync();
}

// Load background data and sync in background
void _loadBackgroundDataAndSync() async {
  try {
    // Wait for critical data to be loaded
    await FastLoadingService.instance.waitForCriticalData();
    
    // Load background data
    await FastLoadingService.instance.loadBackgroundData();
    
    // Sync data if user is authenticated
    if (AuthPersistenceService.instance.isAuthenticated) {
      print('Main: User is authenticated, syncing data from Firebase in background...');
      AuthPersistenceService.instance.syncAllData().catchError((e) {
        print('Main: Background sync failed: $e');
      });
    } else {
      print('Main: User not authenticated, using local data only');
    }
  } catch (e) {
    print('Main: Error in background loading: $e');
  }
}

// Function to save all data to Hive
Future<void> saveAllDataToHive() async {
  try {
    print('Saving all data to Hive...');
    
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
    
    print('Successfully saved all data to Hive');
    
  } catch (e) {
    print('Error saving data to Hive: $e');
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
      print('App lifecycle: Saving data due to app pause/termination');
      
      // Save all data
      await DataPersistenceService.instance.forceSave(reason: 'App pause/termination');
      
      // Save authentication state
      await AuthPersistenceService.instance.saveAuthStateToHive();
      
      // Force save to Firebase if authenticated
      if (AuthPersistenceService.instance.isAuthenticated) {
        print('App lifecycle: Force saving to Firebase...');
        final saveResults = await DataSyncService.instance.forceSaveToFirebase();
        if (saveResults['success'] == true) {
          print('App lifecycle: Data successfully saved to Firebase');
        } else {
          print('App lifecycle: Failed to save to Firebase: ${saveResults['error']}');
        }
      }
      
    } catch (e) {
      print('Error saving data on app pause: $e');
    }
  }

  Future<void> _reloadDataOnAppResume() async {
    try {
      print('App lifecycle: Reloading data on app resume');
      
      // Check authentication status
      await AuthPersistenceService.instance.forceAuthCheck();
      
      // Load data from Hive
      await DataPersistenceService.loadAllDataFromHive();
      
      // Sync data if authenticated
      if (AuthPersistenceService.instance.isAuthenticated) {
        print('App lifecycle: User is authenticated, syncing data from Firebase...');
        await AuthPersistenceService.instance.syncAllData();
      } else {
        print('App lifecycle: User not authenticated, using local data only');
      }
      
    } catch (e) {
      print('Error reloading data on app resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
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
            return Scaffold(
              backgroundColor: kBackgroundColor,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Loading PocketPT',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: kTextHeading,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while we prepare your personalized experience',
                            style: GoogleFonts.ptSans(
                              fontSize: 14,
                              color: kTextNormal,
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
      // Wait for critical data to be loaded by FastLoadingService
      await FastLoadingService.instance.waitForCriticalData();
      
      // Check assessment status from local data (already loaded by FastLoadingService)
      print('AuthWrapper: Using cached user data for assessment check');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking assessment status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
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
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  'Initializing Assessment',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kTextHeading,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preparing your personalized rehabilitation plan',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: kTextNormal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
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

      body: _pages[_currentIndex],

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
                pageBuilder: (context, animation, secondaryAnimation) => PreRecordPage(),
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