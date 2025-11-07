// Import packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive/hive.dart';
import '../data/globals.dart';
import '../core/animations.dart';
import '../welcome/login_page.dart';
import '../data/functions.dart';
import '../data/data_persistence_service.dart';
import '../data/auth_persistence_service.dart';
import '../data/user_data_notifier.dart';
import '../data/guest_mode_service.dart';
import '../widgets/responsive_dialog.dart';
import '../demo/pose_estimation_demo.dart';
import '../main.dart';
import '../reports/services/pdf_export_service.dart';
import '../tutorials/tutorial_config.dart';
import '../tutorials/tutorial_preferences.dart';
import '../tutorials/tutorial_service.dart';
// removed loader: using direct global data like a_goal1.dart

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Muscular maroon
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green
  static const errorColor = Color(0xFFEF4444); // Red

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  bool _tutorialsEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    // Load settings from Hive/Firebase if not already loaded
    UserSettings.loadFromHive();
    _loadTutorialPreferences();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
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

  Future<void> _loadTutorialPreferences() async {
    try {
      await TutorialPreferences.instance.ensureInitialized();
      if (!mounted) return;
      setState(() {
        _tutorialsEnabled = TutorialPreferences.instance.tutorialsEnabled;
      });
    } catch (e) {
      debugPrint('ProfilePage: Failed to load tutorial preferences: $e');
    }
  }

  Future<void> _handleTutorialToggle(bool value) async {
    await TutorialPreferences.instance.ensureInitialized();
    await TutorialPreferences.instance.setTutorialsEnabled(value);
    if (!mounted) {
      return;
    }
    setState(() {
      _tutorialsEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Guided tutorials enabled.' : 'Guided tutorials disabled.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _replayTutorialFlow(BuildContext context, String flowId) async {
    await TutorialPreferences.instance.ensureInitialized();
    for (final step in TutorialRegistry.steps.where((step) => step.flowId == flowId)) {
      await TutorialPreferences.instance.resetStep(step.id);
    }
    await TutorialPreferences.instance.resetFlow(flowId);
    await TutorialService.instance.startFlow(context, flowId);
  }

  Future<void> _resetAllTutorials(BuildContext context) async {
    await TutorialPreferences.instance.ensureInitialized();
    for (final step in TutorialRegistry.steps) {
      await TutorialPreferences.instance.resetStep(step.id);
    }
    final flowIds = TutorialRegistry.steps
        .map((step) => step.flowId)
        .whereType<String>()
        .toSet();
    for (final flowId in flowIds) {
      await TutorialPreferences.instance.resetFlow(flowId);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tutorial progress has been reset.'),
        duration: Duration(seconds: 2),
      ),
    );
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
        child: AnimationLimiter(
          child: Column(
            children: [
                // Profile Picture and Info Section
                AnimationConfiguration.staggeredList(
                  position: 0,
                  duration: PocketPTAnimations.pageTransition,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildProfileSection(data),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Settings Section
                AnimationConfiguration.staggeredList(
                  position: 1,
                  duration: PocketPTAnimations.pageTransition,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildSettingsSection(data),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Pain Detection Settings Section
                AnimationConfiguration.staggeredList(
                  position: 2,
                  duration: PocketPTAnimations.pageTransition,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildPainDetectionSettingsSection(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Data & Export Section
                AnimationConfiguration.staggeredList(
                  position: 3,
                  duration: PocketPTAnimations.pageTransition,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildDataExportSection(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Pose Estimation Demo Section - HIDDEN
                // AnimationConfiguration.staggeredList(
                //   position: 3,
                //   duration: PocketPTAnimations.pageTransition,
                //   child: SlideAnimation(
                //     verticalOffset: 50.0,
                //     child: FadeInAnimation(
                //       child: _buildPoseEstimationDemoSection(),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 24),
                
                // Security Section - HIDDEN
                // _buildSecuritySection(),
                // const SizedBox(height: 24),
                
                // Legal Section
                _buildLegalSection(),
                const SizedBox(height: 24),
                
                // Account Actions Section (moved to bottom)
                AnimationConfiguration.staggeredList(
                  position: 5,
                  duration: PocketPTAnimations.pageTransition,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildAccountActionsSection(isGuest),
                    ),
                  ),
                ),
              ],
            ),
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
                        backgroundImage: AssetImage('assets/images/pfp/${UserDataNotifier.instance.profilePicture}'),
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
                      IconButton(
                        icon: Icon(Icons.edit, color: mainColor),
                        onPressed: () {
                          showCustomInputDialog(
                            context: context,
                            title: 'Edit Profile',
                            fieldLabels: ['First Name', 'Last Name'],
                            initialValues: [
                              UserDataNotifier.instance.firstName,
                              UserDataNotifier.instance.lastName,
                            ],
                            onSave: (values) async {
                              // Validate that both fields are non-empty
                              if (values[0].trim().isEmpty || values[1].trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('First name and last name cannot be empty'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                // Update the UI immediately
                                setState(() {
                                  UserDataNotifier.instance.updateUserData(
                                    firstName: values[0].trim(),
                                    lastName: values[1].trim(),
                                  );
                                });

                                // Save to Hive
                                await UserDetails.saveToHive();

                                // Sync to Firebase
                                await UserDetails.updateInFirebase(
                                  newFirstName: values[0].trim(),
                                  newLastName: values[1].trim(),
                                );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update profile: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
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
            'Notification Settings',
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
          
          const SizedBox(height: 16),
          
          // Exercise Reminder Time
          _buildTimeSettingItem(
            'Exercise Reminder Time',
            'Set the time for exercise reminders',
            Icons.access_time,
            UserSettings.exerciseReminderTime,
            () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: UserSettings.exerciseReminderTime,
              );
              if (picked != null) {
                setState(() {
                  UserSettings.exerciseReminderTime = picked;
                });
                // Save to Hive
                await UserSettings.saveToHive();
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Streak Alert Toggle
          _buildSettingItem(
            'Streak Alert Notifications',
            'Get notified about your exercise streaks',
            Icons.local_fire_department,
            UserSettings.isStreakAlert,
            (value) {
              // Update setting and save
              UserSettings.isStreakAlert = value;
              UserSettings.saveToHive();
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Tutorials & Guidance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingItem(
            'Enable Guided Tutorials',
            'Show contextual tooltips and walkthroughs across assessments and recordings',
            Icons.help_outline,
            _tutorialsEnabled,
            (value) {
              _handleTutorialToggle(value);
            },
          ),

          const SizedBox(height: 16),

          _buildActionItem(
            'Replay Dashboard Tutorial',
            'Walk through the home dashboard tips again',
            Icons.play_circle_outline,
            () {
              _replayTutorialFlow(context, 'onboarding_dashboard');
            },
          ),

          const SizedBox(height: 12),

          _buildActionItem(
            'Reset All Tutorials',
            'Clear completion status and show tutorials on next visit',
            Icons.refresh,
            () {
              _resetAllTutorials(context);
            },
          ),
              ],
            ),
    );
  }
  
  Widget _buildPainDetectionSettingsSection() {
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
            'Pain Detection Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control when pain detection notifications appear during exercises and assessments',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Moderate Pain Banner Toggle
          _buildSettingItem(
            'Show Moderate Pain Banner',
            'Display notification when moderate pain is detected',
            Icons.info_outline,
            UserSettings.showModeratePainBanner,
            (value) {
              // Update setting and save
              UserSettings.showModeratePainBanner = value;
              UserSettings.saveToHive();
              UserSettings.saveToFirebase();
              setState(() {});
            },
          ),
          
          const SizedBox(height: 16),
          
          // Severe Pain Dialog Toggle
          _buildSettingItem(
            'Show Severe Pain Dialog',
            'Display dialog when severe pain is detected',
            Icons.warning,
            UserSettings.showSeverePainDialog,
            (value) {
              // Update setting and save
              UserSettings.showSeverePainDialog = value;
              UserSettings.saveToHive();
              UserSettings.saveToFirebase();
              setState(() {});
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

  Widget _buildTimeSettingItem(String title, String subtitle, IconData icon, TimeOfDay time, VoidCallback onTap) {
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
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit,
              color: mainColor,
              size: 20,
            ),
          ],
        ),
      ),
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
          
          // Logout/Exit Guest Mode
          _buildActionItem(
            isGuest ? 'Exit Guest Mode' : 'Logout',
            isGuest ? 'Return to login screen' : 'Sign out of your account',
            isGuest ? Icons.exit_to_app : Icons.logout,
            _handleLogout,
            isDestructive: true,
            key: TutorialAnchors.profileLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, VoidCallback onTap,
      {bool isDestructive = false, Key? key}) {
    return InkWell(
      key: key,
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
          return ResponsiveDialog(
            title: isGuest ? 'Exit Guest Mode' : 'Logout',
            icon: isGuest ? Icons.exit_to_app : Icons.logout,
            content: Text(
              isGuest 
                ? 'Are you sure you want to exit guest mode? Your progress will be saved locally.'
                : 'Are you sure you want to logout? All unsaved data will be saved automatically.',
              style: GoogleFonts.ptSans(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : kTextNormal,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: kTextNormal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kErrorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isGuest ? 'Exit' : 'Logout',
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

      if (shouldLogout != true) return;

      // Show loading indicator
      final isGuest = UserDetails.isGuest;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ResponsiveDialog(
            title: isGuest ? 'Exiting Guest Mode' : 'Logging Out',
            icon: Icons.hourglass_empty,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  isGuest 
                    ? 'Saving your progress...'
                    : 'Saving your data...',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white70 
                        : kTextNormal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: const [],
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
        
        // Clear all Hive data for next user
        try {
          if (Hive.isBoxOpen('rehabBox')) {
            await Hive.box('rehabBox').clear();
            debugPrint('ProfilePage: Cleared all Hive data on logout');
          }
        } catch (e) {
          debugPrint('ProfilePage: Error clearing Hive data: $e');
        }
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
        return ResponsiveDialog(
          title: 'Select Profile Picture',
          icon: Icons.person,
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
                        color: isSelected ? kMainColor : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: kMainColor.withOpacity(0.3),
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
              style: TextButton.styleFrom(
                foregroundColor: kTextNormal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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

  Widget _buildDataExportSection() {
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
            'Data & Export',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Export Exercise History',
            'Download your exercise data',
            Icons.upload_file,
            () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return ResponsiveDialog(
                    title: 'Exporting Report',
                    icon: Icons.hourglass_empty,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generating PDF report...',
                          style: GoogleFonts.ptSans(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : kTextNormal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actions: const [],
                  );
                },
              );

              // Export PDF
              final success = await PDFExportService.instance.exportPDFReport(context);

              // Close loading dialog
              if (mounted) Navigator.of(context).pop();

              // Success message is shown by the service
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to export PDF report'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Download Progress Report',
            'Get PDF/CSV reports of your progress',
            Icons.picture_as_pdf,
            () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return ResponsiveDialog(
                    title: 'Generating Report',
                    icon: Icons.hourglass_empty,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generating PDF report...',
                          style: GoogleFonts.ptSans(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : kTextNormal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actions: const [],
                  );
                },
              );

              // Export PDF
              final success = await PDFExportService.instance.exportPDFReport(context);

              // Close loading dialog
              if (mounted) Navigator.of(context).pop();

              // Success message is shown by the service
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to export PDF report'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSecuritySection() {
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
            'Security',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Change Password',
            'Update your account password',
            Icons.lock,
            () {
              // Check if user is in guest mode
              if (UserDetails.isGuest) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changes are not available for guest users'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              showCustomInputDialog(
                context: context,
                title: 'Change Password',
                fieldLabels: ['New Password', 'Confirm Password'],
                initialValues: ['', ''],
                onSave: (values) async {
                  // Validate that both fields are non-empty
                  if (values[0].isEmpty || values[1].isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in both fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validate minimum password length
                  if (values[0].length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters long'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validate password confirmation
                  if (values[0] != values[1]) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passwords do not match'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    // Update password in Firebase Auth
                    final user = _auth.currentUser;
                    if (user != null) {
                      await user.updatePassword(values[0]);
                    }

                    // Update password in local storage
                    setState(() {
                      UserDetails.password = values[0];
                    });

                    // Save to Hive
                    await UserDetails.saveToHive();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String errorMessage = 'Failed to update password';
                    switch (e.code) {
                      case 'weak-password':
                        errorMessage = 'Password is too weak';
                        break;
                      case 'requires-recent-login':
                        errorMessage = 'Please log in again before changing password';
                        break;
                      case 'network-request-failed':
                        errorMessage = 'Network error. Please check your connection';
                        break;
                      default:
                        errorMessage = 'Failed to update password: ${e.message}';
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('An unexpected error occurred: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Two-Factor Authentication',
            'Add extra security to your account',
            Icons.security,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
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
            'Legal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Terms of Service',
            'Read our terms and conditions',
            Icons.description,
            () {
              _showTermsDialog(
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
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Privacy Policy',
            'Learn how we protect your data',
            Icons.privacy_tip,
            () {
              _showTermsDialog(
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
              );
            },
          ),
        ],
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

  // ignore: unused_element
  Widget _buildPoseEstimationDemoSection() {
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
            'AI & Machine Learning',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Pose Estimation Demo',
            'Test the custom trained pose estimation model with real-time camera feed',
            Icons.psychology,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PoseEstimationDemo(),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildActionItem(
            'Model Information',
            'Learn about the pose estimation model and its capabilities',
            Icons.info_outline,
            () {
              _showModelInfoDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showModelInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveDialog(
          title: 'Pose Estimation Model',
          icon: Icons.psychology,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Custom Trained Model',
                style: GoogleFonts.ptSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This demo uses a custom-trained pose estimation model (pose_estimation_model.pt) that provides enhanced pose detection capabilities beyond standard ML Kit implementations.',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Features:',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              ...[
                '• Real-time pose detection with 17 keypoints',
                '• Enhanced accuracy for specific use cases',
                '• Customizable skeleton overlay visualization',
                '• Performance monitoring and FPS display',
                '• Confidence scoring for each keypoint',
              ].map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  feature,
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              )).toList(),
            ],
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