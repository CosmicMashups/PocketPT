import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import '../data/simple_auth_service.dart';
import '../widgets/progressive_loading_widget.dart';
import '../widgets/responsive_dialog.dart';
import '../main.dart';
import 'email_verification_page.dart';
import 'login_page.dart';
import '../assessment/preliminary.dart';
/// Registration page with proper password validation
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  
  final SimpleAuthService _authService = SimpleAuthService.instance;
  
  bool _isLoading = false;
  String? _errorMessage = '';
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle user registration
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms and Privacy Policy';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (result.requiresEmailVerification) {
        _showEmailVerificationPage(result.email!);
      } else {
        setState(() {
          _errorMessage = result.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Show email verification page
  void _showEmailVerificationPage(String email) {
    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleEmailVerificationPage(
          email: email,
          password: _passwordController.text.trim(), // Pass password for automatic login
          onVerificationComplete: () {
            // Navigate to assessment process since user will be automatically logged in
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AssessPrelim()),
            );
          },
        ),
      ),
    );
  }

  /// Navigate to login page
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  /// Validate password confirmation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC), // Professional background
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isLoading ? 'Creating account...' : null,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Professional Header Section
              Container(
                height: screenHeight * 0.35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B2E2E), // Muscular maroon
                      const Color(0xFFC24A4A), // Light maroon
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          'assets/images/welcome_1.jpg',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    // Logo and branding
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Flexible(
                            child: Text(
                              'Join PocketPT',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              'Start Your Rehabilitation Journey',
                              style: GoogleFonts.ptSans(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Form Section
              Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32.0),
                    topRight: Radius.circular(32.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B2E2E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person_add,
                                  color: Color(0xFF8B2E2E),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create Your Account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Join our professional rehabilitation platform",
                                      style: GoogleFonts.ptSans(
                                        fontSize: 16,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (_errorMessage!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.red.withOpacity(0.3) : const Color(0xFFFECACA),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.ptSans(
                                  color: const Color(0xFFDC2626),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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

                          ReusableInputField(
                            label: 'Confirm Password',
                            isPassword: true,
                            icon: Icons.lock,
                            controller: _confirmPasswordController,
                            validator: _validateConfirmPassword,
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
                                    onTap: () => _showTermsDialog(
                                      context,
                                      'Terms of Service',
                                      [
                                        'Welcome to PocketPT, a user-centric rehabilitation application designed to assist individuals in managing muscle strains and injuries through treatment, rehabilitation, and strengthening.',
                                        '1. Acceptance of Terms:',
                                        'By using PocketPT, you agree to these Terms of Service and our Privacy Policy. If you do not agree, please discontinue use.',
                                        '2. Eligibility:',
                                        'Users must be at least 18 years old or have parental/guardian consent to use the app.',
                                        '3. Purpose of the Application:',
                                        'PocketPT is a research-based academic project for educational and self-management support only. It is not a substitute for professional medical advice. Always consult a healthcare provider for medical concerns.',
                                        '4. User Responsibilities:',
                                        '- Provide accurate and truthful information.',
                                        '- Use the app only for personal, non-commercial purposes.',
                                        '- Do not misuse, modify, or attempt unauthorized access.',
                                        '5. Data Collection & Confidentiality:',
                                        'Feedback and anonymized data may be collected strictly for research purposes and handled in accordance with the Privacy Policy and Data Privacy Act of 2012.',
                                        '6. Intellectual Property:',
                                        'All app content and features are the intellectual property of the developers and cannot be copied or redistributed without permission.',
                                        '7. Limitation of Liability:',
                                        'PocketPT is provided "as is." The developers are not liable for injuries, damages, or losses resulting from reliance on the app. Users assume full responsibility for their health decisions.',
                                        '8. Termination:',
                                        'We reserve the right to suspend or terminate access if these Terms are violated.',
                                        '9. Changes to Terms:',
                                        'Terms of Service may be updated periodically. Continued use of PocketPT after changes means acceptance of the new terms.'
                                      ],
                                    ),
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
                                    onTap: () => _showTermsDialog(
                                      context,
                                      'Privacy Policy',
                                      [
                                        'PocketPT values and protects your privacy. This Privacy Policy explains how we collect, use, store, and safeguard your personal information.',
                                        '1. Information We Collect:',
                                        '- Personal Information: Email address or contact details (if voluntarily provided).',
                                        '- Usage Data: App interaction logs, survey responses, and anonymized feedback.',
                                        '- Health-Related Inputs: Self-reported symptoms or injury details, used solely for rehabilitation guidance.',
                                        '2. Purpose of Data Collection:',
                                        '- To support academic research and system development.',
                                        '- To provide rehabilitation guidance through the app.',
                                        '- To improve user experience and app functionality.',
                                        '3. Confidentiality and Data Protection:',
                                        '- All data is treated as confidential and only used for research purposes.',
                                        '- No data will be sold, shared, or disclosed to unauthorized parties.',
                                        '- Security measures are implemented to prevent unauthorized access or breaches.',
                                        '4. Compliance with Law:',
                                        'PocketPT complies with the Data Privacy Act of 2012 (RA 10173) and applicable laws on data collection and protection.',
                                        '5. Data Retention:',
                                        'Data is retained only as long as necessary for research objectives and securely deleted afterward.',
                                        '6. Your Rights as a User:',
                                        '- Access the data you provided.',
                                        '- Request corrections of inaccuracies.',
                                        '- Request deletion of your data (subject to research requirements).',
                                        '- Withdraw consent at any time.',
                                        '7. Third-Party Services:',
                                        'PocketPT does not share personal data with third parties unless explicitly required for academic purposes with consent.',
                                        '8. Updates to Privacy Policy:',
                                        'This Privacy Policy may be updated periodically. Users will be notified of significant changes.'
                                      ],
                                    ),
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

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B2E2E).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Creating Account...",
                                          style: GoogleFonts.ptSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.person_add,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Create Account",
                                          style: GoogleFonts.ptSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.ptSans(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                              children: [
                                const TextSpan(text: "Already have an account? "),
                                TextSpan(
                                  text: 'Sign In',
                                  style: GoogleFonts.ptSans(
                                    fontSize: 14,
                                    color: const Color(0xFF8B2E2E),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _navigateToLogin,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show terms dialog
  void _showTermsDialog(BuildContext context, String title, List<String> content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveDialog(
          title: title,
          icon: Icons.description,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: content.map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                text,
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            )).toList(),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
      style: GoogleFonts.ptSans(
        fontSize: 16,
        color: const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.ptSans(
          color: const Color(0xFF6B7280),
          fontSize: 14,
        ),
        prefixIcon: widget.icon != null 
            ? Icon(
                widget.icon, 
                color: const Color(0xFF6B7280),
                size: 20,
              ) 
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    isObscured = !isObscured;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF8B2E2E),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
