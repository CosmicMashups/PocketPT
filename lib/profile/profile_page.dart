// Import packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/globals.dart';
import '../welcome/login_page.dart';
import '../data/data_management_widget.dart';
import '../data/data_persistence_service.dart';
import '../data/auth_persistence_service.dart';
import '../data/user_data_notifier.dart';
import '../data/guest_mode_service.dart';
// removed loader: using direct global data like a_goal1.dart

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Muscular maroon
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green
  static const errorColor = Color(0xFFEF4444); // Red

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  Widget build(BuildContext context) {
    // Initialize the notifier with current data
    UserDataNotifier.instance.initialize();

    final data = _gatherProfileData();
    return _buildProfileContent(context, data);
  }

  Map<String, dynamic> _gatherProfileData() {
    return {
      'isGuest': UserDetails.isGuest,
      'firstName': UserDataNotifier.instance.firstName,
      'lastName': UserDataNotifier.instance.lastName,
      'email': UserDataNotifier.instance.email,
      'profilePicture': UserDataNotifier.instance.profilePicture,
      'settings': {
        'isDailyReminder': UserSettings.isDailyReminder,
        'isExerciseReminder': UserSettings.isExerciseReminder,
      },
    };
  }

  // Removed legacy loading/error UI; page now builds directly from globals

  Widget _buildProfileContent(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = data['isGuest'] ?? false;
    
    return ListenableBuilder(
      listenable: UserDataNotifier.instance,
      builder: (context, child) {
        return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      appBar: AppBar(
            title: const Text('Profile Settings'),
        backgroundColor: mainColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
                // Profile Picture and Info Section
                _buildProfileSection(data),
                const SizedBox(height: 24),
                
                // Settings Section
                _buildSettingsSection(data),
                const SizedBox(height: 24),
                
                // Account Actions Section
                _buildAccountActionsSection(isGuest),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(Map<String, dynamic> data) {
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final email = data['email'] ?? '';
    final profilePicture = data['profilePicture'] ?? '01.jpg';
    
    return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
            Colors.white,
            const Color(0xFFF0F9FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
          color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
            color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showProfilePictureDialog,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: mainColor.withOpacity(0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: mainColor.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                        backgroundImage: AssetImage('assets/images/pfp/$profilePicture'),
                                backgroundColor: Colors.grey[200],
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                          padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: mainColor,
                                    shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                        Text(
                      '${firstName.isNotEmpty ? firstName : 'User'} ${lastName.isNotEmpty ? lastName : ''}',
                      style: const TextStyle(
                                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isNotEmpty ? email : 'No email provided',
                      style: const TextStyle(
                                        fontSize: 16,
                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                    const SizedBox(height: 8),
                            Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active User',
                                    style: TextStyle(
                          fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: mainColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ],
                      ),
                    ],
                  ),
    );
  }

  Widget _buildSettingsSection(Map<String, dynamic> data) {
    final settings = data['settings'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // Daily Reminder Toggle
          _buildSettingItem(
            'Daily Reminder',
            'Get reminded to complete daily assessments',
            Icons.notifications_active,
            settings['isDailyReminder'] ?? true,
            (value) {
              // Update setting and save
              UserSettings.isDailyReminder = value;
              UserSettings.saveToHive();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Exercise Reminder Toggle
          _buildSettingItem(
            'Exercise Reminder',
            'Get reminded about exercise sessions',
            Icons.fitness_center,
            settings['isExerciseReminder'] ?? true,
            (value) {
              // Update setting and save
              UserSettings.isExerciseReminder = value;
              UserSettings.saveToHive();
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Row(
      children: [
            Container(
          padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
            color: mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: mainColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  ),
                ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
          Switch(
          value: value,
          onChanged: onChanged,
          activeColor: mainColor,
        ),
      ],
    );
  }

  Widget _buildAccountActionsSection(bool isGuest) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // Data Management
          _buildActionItem(
            'Data Management',
            'Export or manage your data',
            Icons.storage,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataManagementWidget(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Logout/Exit Guest Mode
          _buildActionItem(
            isGuest ? 'Exit Guest Mode' : 'Logout',
            isGuest ? 'Return to login screen' : 'Sign out of your account',
            isGuest ? Icons.exit_to_app : Icons.logout,
            _handleLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: isDestructive ? errorColor.withOpacity(0.1) : mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? errorColor : mainColor,
                size: 24,
              ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                      color: isDestructive ? errorColor : const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  subtitle,
                    style: const TextStyle(
                    fontSize: 14,
                      color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive ? errorColor : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Handle logout with proper data saving and Firebase sign out
  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          final isGuest = UserDetails.isGuest;
          return AlertDialog(
            title: Text(isGuest ? 'Exit Guest Mode' : 'Logout'),
            content: Text(isGuest 
              ? 'Are you sure you want to exit guest mode? Your progress will be saved locally.'
              : 'Are you sure you want to logout? All unsaved data will be saved automatically.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(isGuest ? 'Exit' : 'Logout', style: const TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );

      if (shouldLogout != true) return;

      // Show loading indicator
      showDialog(
            context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      if (UserDetails.isGuest) {
        // Handle guest mode exit
        final guestModeService = GuestModeService.instance;
        await guestModeService.endGuestSession();
      } else {
        // Handle regular user logout
        // Save all data to Hive before logout
        await DataPersistenceService.instance.forceSave(reason: 'User logout');

        // Use authentication persistence service for logout
        await AuthPersistenceService.instance.onUserLoggedOut();
        
        // Sign out from Firebase
        await _auth.signOut();
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to login page and clear navigation stack
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }

      // Show success message
      if (mounted) {
        final isGuest = UserDetails.isGuest;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isGuest ? 'Exited guest mode successfully' : 'Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted) Navigator.of(context).pop();
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show profile picture selection dialog
  Future<void> _showProfilePictureDialog() async {
    final List<String> profilePictures = [
      '01.jpg', '02.jpg', '03.jpg', '04.jpg', '05.jpg', '06.jpg',
      '07.jpg', '08.jpg', '09.jpg', '10.jpg', '11.jpg', '12.jpg'
    ];
    
    final String? selectedPicture = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Profile Picture',
                    style: TextStyle(
                      color: mainColor,
                fontWeight: FontWeight.w600,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: profilePictures.length,
              itemBuilder: (context, index) {
                final picture = profilePictures[index];
                final isSelected = picture == UserDataNotifier.instance.profilePicture;
                
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(picture);
                  },
                  child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
                        color: isSelected ? mainColor : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
        ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: mainColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
      ),
                      ] : null,
                    ),
                    child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/pfp/$picture',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: detailColor),
              ),
            ),
          ],
        );
      },
    );
    
    if (selectedPicture != null && selectedPicture != UserDataNotifier.instance.profilePicture) {
      // Update the profile picture
      UserDataNotifier.instance.updateUserData(profilePicture: selectedPicture);
      
      // Save to Hive
      await UserDetails.saveToHive();
      
      // Update in Firebase
      try {
        await UserDetails.updateInFirebase(newProfilePicture: selectedPicture);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sync profile picture: ${e.toString()}'),
              backgroundColor: errorColor,
      ),
    );
  }
}
    }
  }
}