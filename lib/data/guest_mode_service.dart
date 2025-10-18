import 'package:hive/hive.dart';
import 'dart:async';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'data_persistence_service.dart';

/// Service for managing guest mode with local-only data storage
class GuestModeService {
  static final GuestModeService _instance = GuestModeService._internal();
  static GuestModeService get instance => _instance;
  
  GuestModeService._internal();
  
  bool _isGuestMode = false;
  bool _isInitialized = false;
  String? _guestSessionId;
  
  /// Initialize guest mode service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('GuestModeService: Initializing...');
      
      // Initialize Hive if not already done
      if (!Hive.isBoxOpen('rehabBox')) {
        await openRehabBox();
      }
      
      // Check if there's an existing guest session
      await _loadGuestSession();
      
      _isInitialized = true;
      print('GuestModeService: Initialized successfully');
      
    } catch (e) {
      print('GuestModeService: Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Start guest mode session
  Future<Map<String, dynamic>> startGuestSession() async {
    try {
      print('GuestModeService: Starting guest session...');
      
      // Generate unique guest session ID
      _guestSessionId = _generateGuestSessionId();
      _isGuestMode = true;
      
      // Save guest session info to Hive
      final box = Hive.box('rehabBox');
      await box.put('guest_mode', true);
      await box.put('guest_session_id', _guestSessionId);
      await box.put('guest_session_start', DateTime.now().toIso8601String());
      
      // Initialize guest user data
      await _initializeGuestUserData();
      
      // Load any existing guest data
      await _loadGuestData();
      
      print('GuestModeService: Guest session started with ID: $_guestSessionId');
      return {
        'success': true,
        'sessionId': _guestSessionId,
        'message': 'Guest session started successfully'
      };
      
    } catch (e) {
      print('GuestModeService: Error starting guest session: $e');
      return {
        'success': false,
        'error': 'Failed to start guest session: ${e.toString()}'
      };
    }
  }
  
  /// Load existing guest session
  Future<void> _loadGuestSession() async {
    try {
      final box = Hive.box('rehabBox');
      final isGuestMode = box.get('guest_mode', defaultValue: false) as bool;
      
      if (isGuestMode) {
        _isGuestMode = true;
        _guestSessionId = box.get('guest_session_id') as String?;
        
        print('GuestModeService: Loaded existing guest session: $_guestSessionId');
      }
    } catch (e) {
      print('GuestModeService: Error loading guest session: $e');
    }
  }
  
  /// Initialize guest user data
  Future<void> _initializeGuestUserData() async {
    try {
      // Set up guest user details
      UserDetails.firstName = 'Guest';
      UserDetails.lastName = 'User';
      UserDetails.email = 'guest@local.app';
      UserDetails.isGuest = true;
      UserDetails.guestSessionId = _guestSessionId;
      UserDetails.hasCompletedAssessment = false; // Allow guests to take assessment
      
      // Save initial data to Hive
      await _saveGuestData();
      
    } catch (e) {
      print('GuestModeService: Error initializing guest user data: $e');
    }
  }
  
  
  /// Load guest data from Hive
  Future<void> _loadGuestData() async {
    try {
      // Load all data from Hive (local storage only)
      await DataPersistenceService.loadAllDataFromHive();
      
      print('GuestModeService: Guest data loaded from Hive');
    } catch (e) {
      print('GuestModeService: Error loading guest data: $e');
    }
  }
  
  /// Save guest data to Hive
  Future<void> _saveGuestData() async {
    try {
      // Save all data to Hive (local storage only)
      await DataPersistenceService.saveAllDataToHive();
      
      print('GuestModeService: Guest data saved to Hive');
    } catch (e) {
      print('GuestModeService: Error saving guest data: $e');
    }
  }
  
  /// Save data (guest mode - Hive only)
  Future<Map<String, dynamic>> saveData() async {
    try {
      if (!_isGuestMode) {
        return {'success': false, 'error': 'Not in guest mode'};
      }
      
      print('GuestModeService: Saving guest data...');
      
      // Update guest session timestamp
      final box = Hive.box('rehabBox');
      await box.put('guest_session_last_activity', DateTime.now().toIso8601String());
      
      // Save all data to Hive
      await _saveGuestData();
      
      return {'success': true, 'message': 'Guest data saved locally'};
      
    } catch (e) {
      print('GuestModeService: Error saving guest data: $e');
      return {'success': false, 'error': 'Failed to save guest data: ${e.toString()}'};
    }
  }

  /// Force save all guest data (useful after assessment completion)
  Future<Map<String, dynamic>> forceSaveAllData() async {
    try {
      if (!_isGuestMode) {
        return {'success': false, 'error': 'Not in guest mode'};
      }
      
      print('GuestModeService: Force saving all guest data...');
      
      // Update user details in memory
      UserDetails.isGuest = true;
      UserDetails.guestSessionId = _guestSessionId;
      
      // Save all data to Hive
      await _saveGuestData();
      
      // Also save assessment completion flag if set
      if (UserDetails.hasCompletedAssessment) {
        final box = Hive.box('rehabBox');
        await box.put('hasCompletedAssessment', true);
      }
      
      return {'success': true, 'message': 'All guest data force saved'};
      
    } catch (e) {
      print('GuestModeService: Error force saving guest data: $e');
      return {'success': false, 'error': 'Failed to force save guest data: ${e.toString()}'};
    }
  }
  
  /// Load data (guest mode - Hive only)
  Future<Map<String, dynamic>> loadData() async {
    try {
      if (!_isGuestMode) {
        return {'success': false, 'error': 'Not in guest mode'};
      }
      
      print('GuestModeService: Loading guest data...');
      
      // Load all data from Hive
      await _loadGuestData();
      
      return {'success': true, 'message': 'Guest data loaded from local storage'};
      
    } catch (e) {
      print('GuestModeService: Error loading guest data: $e');
      return {'success': false, 'error': 'Failed to load guest data: ${e.toString()}'};
    }
  }
  
  /// End guest session
  Future<Map<String, dynamic>> endGuestSession() async {
    try {
      print('GuestModeService: Ending guest session...');
      
      // Save final data
      await _saveGuestData();
      
      // Clear guest session info
      final box = Hive.box('rehabBox');
      await box.delete('guest_mode');
      await box.delete('guest_session_id');
      await box.delete('guest_session_start');
      await box.delete('guest_session_last_activity');
      
      // Reset guest mode
      _isGuestMode = false;
      _guestSessionId = null;
      
      // Clear user data
      UserDetails.firstName = '';
      UserDetails.lastName = '';
      UserDetails.email = '';
      UserDetails.isGuest = false;
      UserDetails.guestSessionId = null;
      
      UserRehabilitation.instance.rehabPlans.clear();
      UserRehabilitation.instance.activePlan = null;
      UserRehabilitation.instance.treatmentReferences = null;
      
      print('GuestModeService: Guest session ended');
      return {'success': true, 'message': 'Guest session ended successfully'};
      
    } catch (e) {
      print('GuestModeService: Error ending guest session: $e');
      return {'success': false, 'error': 'Failed to end guest session: ${e.toString()}'};
    }
  }
  
  /// Clear all guest data
  Future<Map<String, dynamic>> clearGuestData() async {
    try {
      print('GuestModeService: Clearing guest data...');
      
      // Clear all data from Hive
      final box = Hive.box('rehabBox');
      await box.clear();
      
      // Clear rehabilitation data
      UserRehabilitation.instance.rehabPlans.clear();
      UserRehabilitation.instance.activePlan = null;
      UserRehabilitation.instance.treatmentReferences = null;
      
      // Reset user details
      UserDetails.firstName = '';
      UserDetails.lastName = '';
      UserDetails.email = '';
      UserDetails.isGuest = false;
      UserDetails.guestSessionId = null;
      
      print('GuestModeService: Guest data cleared');
      return {'success': true, 'message': 'Guest data cleared successfully'};
      
    } catch (e) {
      print('GuestModeService: Error clearing guest data: $e');
      return {'success': false, 'error': 'Failed to clear guest data: ${e.toString()}'};
    }
  }
  
  /// Generate unique guest session ID
  String _generateGuestSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'guest_${timestamp}_$random';
  }
  
  /// Get guest session info
  Map<String, dynamic> getGuestSessionInfo() {
    return {
      'isGuestMode': _isGuestMode,
      'sessionId': _guestSessionId,
      'isInitialized': _isInitialized,
    };
  }
  
  /// Check if currently in guest mode
  bool get isGuestMode => _isGuestMode;
  
  /// Get current guest session ID
  String? get guestSessionId => _guestSessionId;
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
