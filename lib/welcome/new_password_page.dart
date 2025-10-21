import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../data/forgot_password_service.dart';
import '../widgets/progressive_loading_widget.dart';
import '../widgets/responsive_dialog.dart';
import '../main.dart';
/// New password reset page
class NewPasswordPage extends StatefulWidget {
  final String email;

  const NewPasswordPage({super.key, required this.email});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService.instance;
  
  bool _isLoading = false;
  String? _errorMessage = '';
  String? _successMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle password reset
  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final result = await _forgotPasswordService
          .resetPasswordWithCode(widget.email, _passwordController.text.trim())
          .timeout(const Duration(seconds: 15));

      if (result.success) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Password reset email sent successfully';
        });
        
        // Show success dialog and navigate to login
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = result.error;
          _isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Connection timed out. Please check your internet and try again.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ResponsiveDialog(
          title: 'Password Reset Successful!',
          icon: Icons.check_circle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSuccessColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: kSuccessColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'A password reset email has been sent to your email address. Please check your inbox and follow the instructions to complete the password reset.',
                style: GoogleFonts.ptSans(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : kTextNormal,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Navigate to login page
  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  /// Navigate back to verification code page
  void _navigateBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          onPressed: _navigateBack,
        ),
        title: Text(
          'New Password',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isLoading ? 'Resetting password...' : null,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                height: screenHeight * 0.25,
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
                    // Content
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
                            child: const Icon(
                              Icons.lock_outline,
                              size: 50,
                              color: Color(0xFF8B2E2E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Create New Password',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a strong password for your account',
                            style: GoogleFonts.ptSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Password Requirements
                      Container(
                        padding: const EdgeInsets.all(20),
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
                                    Icons.security,
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
                                        'Password Requirements',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Your password must meet the following criteria:",
                                        style: GoogleFonts.ptSans(
                                          fontSize: 14,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordRequirement('At least 8 characters long'),
                            _buildPasswordRequirement('Contains uppercase letter (A-Z)'),
                            _buildPasswordRequirement('Contains lowercase letter (a-z)'),
                            _buildPasswordRequirement('Contains number (0-9)'),
                            _buildPasswordRequirement('Contains special character (!@#\$%^&*)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Error Message
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
                      
                      // Success Message
                      if (_successMessage!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.green.withOpacity(0.1) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.green.withOpacity(0.3) : const Color(0xFFBBF7D0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF16A34A),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: GoogleFonts.ptSans(
                                    color: const Color(0xFF16A34A),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // New Password Field
                      ReusableInputField(
                        label: 'New Password',
                        isPassword: true,
                        icon: Icons.lock,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(value)) {
                            return 'Password must contain at least one uppercase letter';
                          }
                          if (!RegExp(r'[a-z]').hasMatch(value)) {
                            return 'Password must contain at least one lowercase letter';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(value)) {
                            return 'Password must contain at least one number';
                          }
                          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                            return 'Password must contain at least one special character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      ReusableInputField(
                        label: 'Confirm New Password',
                        isPassword: true,
                        icon: Icons.lock_outline,
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      // Reset Password Button
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
                          onPressed: _isLoading ? null : _handlePasswordReset,
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
                                      "Resetting Password...",
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
                                      Icons.lock_reset,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Reset Password",
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build password requirement item
  Widget _buildPasswordRequirement(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF8B2E2E),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              requirement,
              style: GoogleFonts.ptSans(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable input field widget with custom visibility toggle
class ReusableInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;

  const ReusableInputField({
    required this.label,
    required this.controller,
    this.isPassword = false,
    required this.icon,
    this.validator,
    this.obscureText = true,
    this.onToggleVisibility,
  });

  @override
  State<ReusableInputField> createState() => _ReusableInputFieldState();
}

class _ReusableInputFieldState extends State<ReusableInputField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? widget.obscureText : false,
      validator: widget.validator,
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
        prefixIcon: Icon(
          widget.icon,
          color: const Color(0xFF6B7280),
          size: 20,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  widget.obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: widget.onToggleVisibility,
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
