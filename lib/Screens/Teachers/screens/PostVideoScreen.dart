import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../servcies.dart';

class PostVideoScreen extends StatefulWidget {
  const PostVideoScreen({super.key});

  @override
  State<PostVideoScreen> createState() => _PostVideoScreenState();
}

class _PostVideoScreenState extends State<PostVideoScreen> {
  // Data
  List<dynamic> subjects = [];
  List<dynamic> chapters = [];
  List<dynamic> batches = [];

  bool isLoadingSubjects = true;
  bool isLoadingChapters = false;
  bool isLoadingBatches = true;
  bool isSubmitting = false;

  dynamic selectedSubject;
  dynamic selectedChapter;
  dynamic selectedBatch; // Now SINGLE selection

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();

    fetchSubjects();
    fetchBatches();
  }

  @override
  void dispose() {
    SecureScreen.disable();

    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      final response = await http.get(
        Uri.parse('https://truescoreedu.com/api/get-subjects'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          subjects = json['data'] ?? [];
          isLoadingSubjects = false;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load subjects");
    } finally {
      setState(() => isLoadingSubjects = false);
    }
  }

  // Future<void> fetchChapters(String subjectId) async {
  //   setState(() {
  //     isLoadingChapters = true;
  //     selectedChapter = null;
  //     chapters.clear();
  //   });
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://truescoreedu.com/api/get-chapters'),
  //       body: {"subject_id": subjectId},
  //     );
  //     if (response.statusCode == 200) {
  //       final json = jsonDecode(response.body);
  //       setState(() {
  //         chapters = json['chapters'] ?? [];
  //         isLoadingChapters = false;
  //       });
  //     }
  //   } catch (e) {
  //     _showSnackBar("Failed to load chapters");
  //   } finally {
  //     setState(() => isLoadingChapters = false);
  //   }
  // }

  Future<void> fetchBatches() async {
    setState(() => isLoadingBatches = true);
    try {
      final response = await http.get(
        Uri.parse('https://truescoreedu.com/api/get-active-batches'),);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          batches = json['data'] ?? [];
          isLoadingBatches = false;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load batches");
    } finally {
      setState(() => isLoadingBatches = false);
    }
  }

  Future<void> _submitVideo() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar("Please enter video title");
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar("Please enter description");
      return;
    }
    if (selectedSubject == null) {
      _showSnackBar("Please select a subject");
      return;
    }
    // if (selectedChapter == null) {
    //   _showSnackBar("Please select a chapter");
    //   return;
    // }
    if (selectedBatch == null) {
      _showSnackBar("Please select a course");
      return;
    }
    if (_youtubeUrlController.text.trim().isEmpty) {
      _showSnackBar("Please enter YouTube URL");
      return;
    }

    setState(() => isSubmitting = true);

    final token = await _getToken();
    if (token == null) {
      _showSnackBar("Authentication failed");
      setState(() => isSubmitting = false);
      return;
    }

    try {
      Map data={ "apiToken": token,
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "subject": selectedSubject['id'].toString(),
        // "chapter": selectedChapter['id'].toString(),
        "batch": selectedBatch['id'].toString(), // Single batch
        "video_type": "youtube",
        "url": _youtubeUrlController.text.trim(),};
      print(data);
      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/add-teacher-video'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },

        body: data,
      );
      print(response.body);
      print(response.statusCode);

      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 1 || jsonData['success'] == true) {
        _showSnackBar("Video posted successfully!", Colors.green);
        Navigator.pop(context);
      } else {
        _showSnackBar(jsonData['message'] ?? "Failed to post video", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Network error: $e", Colors.red);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color ?? Colors.orange),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    dynamic value,
    required List items,
    required String Function(dynamic) displayText,
    required void Function(dynamic)? onChanged,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(displayText(item)));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (v) => v == null ? "$label is required" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Post YouTube Video", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Video Title *",
                  prefixIcon: const Icon(Icons.title),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: "Video Description *",
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),

              // Subject Dropdown
              isLoadingSubjects
                  ? const LinearProgressIndicator()
                  : _buildDropdown(
                label: "Select Subject *",
                icon: Icons.book,
                value: selectedSubject,
                items: subjects,
                displayText: (s) => s['subject_name'],
                onChanged: (val) {
                  setState(() => selectedSubject = val);
                  //if (val != null) fetchChapters(val['id'].toString());
                },
              ),
              const SizedBox(height: 20),

              // Chapter Dropdown
              // isLoadingChapters
              //     ? const LinearProgressIndicator()
              //     : _buildDropdown(
              //   label: "Select Chapter *",
              //   icon: Icons.menu_book,
              //   value: selectedChapter,
              //   items: chapters,
              //   displayText: (c) => c['name'],
              //   onChanged: (val) => setState(() => selectedChapter = val),
              //   enabled: selectedSubject != null,
              // ),
              const SizedBox(height: 20),

              // Single Batch/Course Dropdown
              isLoadingBatches
                  ? const LinearProgressIndicator()
                  : _buildDropdown(
                label: "Select Course *",
                icon: Icons.group,
                value: selectedBatch,
                items: batches,
                displayText: (b) => b['batch_name'],
                onChanged: (val) => setState(() => selectedBatch = val),
              ),

              const SizedBox(height: 30),

              // YouTube URL Field
              TextField(
                controller: _youtubeUrlController,
                decoration: InputDecoration(
                  labelText: "YouTube Video URL *",
                  hintText: "https://www.youtube.com/watch?v=...",
                  prefixIcon: const Icon(Icons.link, color: Colors.red),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              Text(
                "Only public or unlisted YouTube videos are supported",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Post Video", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}