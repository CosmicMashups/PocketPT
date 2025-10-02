import 'package:flutter/foundation.dart';
import 'globals.dart';

/// Service to notify UI components when user data changes
class UserDataNotifier extends ChangeNotifier {
  static final UserDataNotifier _instance = UserDataNotifier._internal();
  static UserDataNotifier get instance => _instance;
  
  UserDataNotifier._internal();
  
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _profilePicture = '01.jpg';
  bool _hasCompletedAssessment = false;
  bool _isLoading = false;
  
  // Getters
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get email => _email;
  String get profilePicture => _profilePicture;
  bool get hasCompletedAssessment => _hasCompletedAssessment;
  bool get isLoading => _isLoading;
  
  /// Initialize with current UserDetails values
  void initialize() {
    _firstName = UserDetails.firstName;
    _lastName = UserDetails.lastName;
    _email = UserDetails.email;
    _profilePicture = UserDetails.profilePicture;
    _hasCompletedAssessment = UserDetails.hasCompletedAssessment;
    notifyListeners();
  }
  
  /// Update user data and notify listeners
  void updateUserData({
    String? firstName,
    String? lastName,
    String? email,
    String? profilePicture,
    bool? hasCompletedAssessment,
  }) {
    bool hasChanges = false;
    
    if (firstName != null && _firstName != firstName) {
      _firstName = firstName;
      UserDetails.firstName = firstName;
      hasChanges = true;
    }
    
    if (lastName != null && _lastName != lastName) {
      _lastName = lastName;
      UserDetails.lastName = lastName;
      hasChanges = true;
    }
    
    if (email != null && _email != email) {
      _email = email;
      UserDetails.email = email;
      hasChanges = true;
    }
    
    if (profilePicture != null && _profilePicture != profilePicture) {
      _profilePicture = profilePicture;
      UserDetails.profilePicture = profilePicture;
      hasChanges = true;
    }
    
    if (hasCompletedAssessment != null && _hasCompletedAssessment != hasCompletedAssessment) {
      _hasCompletedAssessment = hasCompletedAssessment;
      UserDetails.hasCompletedAssessment = hasCompletedAssessment;
      hasChanges = true;
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// Sync with UserDetails and notify listeners
  void syncWithUserDetails() {
    bool hasChanges = false;
    
    if (_firstName != UserDetails.firstName) {
      _firstName = UserDetails.firstName;
      hasChanges = true;
    }
    
    if (_lastName != UserDetails.lastName) {
      _lastName = UserDetails.lastName;
      hasChanges = true;
    }
    
    if (_email != UserDetails.email) {
      _email = UserDetails.email;
      hasChanges = true;
    }
    
    if (_profilePicture != UserDetails.profilePicture) {
      _profilePicture = UserDetails.profilePicture;
      hasChanges = true;
    }
    
    if (_hasCompletedAssessment != UserDetails.hasCompletedAssessment) {
      _hasCompletedAssessment = UserDetails.hasCompletedAssessment;
      hasChanges = true;
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }
  
  /// Force refresh from UserDetails
  void refresh() {
    _firstName = UserDetails.firstName;
    _lastName = UserDetails.lastName;
    _email = UserDetails.email;
    _profilePicture = UserDetails.profilePicture;
    _hasCompletedAssessment = UserDetails.hasCompletedAssessment;
    notifyListeners();
  }
  
  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  /// Check if user data is empty (not loaded yet)
  bool get isEmpty => _firstName.isEmpty && _lastName.isEmpty && _email.isEmpty;
}
