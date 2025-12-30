import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TeacherDoubtsScreen extends StatefulWidget {
  const TeacherDoubtsScreen({super.key});

  @override
  State<TeacherDoubtsScreen> createState() => _TeacherDoubtsScreenState();
}

class _TeacherDoubtsScreenState extends State<TeacherDoubtsScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  bool isSubmitting = false;
  List<Map<String, dynamic>> doubts = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchTeacherDoubts();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Fetch doubts assigned to teacher
  Future<void> fetchTeacherDoubts() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      _showSnackBar("Session expired. Please login again.", isError: true);
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/get-teacher-doubts'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": token},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print(json);
        if (json['status'] == 1) {
          final List data = json['data'] ?? [];
          setState(() {
            doubts = data.cast<Map<String, dynamic>>();
          });
        } else {
          _showSnackBar(json['msg'] ?? "No doubts found", isError: false);
        }
      }
    } catch (e) {
      _showSnackBar("Network error. Please try again.", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Teacher replies to a doubt
  Future<void> replyToDoubt(String doubtId, String reply) async {
    if (reply.trim().isEmpty) {
      _showSnackBar("Please write a reply", isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/update-teacher-doubts'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "apiToken": token,
          "doubt_id": doubtId,
          "description": reply.trim(),
        },
      );

      final json = jsonDecode(response.body);
      print(json);
      print(response.statusCode);

      if (response.statusCode == 200 && json['status'] == 1) {
        _showSnackBar("Reply submitted successfully!", isError: false);
        fetchTeacherDoubts(); // Refresh list
      } else {
        _showSnackBar(json['msg'] ?? "Failed to submit reply", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error. Try again.", isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showReplyDialog(Map<String, dynamic> doubt) {
    final TextEditingController replyController = TextEditingController();
    replyController.text = doubt['teacher_description'] ?? '';
    String value="";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reply to Student", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: replyController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: "Write your explanation here...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () {
              Navigator.pop(context);
              replyToDoubt(doubt['doubt_id'].toString(), replyController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text("Submit Reply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) => status == "0" ? "Pending" : "Resolved";
  Color _getStatusColor(String status) => status == "0" ? Colors.orange : Colors.green;

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text("Student Doubts",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: fetchTeacherDoubts,
          color: Colors.blue.shade700,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : doubts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doubts.length,
            itemBuilder: (context, index) {
              final doubt = doubts[index];
              final subject = doubt['subject'] ?? {};
              final student = doubt['student'] ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 6,
                shadowColor: Colors.blue.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student & Subject
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "From: ${student['name'] ?? 'Unknown Student'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Subject: ${subject['name'] ?? 'Unknown'}",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(doubt['status'] ?? '0').withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _getStatusColor(doubt['status'] ?? '0')),
                            ),
                            child: Text(
                              _getStatusText(doubt['status'] ?? '0'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(doubt['status'] ?? '0'),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      // Student's Doubt
                      const Text("Student's Doubt:", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(doubt['description'] ?? 'No description'),

                      const SizedBox(height: 16),

                      // Teacher's Current Reply (if any)
                      if ((doubt['teacher_description'] ?? '').isNotEmpty) ...[
                        const Text("Your Reply:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                        const SizedBox(height: 8),
                        Text(doubt['teacher_description'], style: const TextStyle(fontStyle: FontStyle.italic)),
                        const SizedBox(height: 16),
                      ],

                      // Reply Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _showReplyDialog(doubt),
                          icon: const Icon(Icons.reply, size: 18),
                          label: Text(doubt['teacher_description'].toString().isEmpty ? "Reply" : "Update Reply",style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            "No student doubts yet",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Text(
            "Doubts raised by students will appear here",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}