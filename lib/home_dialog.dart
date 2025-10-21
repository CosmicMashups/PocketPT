import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'widgets/responsive_dialog.dart';

class HomePageWithDialog extends StatefulWidget {
  const HomePageWithDialog({super.key});

  @override
  State<HomePageWithDialog> createState() => _HomePageWithDialogState();
}

class _HomePageWithDialogState extends State<HomePageWithDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

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
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return ScaleTransition(
            scale: _scaleController,
            child: ResponsiveDialog(
              title: 'Session Complete!',
              icon: Icons.check_circle,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kMainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: kMainColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'You\'ve successfully completed today\'s exercise session. Great work on staying consistent with your rehabilitation!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white70 
                          : kTextNormal,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kMainColor, kSubColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kMainColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Return to Dashboard',
                          style: GoogleFonts.ptSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    return const HomePage();
  }
}