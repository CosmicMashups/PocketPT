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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                    offset: Offset(0, -5),
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
                        color: Color(0xFF800020),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Recover Smart: Treat, Rehabilitate, Strengthen.",
                      style: GoogleFonts.ptSans(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReusableInputField(
                            label: 'First Name',
                            icon: Icons.person,
                            controller: _firstNameController,
                          ),                          
                          const SizedBox(height: 14),

                          ReusableInputField(
                            label: 'Last Name',
                            icon: Icons.person,
                            controller: _lastNameController,
                          ),
                          const SizedBox(height: 14),

                          ReusableInputField(
                            label: 'E-mail Address',
                            icon: Icons.email,
                            controller: _emailController,
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
                                      'The information provided above is intended for general informational purposes only and should not be considered as a substitute for professional medical advice, diagnosis, or treatment.',
                                      'It is crucial that you consult with a qualified healthcare provider before beginning any new exercise regimen.',
                                      'Your health and safety are of the utmost importance, and professional guidance ensures appropriate choices.',
                                      'By using this application, you acknowledge and agree that the developers are not responsible for any injuries or complications that may arise.',
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
                                      'The developers are committed to upholding the highest standards of data privacy, security, and ethical conduct in the development and implementation of this academic research project.',
                                      'All information collected throughout the phases of data gathering, model development, and system evaluation shall be strictly utilized for academic purposes within the defined scope of the study. At no point shall any data be disclosed, shared, or used beyond the objectives of this research.',
                                      'The developers fully recognize that some of the data collected may contain personal, sensitive, or confidential information. As such, they commit to full compliance with the provisions of Republic Act No. 10173, also known as the Data Privacy Act of 2012. This includes the lawful collection, handling, processing, storage, and disposal of personal data.',
                                      'Appropriate technical, administrative, and organizational measures will be employed to protect the confidentiality, integrity, and security of all collected data. These measures aim to prevent unauthorized access, misuse, or data breaches at every stage of the research.',
                                      'This policy affirms the developers’ responsibility to safeguard the rights and privacy of all individuals involved and to maintain the trust and confidence of all stakeholders participating in the study.',
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
                          const SizedBox(height: 14),

                          Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.85,
                              child: ElevatedButton(
                                onPressed: () {
                                  final isValid = _formKey.currentState!.validate();
                                  if (isValid) {
                                    print('✅ All fields are valid. Proceeding...');                                    
                                  
                                    if (!_agreedToTerms) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('You must agree to the Terms of Service and Privacy Policy.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => AssessPrelim(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                                    print('❌ Some fields are invalid. Please correct the errors.');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF800020),
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text("Register",
                                    style: GoogleFonts.ptSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                  ),
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
                                color: Color(0xFF800020),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).push(createMorphRoute(LoginPage()));
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

  const ReusableInputField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.icon,
    this.controller,
  });

  @override
  State<ReusableInputField> createState() => _ReusableInputFieldState();
}

class _ReusableInputFieldState extends State<ReusableInputField> {
  late bool isObscured;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    isObscured = widget.isPassword;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8 || value.length > 16) return 'Password must be 8–16 characters long';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Include at least one symbol';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 80,
        child: TextFormField(
          controller: _controller,
          obscureText: widget.isPassword ? isObscured : false,
          validator: widget.isPassword ? _validatePassword : null,
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