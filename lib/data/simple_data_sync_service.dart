import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'data_persistence_service.dart';
import 'firebase_helper.dart';
import 'guest_mode_service.dart';

/// Simplified unified data sync service with clear fallbacks
class SimpleDataSyncService {
  static final SimpleDataSyncService _instance = SimpleDataSyncService._internal();
  static SimpleDataSyncService get instance => _instance;
  
  SimpleDataSyncService._internal();
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isInitialized = false;
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('SimpleDataSyncService: Initializing...');
      
      // Initialize Hive if not already done
      if (!Hive.isBoxOpen('rehabBox')) {
        await Hive.openBox('rehabBox');
      }
      
      _isInitialized = true;
      print('SimpleDataSyncService: Initialized successfully');
      
    } catch (e) {
      print('SimpleDataSyncService: Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Sync all user data with simple fallback strategy
  Future<Map<String, dynamic>> syncUserData() async {
    try {
      print('SimpleDataSyncService: Starting user data sync...');
      
      // Check if in guest mode
      if (UserDetails.isGuest) {
        print('SimpleDataSyncService: Guest mode detected, using local storage only');
        return await _syncGuestData();
      }
      
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No authenticated user'};
      }
      
      // Try Firebase first, fallback to Hive
      try {
        await _syncFromFirebase();
        return {'success': true, 'source': 'firebase'};
      } catch (firebaseError) {
        print('SimpleDataSyncService: Firebase sync failed, trying Hive: $firebaseError');
        await _syncFromHive();
        return {'success': true, 'source': 'hive', 'warning': 'Using offline data'};
      }
      
    } catch (e) {
      print('SimpleDataSyncService: Error syncing user data: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Sync from Firebase
  Future<void> _syncFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    
    // Initialize Firebase collections
    await FirebaseHelper.initializeUserCollections();
    
    // Load user data from Firebase
    await UserDetails.loadFromFirebase();
    
    // Load rehabilitation data from Firebase
    await UserRehabilitation.instance.loadPlansFromFirebase();
    
    // Load other data from Hive as fallback
    await DataPersistenceService.loadAllDataFromHive();
    
    print('SimpleDataSyncService: Firebase sync completed');
  }
  
  /// Sync from Hive
  Future<void> _syncFromHive() async {
    // Load all data from Hive
    await DataPersistenceService.loadAllDataFromHive();
    
    // Try to save to Firebase if user is authenticated
    try {
      await UserDetails.updateInFirebase();
      await UserRehabilitation.instance.savePlansToFirebase();
    } catch (e) {
      print('SimpleDataSyncService: Could not save to Firebase: $e');
    }
    
    print('SimpleDataSyncService: Hive sync completed');
  }
  
  /// Sync guest data (Hive only)
  Future<Map<String, dynamic>> _syncGuestData() async {
    try {
      // Load all data from Hive for guest mode
      await DataPersistenceService.loadAllDataFromHive();
      
      print('SimpleDataSyncService: Guest data sync completed');
      return {'success': true, 'source': 'guest_hive', 'message': 'Guest mode - local storage only'};
      
    } catch (e) {
      print('SimpleDataSyncService: Error syncing guest data: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  /// Clear all user data
  Future<void> clearUserData() async {
    try {
      print('SimpleDataSyncService: Clearing user data...');
      
      // Check if in guest mode
      if (UserDetails.isGuest) {
        print('SimpleDataSyncService: Clearing guest data...');
        await GuestModeService.instance.clearGuestData();
        return;
      }
      
      // Clear from Hive
      final box = Hive.box('rehabBox');
      await box.clear();
      
      // Clear rehabilitation data
      UserRehabilitation.instance.rehabPlans.clear();
      UserRehabilitation.instance.treatmentReferences = null;
      UserRehabilitation.instance.activePlan = null;
      
      print('SimpleDataSyncService: User data cleared');
      
    } catch (e) {
      print('SimpleDataSyncService: Error clearing user data: $e');
    }
  }
  
  /// Check if user is authenticated or in guest mode
  bool get isAuthenticated => _auth.currentUser != null || UserDetails.isGuest;
  
  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid ?? UserDetails.guestSessionId;
}
