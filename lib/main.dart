// Import packages
import 'package:PocketPT/exercise/edit_plan.dart';
import 'package:PocketPT/reports/report_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// For firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Import pages
// import 'data/globals.dart';
import 'welcome/login_page.dart';
import 'dashboard/dashboard_page.dart';
import 'exercise/exercises_page.dart';
import 'record/pre_record_page.dart';
// import 'progress_report.dart';
import 'profile/profile_page.dart';
// import 'reports/report_page.dart';

// Main Function: To run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp()));
}

// Color Theme
const Color kBackgroundColor = Color(0xFFF8F6F4);
const Color kMainColor = Color(0xFF8B2E2E);
const Color kSubColor = Color(0xFFC1574F);
const Color kDetailColor = Color(0xFF557A95);
const Color kTextHeading = Color(0xFF2E2E2E);
const Color kTextNormal = Color(0xFF5B5B5B);

// Stateless Widget: Main (Entry Point of the App)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // or splash screen
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return const LoginPage();
        },
      ),

    );
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

      drawer: const Drawer(
        child: Center(child: Text('Hello, User!')),
      ),

      body: _pages[_currentIndex],

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
        color: const Color(0xFF800020),
        buttonBackgroundColor: const Color(0xFF800020),
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          // Dashboard
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard, color: Colors.white),
                Text("Home", style: TextStyle(color: Colors.white, fontSize: 8)),
              ],
            ),
          ),

          // Exercise
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, color: Colors.white),
                Text("Exercise", style: TextStyle(color: Colors.white, fontSize: 8)),
              ],
            ),
          ),

          // Record (Center Button)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radio_button_checked, color: Colors.white, size: 35),
                Text("Record", style: TextStyle(color: Colors.white, fontSize: 8)),
              ],
            ),
          ),

          // reports
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, color: Colors.white),
                Text("Report", style: TextStyle(color: Colors.white, fontSize: 8)),
              ],
            ),
          ),

          // Profile
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, color: Colors.white),
                Text("Profile", style: TextStyle(color: Colors.white, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}