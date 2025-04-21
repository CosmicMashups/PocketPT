// Import packages
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

// Import pages
import '../main.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.4 + 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    '../assets/images/welcome_1.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 80,
                  child: Image.asset(
                    '../assets/images/logo.png',
                    width: 300,
                    height: 300,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Section
          Positioned(
            top: screenHeight * 0.4,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text("Let's pick up where you left off.",
                        style: GoogleFonts.ptSans(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Stay smart, stay strong.",
                        style: GoogleFonts.ptSans(fontSize: 16)),
                    const SizedBox(height: 24),

                    // Email Field
                    _buildInputField(label: 'E-mail Address'),
                    const SizedBox(height: 16),

                    // Password Field
                    _buildInputField(label: 'Password', isPassword: true),
                    const SizedBox(height: 24),

                    // Login Button
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
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
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF800020),
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                        ),
                        child: Text("Login",
                            style: GoogleFonts.ptSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Text
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.ptSans(
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            color: const Color(0xFF5B5B5B),
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account yet, "),
                            TextSpan(
                              text: 'register',
                              style: GoogleFonts.ptSans(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                color: Color(0xFF800020),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => RegisterPage(),
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
                                ),
                            ),
                            const TextSpan(text: ' here.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, bool isPassword = false}) {
    return Center(
      child: SizedBox(
        height: 60,
        child: TextField(
          obscureText: isPassword,
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          ),
          style: GoogleFonts.ptSans(),
        ),
      ),
    );
  }
}
