import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:async';
import '../data/simple_auth_service.dart';
import '../data/guest_mode_service.dart';
import '../data/optimized_data_service.dart';
import '../widgets/progressive_loading_widget.dart';
import '../widgets/hero_elements.dart';
import '../core/animations.dart';
import 'email_verification_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../main.dart';
/// Login page with progressive loading and streamlined flow
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  
  final SimpleAuthService _authService = SimpleAuthService.instance;
  final GuestModeService _guestModeService = GuestModeService.instance;
  
  bool _isLoading = false;
  String? _errorMessage = '';
  String _loadingMessage = 'Signing in...';
  double _loadingProgress = 0.0;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle email/password sign in with optimized flow
  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _loadingMessage = 'Authenticating...';
        _loadingProgress = 0.0;
      });
    }

    try {
      // Update loading progress
      if (mounted) {
        setState(() {
          _loadingMessage = 'Verifying credentials...';
          _loadingProgress = 0.3;
        });
      }

      // Authenticate user first
      final result = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      ).timeout(const Duration(seconds: 15));

      if (result.success == true) {
        // Update loading progress before navigation
        if (mounted) {
          setState(() {
            _loadingMessage = 'Welcome back!';
            _loadingProgress = 1.0;
          });
        }
        
        // Small delay to show completion message
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate immediately for better UX
        _navigateToHomeWithBackgroundSync();
      } else if (result.requiresEmailVerification == true) {
        _showEmailVerificationPage(result.email!);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result.error ?? 'Login failed. Please try again.';
            _isLoading = false;
          });
        }
      }
    } on TimeoutException {
      _handleLoginError('Connection timed out. Please check your internet and try again.');
    } catch (e) {
      _handleLoginError('An unexpected error occurred. Please try again.');
    }
  }

  /// Handle Google sign in with optimized flow
  Future<void> _handleGoogleSignIn() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _loadingMessage = 'Connecting to Google...';
        _loadingProgress = 0.0;
      });
    }

    try {
      // Update loading progress
      if (mounted) {
        setState(() {
          _loadingMessage = 'Authenticating with Google...';
          _loadingProgress = 0.5;
        });
      }

      // Authenticate with Google
      final result = await _authService.signInWithGoogle().timeout(const Duration(seconds: 15));

      if (result.success == true) {
        // Update loading progress before navigation
        if (mounted) {
          setState(() {
            _loadingMessage = 'Welcome!';
            _loadingProgress = 1.0;
          });
        }
        
        // Small delay to show completion message
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate immediately for better UX
        _navigateToHomeWithBackgroundSync();
      } else if (result.cancelled == true) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result.error ?? 'Google sign in failed. Please try again.';
            _isLoading = false;
          });
        }
      }
    } on TimeoutException {
      _handleLoginError('Connection timed out. Please check your internet and try again.');
    } catch (e) {
      _handleLoginError('An unexpected error occurred. Please try again.');
    }
  }

  /// Show email verification page
  void _showEmailVerificationPage(String email) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    Navigator.push(
          context,
          MaterialPageRoute(
        builder: (context) => SimpleEmailVerificationPage(
          email: email,
              onVerificationComplete: () {
            Navigator.pop(context);
            _navigateToHome();
              },
            ),
          ),
        );
  }

  /// Navigate to home page with background data sync
  void _navigateToHomeWithBackgroundSync() {
    // Navigate immediately for better UX
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
    
    // Start background data sync without blocking UI
    _performBackgroundDataSync();
  }

  /// Navigate to home page (legacy method for compatibility)
  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  /// Handle login errors with retry logic
  void _handleLoginError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
        _loadingProgress = 0.0;
      });
    }
  }

  /// Retry the last attempted action
  void _retryLastAction() {
    // Simple retry logic - could be enhanced to track the last action
    if (_retryCount <= _maxRetries) {
      // Add a small delay before retry
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Reset retry count after max retries
          if (_retryCount >= _maxRetries) {
            _retryCount = 0;
          }
        }
      });
    }
  }

  /// Perform background data sync without blocking UI
  Future<void> _performBackgroundDataSync() async {
    try {
      print('LoginPage: Starting background data sync...');
      
      // Start background sync operations in parallel with priority
      final futures = <Future<void>>[];
      
      // High priority: User profile data
      futures.add(
        OptimizedDataService().preloadData(
          'user_profile',
          () async {
            // Simulate loading user profile data
            await Future.delayed(const Duration(milliseconds: 50));
            return 'user_profile_loaded';
          },
        ).then((_) => print('LoginPage: User profile preloaded')),
      );
      
      // Medium priority: Exercise data (load in background)
      futures.add(
        Future.delayed(const Duration(milliseconds: 100)).then((_) =>
          OptimizedDataService().preloadData(
            'exercise_data',
            () async {
              // Simulate loading exercise data
              await Future.delayed(const Duration(milliseconds: 100));
              return 'exercise_data_loaded';
            },
          ),
        ).then((_) => print('LoginPage: Exercise data preloaded')),
      );
      
      // Low priority: Treatment data (load last)
      futures.add(
        Future.delayed(const Duration(milliseconds: 200)).then((_) =>
          OptimizedDataService().preloadData(
            'treatment_data',
            () async {
              // Simulate loading treatment data
              await Future.delayed(const Duration(milliseconds: 80));
              return 'treatment_data_loaded';
            },
          ),
        ).then((_) => print('LoginPage: Treatment data preloaded')),
      );
      
      // Wait for all background operations to complete
      await Future.wait(futures);
      
      print('LoginPage: Background data sync completed successfully');
    } catch (e) {
      print('LoginPage: Background data sync failed: $e');
      // Don't show error to user as this is background operation
    }
  }

  /// Navigate to register page
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  /// Navigate to forgot password page
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  /// Handle guest mode login with optimized flow
  Future<void> _handleGuestMode() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _loadingMessage = 'Setting up guest mode...';
        _loadingProgress = 0.0;
      });
    }

    try {
      // Update loading progress
      if (mounted) {
        setState(() {
          _loadingMessage = 'Initializing guest session...';
          _loadingProgress = 0.4;
        });
      }

      // Initialize guest mode service
      await _guestModeService.initialize();
      
      // Update loading progress
      if (mounted) {
        setState(() {
          _loadingMessage = 'Starting guest session...';
          _loadingProgress = 0.7;
        });
      }
      
      // Start guest session
      final result = await _guestModeService.startGuestSession().timeout(const Duration(seconds: 8));

      if (result['success']) {
        // Update loading progress before navigation
        if (mounted) {
          setState(() {
            _loadingMessage = 'Welcome, Guest!';
            _loadingProgress = 1.0;
          });
        }
        
        // Small delay to show completion message
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Navigate immediately for guest mode (no background sync needed)
        _navigateToHome();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['error'] ?? 'Failed to start guest session';
            _isLoading = false;
          });
        }
      }
    } on TimeoutException {
      _handleLoginError('Connection timed out. Please try again.');
    } catch (e) {
      _handleLoginError('An unexpected error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC), // Professional background
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isLoading ? _loadingMessage : null,
        progress: _isLoading ? _loadingProgress : null,
        child: SingleChildScrollView(
          child: AnimationLimiter(
            child: Column(
              children: [
              // Professional Header Section
              Container(
                height: screenHeight * 0.4,
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
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: PocketPTAnimations.pageTransition,
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo/pocketpt.png',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Flexible(
                            child: Image.asset(
                              'assets/images/logo/branding.png',
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  'PocketPT',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              'Professional Rehabilitation Platform',
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
                child: Form(
                  key: _formKey,
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
                                    Icons.login,
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
                                        'Welcome Back!',
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Let's continue your rehabilitation journey",
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
                              if (_errorMessage!.contains('timeout') || _errorMessage!.contains('connection') || _errorMessage!.contains('unexpected'))
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _errorMessage = '';
                                      _retryCount++;
                                    });
                                    // Retry the last attempted action
                                    if (_retryCount <= _maxRetries) {
                                      _retryLastAction();
                                    }
                                  },
                                  child: Text(
                                    _retryCount < _maxRetries ? 'Try Again' : 'Reset',
                                    style: GoogleFonts.ptSans(
                                      color: const Color(0xFF8B2E2E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      
                      ReusableInputField(
                        label: 'Email Address',
                        icon: Icons.email,
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      ReusableInputField(
                        label: 'Password',
                        isPassword: true,
                        icon: Icons.lock,
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _navigateToForgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.ptSans(
                              color: const Color(0xFF8B2E2E),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
                          onPressed: _isLoading ? null : _handleEmailSignIn,
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
                                      "Signing in...",
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
                                      Icons.login,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Sign In",
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
                      
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "OR",
                              style: GoogleFonts.ptSans(
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: OutlinedButton.icon(
                          icon: Image.asset(
                            'assets/images/logo/google.png',
                            height: 20,
                          ),
                          label: Text(
                            'Continue with Google',
                            style: GoogleFonts.ptSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Continue as Guest Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.person_outline,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          label: Text(
                            'Continue as Guest',
                            style: GoogleFonts.ptSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleGuestMode,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                                const TextSpan(text: "Don't have an account yet? "),
                                TextSpan(
                                  text: 'Create Account',
                                  style: GoogleFonts.ptSans(
                                    color: const Color(0xFF8B2E2E),
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                      ..onTap = _navigateToRegister,
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

class ReusableInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final IconData icon;
  final FormFieldValidator<String>? validator;

  const ReusableInputField({
    required this.label,
    required this.controller,
    this.isPassword = false,
    required this.icon,
    this.validator,
  });

  @override
  State<ReusableInputField> createState() => _ReusableInputFieldState();
}

class _ReusableInputFieldState extends State<ReusableInputField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
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
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
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
