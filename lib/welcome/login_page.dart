// Import packages
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

// Import pages
import '../main.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _handleGoogleSignIn() {
    // TODO: Implement Google Sign-In (e.g., using firebase_auth and google_sign_in)
    print("Google Sign-In button pressed");
  }

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
            height: screenHeight * 0.3 + 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    'assets/images/welcome_1.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 250,
                    height: 250,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Section
          Positioned(
            top: screenHeight * 0.3,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Text("Let's pick up where you left off.",
                        style: GoogleFonts.ptSans(fontSize: 16, color: Colors.black.withOpacity(0.7))),
                    const SizedBox(height: 4),
                    Text("Stay smart, stay strong.",
                        style: GoogleFonts.ptSans(fontSize: 16, color: Colors.black.withOpacity(0.7))),
                    const SizedBox(height: 24),

                    // Email Field
                    ReusableInputField(label: 'E-mail Address', icon: Icons.email),
                    const SizedBox(height: 16),

                    // Password Field
                    ReusableInputField(label: 'Password', isPassword: true, icon: Icons.lock),
                    const SizedBox(height: 24),

                    // Login Button
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.85,
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
                            padding: EdgeInsets.symmetric(horizontal: 75, vertical: 14),
                          ),
                          child: Text("Login",
                              style: GoogleFonts.ptSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // OR divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[400])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text("OR", style: GoogleFonts.ptSans(color: Colors.grey[600])),
                        ),
                        Expanded(child: Divider(color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Login Button
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.85,
                        child: OutlinedButton.icon(
                          icon: Image.asset('assets/images/logo/google.png', height: 16),
                          label: Text(
                            'Sign in with Google',
                            style: GoogleFonts.ptSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF5B5B5B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            minimumSize: const Size(0, 48),
                          ),
                        ),
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
}

class ReusableInputField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final IconData? icon;

  const ReusableInputField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.icon,
  });

  @override
  State<ReusableInputField> createState() => _ReusableInputFieldState();
}

class _ReusableInputFieldState extends State<ReusableInputField> {
  late bool isObscured;

  @override
  void initState() {
    super.initState();
    isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 60,
        child: TextField(
          obscureText: widget.isPassword ? isObscured : false,
          decoration: InputDecoration(
            prefixIcon: widget.icon != null ? Icon(widget.icon, color: Colors.black45) : null,
            labelText: widget.label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF8B2E2E), width: 2),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black45,
                    ),
                    onPressed: () {
                      setState(() {
                        isObscured = !isObscured;
                      });
                    },
                  )
                : null,
          ),
          style: GoogleFonts.ptSans(),
        ),
      ),
    );
  }
}
