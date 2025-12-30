import 'package:flutter/material.dart';

import '../../../ThemeConstent/themeData.dart';

class TeacherProfile extends StatefulWidget {
  const TeacherProfile({super.key});

  @override
  State<TeacherProfile> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfile> {
  final TextEditingController _nameController =
  TextEditingController(text: "Mr. Rahul Sharma");
  final TextEditingController _phoneController =
  TextEditingController(text: "+91 9876543210");
  final TextEditingController _subjectController =
  TextEditingController(text: "Mathematics");

  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Teacher Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile Updated")),
                );
              }
              _toggleEdit();
            },
          )
        ],
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Material(
              elevation: 10,
              shape: const CircleBorder(), // ✅ Use CircleBorder instead of BoxShape.circle
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage("assets/images/bg.png"),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow("Name", _nameController, Icons.person),
                    const SizedBox(height: 10),
                    _buildRow("Subject", _subjectController, Icons.book),
                    const SizedBox(height: 10),
                    _buildRow("Phone", _phoneController, Icons.phone),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, TextEditingController controller, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(width: 10),
        Expanded(
          child: _isEditing
              ? TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(controller.text,
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
