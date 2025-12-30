import 'package:flutter/material.dart';

import '../../ThemeConstent/themeData.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, String>> notifications = [
    {
      "title": "Course Enrolled",
      "message": "You've successfully enrolled in SSC CGL Course.",
      "time": "2h ago"
    },
    {
      "title": "New Test Available",
      "message": "A new mock test has been uploaded in your course.",
      "time": "5h ago"
    },
    {
      "title": "Reminder",
      "message": "Your live class starts at 6 PM today.",
      "time": "Today"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: AppTheme.primeryColor,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[400]),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Colors.white,
            leading: CircleAvatar(
              backgroundColor: AppTheme.primeryColor,
              child: Icon(Icons.notifications, color: Colors.white),
            ),
            title: Text(
              notification["title"] ?? "",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(notification["message"] ?? ""),
            trailing: Text(
              notification["time"] ?? "",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          );
        },
      ),
    );
  }
}
