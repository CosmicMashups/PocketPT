import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

// Import pages
import 'login_page.dart';
import '../assessment/preliminary.dart';
import '../data/functions.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _agreedToTerms = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage = '';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms and Privacy Policy'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step 1: Register user with Firebase Auth
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;

      if (uid == null) {
        throw FirebaseAuthException(
          code: 'unknown',
          message: 'User ID is null after registration.',
        );
      }

      // Step 2: Save user data to Firestore
      try {
      await _firestore.collection('users').doc(uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': email,
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("✅ User document created in Firestore for UID: $uid");
    } catch (e, st) {
      debugPrint("❌ Firestore write failed: $e");
      debugPrint("📄 StackTrace: $st");
    }

      // Step 3: Navigate to assessment screen
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AssessPrelim(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              final offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ FirebaseAuthException: ${e.code} - ${e.message}");
      if (mounted) {
        setState(() {
          _errorMessage = _getAuthErrorMessage(e);
        });
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Registration failed: $e");
      debugPrint("📄 StackTrace: $stackTrace");
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again later.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      default:
        return e.message ?? 'An unknown error occurred';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            height: screenHeight * 0.2 + 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.6,
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

          // Main Form
          Positioned(
            top: screenHeight * 0.2,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join PocketPT Now!',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF800020),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Recover Smart: Treat, Rehabilitate, Strengthen.",
                      style: GoogleFonts.ptSans(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.ptSans(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReusableInputField(
                            label: 'First Name',
                            icon: Icons.person,
                            controller: _firstNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          ReusableInputField(
                            label: 'Last Name',
                            icon: Icons.person,
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          ReusableInputField(
                            label: 'Email Address',
                            icon: Icons.email,
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          ReusableInputField(
                            label: 'Password',
                            isPassword: true,
                            icon: Icons.lock,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 14),

                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            title: DefaultTextStyle(
                              style: const TextStyle(fontSize: 12.0, color: Colors.black),
                              child: Wrap(
                                children: [
                                  const Text("By checking this, you agree to the "),
                                  GestureDetector(
                                    onTap: () => showReusableDialog(context, 'Terms of Service', [
                                      'The information provided above is intended for general informational purposes only...',
                                    ]),
                                    child: const Text(
                                      "Terms of Service",
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Color(0xFF800020),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text(" and "),
                                  GestureDetector(
                                    onTap: () => showReusableDialog(context, 'Privacy Policy', [
                                      'The developers are committed to upholding the highest standards...',
                                    ]),
                                    child: const Text(
                                      "Privacy Policy",
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Color(0xFF800020),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Text("."),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF800020),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      "Register",
                                      style: GoogleFonts.ptSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

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
                            const TextSpan(text: "Already have an account, "),
                            TextSpan(
                              text: 'login',
                              style: GoogleFonts.ptSans(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                color: const Color(0xFF800020),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                  );
                                },
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
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const ReusableInputField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.icon,
    this.controller,
    this.validator,
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Include at least one symbol';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? isObscured : false,
      validator: widget.isPassword ? _validatePassword : widget.validator,
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
    );
  }
}