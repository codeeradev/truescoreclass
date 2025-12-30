import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ADDdoubtsbystudents.dart';

class MyDoubtsScreen extends StatefulWidget {
  const MyDoubtsScreen({super.key});

  @override
  State<MyDoubtsScreen> createState() => _MyDoubtsScreenState();
}

class _MyDoubtsScreenState extends State<MyDoubtsScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  List<Map<String, dynamic>> doubts = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchDoubts();

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

  Future<void> fetchDoubts() async {
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
        Uri.parse('https://testora.codeeratech.in/api/get-doubts'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": token},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 1) {
          final List data = json['data'] ?? [];
          setState(() {
            doubts = data.cast<Map<String, dynamic>>();
          });
        } else {
          _showSnackBar(json['msg'] ?? "Failed to load doubts", isError: true);
        }
      } else {
        _showSnackBar("Server error. Please try again.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error. Check your connection.", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String date) {
    if (date == "30-11--0001" || date.isEmpty || date.contains("--0001")) {
      return "Not Scheduled";
    }
    // You can format properly if real date comes later
    return date;
  }

  String _getStatusText(String status) {
    return status == "0" ? "Pending" : "Resolved";
  }

  Color _getStatusColor(String status) {
    return status == "0" ? Colors.orange : Colors.green;
  }

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
        title: const Text("My Doubts",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: fetchDoubts,
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
              final teacher = doubt['teacher'] ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 6,
                shadowColor: Colors.blue.shade100,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        doubt['description'] ?? 'No description',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // Details Row
                      Row(
                        children: [
                          const Icon(Icons.book, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Subject: ${subject['name'] ?? 'Unknown'}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Teacher: ${teacher['name'] ?? 'Not Assigned'}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Row(
                      //   children: [
                      //     const Icon(Icons.schedule, size: 18, color: Colors.blue),
                      //     const SizedBox(width: 8),
                      //     Text(
                      //       "Appointment: ${_formatDate(doubt['appointment_date'] ?? '')}",
                      //       style: const TextStyle(fontSize: 14),
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 16),

                      // Status Badge
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(doubt['status'] ?? '0')
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _getStatusColor(doubt['status'] ?? '0')),
                          ),
                          child: Text(
                            _getStatusText(doubt['status'] ?? '0'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(doubt['status'] ?? '0'),
                            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateDoubtScreen()),
          ).then((_) => fetchDoubts()); // Refresh after adding new doubt
        },
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            "No doubts raised yet",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap the + button to ask a doubt",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}