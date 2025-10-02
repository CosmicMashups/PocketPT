// Import packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/globals.dart';
import '../welcome/login_page.dart';
import '../data/functions.dart';
import '../data/data_management_widget.dart';
import '../data/data_persistence_service.dart';
import '../data/auth_persistence_service.dart';
import '../data/theme_controller.dart';
import '../data/user_data_notifier.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Muscular maroon
  static const subColor = Color(0xFFC24A4A); // Lighter maroon
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background
  static const successColor = Color(0xFF10B981); // Green
  static const warningColor = Color(0xFFF59E0B); // Orange
  static const errorColor = Color(0xFFEF4444); // Red

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  void initState() {
    super.initState();
    // Initialize the notifier with current data
    UserDataNotifier.instance.initialize();
  }

  // Handle logout with proper data saving and Firebase sign out
  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout? All unsaved data will be saved automatically.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout', style: TextStyle(color: Colors.red)),
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

      // Save all data to Hive before logout
      await DataPersistenceService.instance.forceSave(reason: 'User logout');

      // Use authentication persistence service for logout
      await AuthPersistenceService.instance.onUserLoggedOut();
      
      // Sign out from Firebase
      await _auth.signOut();

      // Clear any cached data if needed
      // Note: We keep Hive data for when user logs back in

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: UserDataNotifier.instance,
      builder: (context, child) {
        return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: mainColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                mainColor,
                subColor,
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildThemeToggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Professional Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                    isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF0F9FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
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
                                  decoration: BoxDecoration(
                                    color: mainColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.edit,
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
                            Flexible(
                              child: UserDataNotifier.instance.isLoading
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Loading...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: detailColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '${UserDataNotifier.instance.firstName} ${UserDataNotifier.instance.lastName}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: mainColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: UserDataNotifier.instance.isLoading
                                  ? Text(
                                      'Loading email...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: detailColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : Text(
                                      UserDataNotifier.instance.email,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: detailColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: mainColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: mainColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: warningColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    UserProgress.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: mainColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: mainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.edit, color: mainColor, size: 24),
                          onPressed: () {
                            showCustomInputDialog(
                              context: context,
                              title: 'Edit Profile',
                              fieldLabels: ['First Name', 'Last Name', 'Email'],
                              initialValues: [
                                UserDataNotifier.instance.firstName,
                                UserDataNotifier.instance.lastName,
                                UserDataNotifier.instance.email,
                              ],
                              onSave: (values) async {
                                // Update through the notifier
                                UserDataNotifier.instance.updateUserData(
                                  firstName: values[0],
                                  lastName: values[1],
                                  email: values[2],
                                );

                                // Save to Hive
                                await UserDetails.saveToHive();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('User details updated successfully'),
                                    backgroundColor: successColor,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Settings Section
            _buildSettingsSection(
              title: 'Notification Settings',
              icon: Icons.notifications_outlined,
              children: [
                _buildSwitchListTile(
                  'Daily Exercise Reminders',
                  'Get notified to complete your daily exercises',
                  Icons.fitness_center,
                  UserSettings.isExerciseReminder,
                  (val) async {
                    setState(() {
                      UserSettings.isExerciseReminder = val;
                    });
                    await UserSettings.saveToHive();
                  },
                ),
                _buildTimePickerTile(
                  'Exercise Reminder Time',
                  'Set when you want to be reminded',
                  Icons.access_time,
                  UserSettings.exerciseReminderTime,
                  (picked) async {
                    if (picked != null) {
                      setState(() {
                        UserSettings.exerciseReminderTime = picked;
                      });
                      await UserSettings.saveToHive();
                    }
                  },
                ),
                _buildSwitchListTile(
                  'Streak Alert Notifications',
                  'Celebrate your exercise streaks',
                  Icons.local_fire_department,
                  UserSettings.isStreakAlert,
                  (val) async {
                    setState(() {
                      UserSettings.isStreakAlert = val;
                    });
                    await UserSettings.saveToHive();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Management Section
            _buildSettingsSection(
              title: 'Data Management',
              icon: Icons.storage,
              children: [
                const DataManagementWidget(),
              ],
            ),

            const SizedBox(height: 24),

            // Data & Export Section
            _buildSettingsSection(
              title: 'Data & Export',
              icon: Icons.download,
              children: [
                _buildActionTile(
                  'Export Exercise History',
                  'Download your complete exercise data',
                  Icons.upload_file,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export feature coming soon'),
                        backgroundColor: warningColor,
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  'Download Progress Report',
                  'Generate PDF/CSV reports of your progress',
                  Icons.picture_as_pdf,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report generation coming soon'),
                        backgroundColor: warningColor,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Security Section
            _buildSettingsSection(
              title: 'Security',
              icon: Icons.security,
              children: [
                _buildActionTile(
                  'Change Password',
                  'Update your account password',
                  Icons.lock,
                  () {
                    showCustomInputDialog(
                      context: context,
                      title: 'Change Password',
                      fieldLabels: ['New Password', 'Confirm Password'],
                      initialValues: ['', ''],
                      onSave: (values) async {
                        if (values[0].isEmpty || values[1].isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please fill in both fields'),
                              backgroundColor: errorColor,
                            ),
                          );
                          return;
                        }

                        if (values[0] != values[1]) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Passwords do not match'),
                              backgroundColor: errorColor,
                            ),
                          );
                          return;
                        }

                        setState(() {
                          UserDetails.password = values[0];
                        });

                        await UserDetails.saveToHive();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password updated successfully'),
                            backgroundColor: successColor,
                          ),
                        );
                      },
                    );
                  },
                ),
                _buildActionTile(
                  'Two-Factor Authentication',
                  'Add an extra layer of security',
                  Icons.security,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('2FA feature coming soon'),
                        backgroundColor: warningColor,
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Legal Section
            _buildSettingsSection(
              title: 'Legal & Support',
              icon: Icons.description,
              children: [
                _buildActionTile(
                  'Terms of Service',
                  'Read our terms and conditions',
                  Icons.description,
                  () {
                    showReusableDialog(context,
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
                      ]);
                  },
                ),
                _buildActionTile(
                  'Privacy Policy',
                  'Learn how we protect your data',
                  Icons.privacy_tip,
                  () {
                    showReusableDialog(context,
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
                      ]);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    errorColor,
                    const Color(0xFFDC2626),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: errorColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.light_mode, color: Colors.white, size: 18),
          Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (isDark) async {
              final mode = isDark ? ThemeMode.dark : ThemeMode.light;
              await ThemeController.instance.setThemeMode(mode);
              setState(() {});
            },
            activeColor: Colors.white,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white38,
          ),
          const Icon(Icons.dark_mode, color: Colors.white, size: 18),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchListTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: mainColor, size: 20),
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
                    color: mainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: detailColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: successColor,
            inactiveThumbColor: detailColor,
            inactiveTrackColor: detailColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(
    String title,
    String subtitle,
    IconData icon,
    TimeOfDay time,
    Function(TimeOfDay?) onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: time,
          );
          onChanged(picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: mainColor, size: 20),
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
                      color: mainColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: detailColor,
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
            Icon(Icons.arrow_forward_ios, color: detailColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Function() onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: mainColor, size: 20),
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
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: detailColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
