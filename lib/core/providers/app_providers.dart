import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error_handler.dart';
import '../secure_auth_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/hive_user_repository.dart';

/// Core services providers
/// This replaces the static global state with proper dependency injection

/// Error handler provider
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

/// Secure authentication service provider
final secureAuthServiceProvider = Provider<SecureAuthService>((ref) {
  return SecureAuthService();
});

/// User repository provider
/// This provides the concrete Hive implementation
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return HiveUserRepository();
});

/// Authentication state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final authService = ref.watch(secureAuthServiceProvider);
  return AuthStateNotifier(authService);
});

/// Authentication state
class AuthState {
  final bool isLoggedIn;
  final User? user;
  final bool isLoading;
  final String? error;
  
  const AuthState({
    this.isLoggedIn = false,
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    bool? isLoggedIn,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isLoggedIn == other.isLoggedIn &&
          user == other.user &&
          isLoading == other.isLoading &&
          error == other.error;
  
  @override
  int get hashCode =>
      isLoggedIn.hashCode ^
      user.hashCode ^
      isLoading.hashCode ^
      error.hashCode;
}

/// Authentication state notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final SecureAuthService _authService;
  
  AuthStateNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }
  
  /// Check current authentication status
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final isLoggedInResult = await _authService.isLoggedIn();
      if (isLoggedInResult.isError) {
        state = state.copyWith(
          isLoading: false,
          error: isLoggedInResult.errorMessage,
        );
        return;
      }
      
      if (isLoggedInResult.data == true) {
        final sessionResult = await _authService.getSession();
        if (sessionResult.isError) {
          state = state.copyWith(
            isLoading: false,
            error: sessionResult.errorMessage,
          );
          return;
        }
        
        // TODO: Load user data from repository
        state = state.copyWith(
          isLoggedIn: true,
          isLoading: false,
          // user: user, // Will be implemented when user repository is ready
        );
      } else {
        state = state.copyWith(
          isLoggedIn: false,
          isLoading: false,
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }
  
  /// Login user
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Verify password
      final verifyResult = await _authService.verifyPassword(password);
      if (verifyResult.isError) {
        state = state.copyWith(
          isLoading: false,
          error: verifyResult.errorMessage,
        );
        return;
      }
      
      if (verifyResult.data != true) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password',
        );
        return;
      }
      
      // Generate session token (in real app, this would come from server)
      final sessionToken = _generateSessionToken();
      
      // Store session
      final storeResult = await _authService.storeSession(email, sessionToken);
      if (storeResult.isError) {
        state = state.copyWith(
          isLoading: false,
          error: storeResult.errorMessage,
        );
        return;
      }
      
      // TODO: Load user data from repository
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        // user: user, // Will be implemented when user repository is ready
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final clearResult = await _authService.clearSession();
      if (clearResult.isError) {
        state = state.copyWith(
          isLoading: false,
          error: clearResult.errorMessage,
        );
        return;
      }
      
      state = state.copyWith(
        isLoggedIn: false,
        user: null,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }
  
  /// Register new user
  Future<void> register(String email, String password, String? name) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Validate password strength
      final validateResult = _authService.validatePasswordStrength(password);
      if (validateResult.isError) {
        state = state.copyWith(
          isLoading: false,
          error: validateResult.errorMessage,
        );
        return;
      }
      
      // Store password securely
      final storeResult = await _authService.storePassword(password);
      if (storeResult.isError) {
        state = state.copyWith(
          isLoading: false,
          error: storeResult.errorMessage,
        );
        return;
      }
      
      // Generate session token
      final sessionToken = _generateSessionToken();
      
      // Store session
      final sessionResult = await _authService.storeSession(email, sessionToken);
      if (sessionResult.isError) {
        state = state.copyWith(
          isLoading: false,
          error: sessionResult.errorMessage,
        );
        return;
      }
      
      // TODO: Create user in repository
      state = state.copyWith(
        isLoggedIn: true,
        isLoading: false,
        // user: user, // Will be implemented when user repository is ready
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }
  
  /// Generate a simple session token (in real app, this would come from server)
  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000) % 1000000;
    return 'session_${timestamp}_$random';
  }
  
  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}
