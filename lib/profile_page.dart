// Import packages
import 'package:flutter/material.dart';
import 'assessment/globals.dart';
import 'welcome/login_page.dart';
import 'functions.dart';

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
        title: Text('Profile'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('../../assets/images/profile/profile.jpg'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${UserDetails.firstName.toUpperCase()} ${UserDetails.lastName.toUpperCase()}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(UserDetails.email),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        UserProgress.title,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
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

          SizedBox(height: 24),

          // Notification Settings
          Text('Notification Settings', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            value: true,
            onChanged: (val) {},
            title: Text('Daily Exercise Reminders'),
          ),
          SwitchListTile(
            value: true,
            onChanged: (val) {},
            title: Text('Streak Alert Notifications'),
          ),

          Divider(height: 32),

          // Data & Export
          Text('Data & Export', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('Export Exercise History'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Download Progress Report (PDF/CSV)'),
            onTap: () {},
          ),

          Divider(height: 32),

          // Security
          Text('Security', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            onTap: () {
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
            },
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Two-Factor Authentication'),
            onTap: () {},
          ),

          Divider(height: 32),

          // Legal
          Text('Legal', style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Terms of Service'),
            onTap: () {
              showReusableDialog(context, 'Terms of Service', [
                'The information provided above is intended for general informational purposes only and should not be considered as a substitute for professional medical advice, diagnosis, or treatment.',
                'It is crucial that you consult with a qualified healthcare provider before beginning any new exercise regimen.',
                'Your health and safety are of the utmost importance, and professional guidance ensures appropriate choices.',
                'By using this application, you acknowledge and agree that the developers are not responsible for any injuries or complications that may arise.',
              ]);
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            onTap: () {
              showReusableDialog(context, 'Privacy Policy', [
                'The developers are committed to upholding the highest standards of data privacy, security, and ethical conduct in the development and implementation of this academic research project.',
                'All information collected throughout the phases of data gathering, model development, and system evaluation shall be strictly utilized for academic purposes within the defined scope of the study. At no point shall any data be disclosed, shared, or used beyond the objectives of this research.',
                'The developers fully recognize that some of the data collected may contain personal, sensitive, or confidential information. As such, they commit to full compliance with the provisions of Republic Act No. 10173, also known as the Data Privacy Act of 2012. This includes the lawful collection, handling, processing, storage, and disposal of personal data.',
                'Appropriate technical, administrative, and organizational measures will be employed to protect the confidentiality, integrity, and security of all collected data. These measures aim to prevent unauthorized access, misuse, or data breaches at every stage of the research.',
                'This policy affirms the developers’ responsibility to safeguard the rights and privacy of all individuals involved and to maintain the trust and confidence of all stakeholders participating in the study.',
              ]);
            },
          ),

          Divider(height: 32),

          // Logout
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
          )
        ],
      ),
    );
  }
}