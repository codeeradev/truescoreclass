import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class getclassscreen extends StatefulWidget {
  const getclassscreen({super.key});

  @override
  State<getclassscreen> createState() => _getclassscreenState();
}

class _getclassscreenState extends State<getclassscreen> {
  List<dynamic> liveClasses = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchLiveClasses();
  }

  Future<void> fetchLiveClasses() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception("Token not found");
      }

      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/get-live-class'),
        body: {"apiToken": token},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 1) {
          setState(() {
            liveClasses = jsonData['data'] ?? [];
          });
        } else {
          throw Exception(jsonData['msg'] ?? "Failed to fetch classes");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => hasError = true);
      debugPrint("Error fetching live classes: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load live classes: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Open Google Meet Link
  Future<void> _openMeeting(String meetingLink) async {
    final Uri url = Uri.parse(meetingLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open meeting link")),
      );
    }
  }

  // Format Date & Time
  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('EEEE, dd MMMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  String formatTime(String time) {
    try {
      final format = DateFormat('HH:mm:ss');
      final parsedTime = format.parse(time);
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.green;
      case 'upcoming':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Classes", style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchLiveClasses,
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: fetchLiveClasses,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError && liveClasses.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("Failed to load classes", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: fetchLiveClasses,
                child: const Text("Retry"),
              ),
            ],
          ),
        )
            : liveClasses.isEmpty
            ? const Center(
          child: Text(
            "No live classes available",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )

            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: liveClasses.length,
          itemBuilder: (context, index) {
            final cls = liveClasses[index];
            final meetingLink = cls['meeting_link']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cls['title'] ?? "Untitled Class",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(cls['class_status'] ?? '').withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (cls['class_status'] ?? "Scheduled").toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(cls['class_status'] ?? ''),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Batch & Subject
                    Row(
                      children: [
                        const Icon(Icons.group, size: 20, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cls['batch']?['name'] ?? "Unknown Batch",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.book, size: 20, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cls['subject']?['name'] ?? "Unknown Subject",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),

                    if (cls['chapter'] != null && cls['chapter']['name'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.menu_book, size: 20, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cls['chapter']['name'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 24),

                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blueGrey),
                        const SizedBox(width: 10),
                        Text(
                          formatDate(cls['date'] ?? ""),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blueGrey),
                        const SizedBox(width: 10),
                        Text(
                          "${formatTime(cls['start_time'] ?? "")} - ${formatTime(cls['end_time'] ?? "")}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Join Button (Only if meeting link exists)
                    if (meetingLink.isNotEmpty && meetingLink.startsWith("http"))
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openMeeting(meetingLink),
                          icon: const Icon(Icons.video_call),
                          label: const Text("Join Google Meet"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
    );
  }
}