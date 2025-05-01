// Import packages
import 'package:flutter/material.dart';
import '../data/globals.dart';
import '../welcome/login_page.dart';
import '../data/functions.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF8B2E2E), // Main color for AppBar
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Add settings page navigation if necessary
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Header with Custom Styling
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/profile/profile.jpg'),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${UserDetails.firstName.toUpperCase()} ${UserDetails.lastName.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B2E2E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          UserDetails.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF8B2E2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            UserProgress.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Color(0xFF8B2E2E)),
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
                        onSave: (values) {
                          setState(() {
                            UserDetails.firstName = values[0];
                            UserDetails.lastName = values[1];
                            UserDetails.email = values[2];
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('User details updated successfully')),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Notification Settings with Custom Styling
          _buildSectionTitle('Notification Settings'),
          _buildSwitchListTile(
            'Daily Exercise Reminders',
            UserSettings.isDailyReminder,
            (val) {
              setState(() {
                UserSettings.isDailyReminder = val;
              });
            },
          ),
          _buildSwitchListTile(
            'Streak Alert Notifications',
            UserSettings.isStreakAlert,
            (val) {
              setState(() {
                UserSettings.isStreakAlert = val;
              });
            },
          ),

          Divider(height: 32),

          // Data & Export Section
          _buildSectionTitle('Data & Export'),
          _buildListTile(Icons.upload_file, 'Export Exercise History'),
          _buildListTile(Icons.picture_as_pdf, 'Download Progress Report (PDF/CSV)'),

          Divider(height: 32),

          // Security Section
          _buildSectionTitle('Security'),
          _buildListTile(Icons.lock, 'Change Password', onTap: () {
            showCustomInputDialog(
              context: context,
              title: 'Change Password',
              fieldLabels: ['New Password', 'Confirm Password'],
              initialValues: ['', ''],
              onSave: (values) {
                if (values[0].isEmpty || values[1].isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in both fields')),
                  );
                  return;
                }

                if (values[0] != values[1]) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }

                setState(() {
                  UserDetails.password = values[0];
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password updated successfully')),
                );
              },
            );
          }),
          _buildListTile(Icons.security, 'Two-Factor Authentication'),

          Divider(height: 32),

          // Legal Section
          _buildSectionTitle('Legal'),
          _buildListTile(Icons.description, 'Terms of Service', onTap: () {
            showReusableDialog(context, 'Terms of Service', [
              'The information provided above is intended for general informational purposes only...',
              'Please consult with a qualified healthcare provider before beginning any exercise regimen.',
            ]);
          }),
          _buildListTile(Icons.privacy_tip, 'Privacy Policy', onTap: () {
            showReusableDialog(context, 'Privacy Policy', [
              'The developers are committed to upholding the highest standards of data privacy...',
              'All data collected will be used only for academic purposes...',
            ]);
          }),

          Divider(height: 32),

          // Logout Section
          Center(
            child: TextButton.icon(
              icon: Icon(Icons.logout, color: Colors.red),
              label: Text('Log Out', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B2E2E),
      ),
    );
  }

  Widget _buildSwitchListTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      activeColor: Color(0xFFC1574F),
      inactiveThumbColor: Color(0xFF8B2E2E),
      inactiveTrackColor: Color(0xFF8B2E2E).withOpacity(0.3),
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF8B2E2E),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {Function()? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF8B2E2E)),
      title: Text(title),
      onTap: onTap,
    );
  }
}
