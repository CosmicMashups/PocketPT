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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      Container(
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
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: const AssetImage('assets/images/profile/profile.jpg'),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${UserDetails.firstName} ${UserDetails.lastName}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: mainColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              UserDetails.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: detailColor,
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
                                UserDetails.firstName,
                                UserDetails.lastName,
                                UserDetails.email,
                              ],
                              onSave: (values) async {
                                setState(() {
                                  UserDetails.firstName = values[0];
                                  UserDetails.lastName = values[1];
                                  UserDetails.email = values[2];
                                });

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
                    showReusableDialog(context, 'Terms of Service', [
                      'The information provided above is intended for general informational purposes only...',
                      'Please consult with a qualified healthcare provider before beginning any exercise regimen.',
                    ]);
                  },
                ),
                _buildActionTile(
                  'Privacy Policy',
                  'Learn how we protect your data',
                  Icons.privacy_tip,
                  () {
                    showReusableDialog(context, 'Privacy Policy', [
                      'The developers are committed to upholding the highest standards of data privacy...',
                      'All data collected will be used only for academic purposes...',
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
