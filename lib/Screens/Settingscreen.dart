import 'package:flutter/material.dart';
import 'package:online_classes/ThemeConstent/themeData.dart';

class ProfileSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text('Profile Settings'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/s1.png'),
                ),
              ),
              SizedBox(height: 16),

              // Name
              Text(
                'Rishumaan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              // Email
              SizedBox(height: 8),
              Text(
                'sdsad@gmail.com',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              SizedBox(height: 24),

              // Subscription Section
              Card(color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.subscriptions, color: Colors.blueAccent),
                  title: Text('Subscription Status'),
                  subtitle: Text('Active - Premium Plan'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to subscription details
                  },
                ),
              ),

              SizedBox(height: 16),

              // Purchased Courses
              Card(
                color:
                Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.school, color: Colors.green),
                  title: Text('Purchased Courses'),
                  subtitle: Text('5 courses purchased'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to purchased courses list
                  },
                ),
              ),

              SizedBox(height: 16),

              // App Settings
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.lock, color: Colors.blueAccent),
                      title: Text('Change Password'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to change password screen
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.notifications, color: Colors.blueAccent),
                      title: Text('Notification Settings'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to notification settings
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Logout'),
                      onTap: () {
                        // Perform logout
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
