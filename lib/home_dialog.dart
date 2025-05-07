import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';

class HomePageWithDialog extends StatefulWidget {
  const HomePageWithDialog({super.key});

  @override
  State<HomePageWithDialog> createState() => _HomePageWithDialogState();
}

class _HomePageWithDialogState extends State<HomePageWithDialog> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(
            child: ScaleTransition(
              scale: _scaleController,
              child: Dialog(
                backgroundColor: const Color(0xFFF8F6F4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/lottie/celebration.json',
                        height: 150,
                        repeat: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Great Job!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'You’ve completed today’s exercise session. 🎯 Keep it up!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5B5B5B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF800020),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Thanks!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF8F6F4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage(); // Replace with your actual HomePage
  }
}