import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'data_sync_service.dart';

/// Service to manage authentication persistence and data synchronization
class AuthPersistenceService {
  static final AuthPersistenceService _instance = AuthPersistenceService._internal();
  static AuthPersistenceService get instance => _instance;
  
  AuthPersistenceService._internal();
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String? _currentUserId;
  DateTime? _lastAuthCheck;
  
  /// Initialize the authentication persistence service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('AuthPersistenceService: Initializing...');
      
      // Initialize data sync service
      await DataSyncService.instance.initialize();
      
      // Listen to authentication state changes
      _auth.authStateChanges().listen(_onAuthStateChanged);
      
      // Check current authentication status
      await _checkAuthenticationStatus();
      
      _isInitialized = true;
      print('AuthPersistenceService: Initialized successfully');
      
    } catch (e) {
      print('AuthPersistenceService: Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Handle authentication state changes
  void _onAuthStateChanged(User? user) {
    final wasAuthenticated = _isAuthenticated;
    _isAuthenticated = user != null;
    _currentUserId = user?.uid;
    _lastAuthCheck = DateTime.now();
    
    print('AuthPersistenceService: Auth state changed - Authenticated: $_isAuthenticated, User ID: $_currentUserId');
    
    if (_isAuthenticated && !wasAuthenticated) {
      // User just logged in - delay token verification to prevent immediate sign out
      Future.delayed(const Duration(seconds: 2), () {
        if (_isAuthenticated && _auth.currentUser != null) {
          _onUserLoggedIn();
        }
      });
    } else if (!_isAuthenticated && wasAuthenticated) {
      // User just logged out
      onUserLoggedOut();
    }
  }
  
  /// Handle user login
  Future<void> _onUserLoggedIn() async {
    try {
      print('AuthPersistenceService: User logged in, syncing data...');
      
      // Use comprehensive data sync service
      final syncResults = await DataSyncService.instance.syncAllData();
      
      if (syncResults['success'] == true) {
        print('AuthPersistenceService: User login data sync completed successfully');
        print('AuthPersistenceService: Sync results: $syncResults');
      } else {
        print('AuthPersistenceService: Data sync failed: ${syncResults['error']}');
      }
      
    } catch (e) {
      print('AuthPersistenceService: Error syncing data on login: $e');
    }
  }
  
  /// Handle user logout
  Future<void> onUserLoggedOut() async {
    try {
      print('AuthPersistenceService: User logged out, clearing data...');
      
      // Use data sync service to clear all data
      await DataSyncService.instance.clearAllData();
      
      print('AuthPersistenceService: User logout data clear completed');
      
    } catch (e) {
      print('AuthPersistenceService: Error clearing data on logout: $e');
    }
  }
  
  /// Check current authentication status
  Future<void> _checkAuthenticationStatus() async {
    try {
      final user = _auth.currentUser;
      _isAuthenticated = user != null;
      _currentUserId = user?.uid;
      _lastAuthCheck = DateTime.now();
      
      print('AuthPersistenceService: Current auth status - Authenticated: $_isAuthenticated, User ID: $_currentUserId');
      
      // Skip token verification on startup to reduce loading time
      // Token will be verified when needed during operations
      if (_isAuthenticated) {
        print('AuthPersistenceService: User authenticated, skipping token verification for faster startup');
      }
      
    } catch (e) {
      print('AuthPersistenceService: Error checking authentication status: $e');
      _isAuthenticated = false;
      _currentUserId = null;
    }
  }
  
  
  /// Ensure user stays authenticated
  Future<bool> ensureAuthentication() async {
    try {
      if (!_isAuthenticated) {
        print('AuthPersistenceService: User not authenticated');
        return false;
      }
      
      // Check if token needs refresh
      final user = _auth.currentUser;
      if (user == null) {
        _isAuthenticated = false;
        return false;
      }
      
      // Check token expiration without forcing refresh
      final tokenResult = await user.getIdTokenResult();
      final expirationTime = tokenResult.expirationTime;
      
      if (expirationTime != null) {
        final timeUntilExpiry = expirationTime.difference(DateTime.now());
        print('AuthPersistenceService: Token expires in ${timeUntilExpiry.inMinutes} minutes');
        
        // Only refresh if token expires within 5 minutes
        if (timeUntilExpiry.inMinutes < 5) {
          print('AuthPersistenceService: Token expires soon, refreshing...');
          await user.getIdToken(true);
        }
      }
      
      return true;
      
    } catch (e) {
      print('AuthPersistenceService: Error ensuring authentication: $e');
      // Don't return false immediately, let the user continue
      return _auth.currentUser != null;
    }
  }
  
  /// Get authentication status
  bool get isAuthenticated => _isAuthenticated;
  
  /// Get current user ID
  String? get currentUserId => _currentUserId;
  
  /// Get last authentication check time
  DateTime? get lastAuthCheck => _lastAuthCheck;
  
  /// Force authentication check
  Future<void> forceAuthCheck() async {
    await _checkAuthenticationStatus();
  }
  
  /// Save authentication state to Hive
  Future<void> saveAuthStateToHive() async {
    try {
      final box = Hive.box('rehabBox');
      
      final authState = {
        'isAuthenticated': _isAuthenticated,
        'currentUserId': _currentUserId,
        'lastAuthCheck': _lastAuthCheck?.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await box.put('authState', authState);
      print('AuthPersistenceService: Auth state saved to Hive');
      
    } catch (e) {
      print('AuthPersistenceService: Error saving auth state to Hive: $e');
    }
  }
  
  /// Load authentication state from Hive
  Future<void> loadAuthStateFromHive() async {
    try {
      final box = Hive.box('rehabBox');
      final authState = box.get('authState');
      
      if (authState is Map<String, dynamic>) {
        _isAuthenticated = authState['isAuthenticated'] ?? false;
        _currentUserId = authState['currentUserId'];
        
        final lastAuthCheckStr = authState['lastAuthCheck'];
        if (lastAuthCheckStr != null) {
          _lastAuthCheck = DateTime.tryParse(lastAuthCheckStr);
        }
        
        print('AuthPersistenceService: Auth state loaded from Hive - Authenticated: $_isAuthenticated, User ID: $_currentUserId');
      }
      
    } catch (e) {
      print('AuthPersistenceService: Error loading auth state from Hive: $e');
    }
  }
  
  /// Sync all data for authenticated user
  Future<void> syncAllData() async {
    if (!_isAuthenticated) {
      print('AuthPersistenceService: Cannot sync data - user not authenticated');
      return;
    }
    
    try {
      print('AuthPersistenceService: Syncing all data...');
      
      // Ensure authentication is still valid
      final authValid = await ensureAuthentication();
      if (!authValid) {
        print('AuthPersistenceService: Authentication invalid, cannot sync');
        return;
      }
      
      // Use comprehensive data sync service
      final syncResults = await DataSyncService.instance.syncAllData();
      
      if (syncResults['success'] == true) {
        print('AuthPersistenceService: Data sync completed successfully');
        print('AuthPersistenceService: Sync results: $syncResults');
      } else {
        print('AuthPersistenceService: Data sync failed: ${syncResults['error']}');
      }
      
      // Save auth state
      await saveAuthStateToHive();
      
    } catch (e) {
      print('AuthPersistenceService: Error syncing data: $e');
    }
  }
  
  /// Get authentication persistence status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAuthenticated': _isAuthenticated,
      'currentUserId': _currentUserId,
      'lastAuthCheck': _lastAuthCheck?.toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Dispose of the service
  void dispose() {
    _isInitialized = false;
    _isAuthenticated = false;
    _currentUserId = null;
    _lastAuthCheck = null;
    print('AuthPersistenceService: Disposed');
  }
}
