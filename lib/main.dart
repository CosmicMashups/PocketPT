// Import packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import pages
import 'dashboard_page.dart';
import 'exercises_page.dart';
import 'profile_page.dart';

// Main Function: To run the app
void main() {
  runApp(const MyApp());
}

// Stateless Widget: Main (Entry Point of the App)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.ptSansTextTheme(),
      ),
      home: const HomePage(), // HomePage is now called here
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
    ExercisePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF800020),
        title: Image.asset(
          '../assets/images/logo.png', // Ensure this path is correct for assets
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      drawer: const Drawer(
        child: Center(child: Text('Hello, User!')),
      ),

      body: _pages[_currentIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            count++;
          });
        },
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Exercise',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face),
            label: 'Profile',
          ),
        ],
        selectedItemColor: const Color(0xFF800020),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}