import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateDoubtScreen extends StatefulWidget {
  const CreateDoubtScreen({super.key});

  @override
  State<CreateDoubtScreen> createState() => _CreateDoubtScreenState();

}

class _CreateDoubtScreenState extends State<CreateDoubtScreen>
    with TickerProviderStateMixin {
  // Loading states
  bool isLoadingSubjects = true;
  bool isLoadingTeachers = false;
  bool isLoadingChapters = false;
  bool isSubmitting = false;

  // Data lists
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> chapters = [];

  // Selected values
  Map<String, dynamic>? selectedSubject;
  Map<String, dynamic>? selectedTeacher;
  Map<String, dynamic>? selectedChapter;

  final descriptionController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchSubjects();

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
    descriptionController.dispose();
    super.dispose();
  }

  // Fetch Subjects
  Future<void> fetchSubjects()
  async {
    setState(() => isLoadingSubjects = true);
    try {
      final response = await http.get(
        Uri.parse('https://testora.codeeratech.in/api/get-subjects'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 1) {
          final List data = json['data'] ?? [];
          setState(() {
            subjects = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {

      _showSnackBar("Failed to load subjects", isError: true);

    } finally {

      setState(() => isLoadingSubjects = false);

    }
  }

  // When Subject is Selected → Load Teachers & Chapters
  void onSubjectChanged(dynamic value) async {
    if (value == null) return;

    final Map<String, dynamic> subject = value as Map<String, dynamic>;

    setState(() {
      selectedSubject = subject;
      selectedTeacher = null;
      selectedChapter = null;
      teachers.clear();
      chapters.clear();
    });

    final String subjectId = subject['id'].toString();

    // Load both teachers and chapters in parallel
    await Future.wait([
      fetchTeachers(subjectId),
      //fetchChapters(subjectId),
    ]);
  }

  // Fetch Teachers
  Future<void> fetchTeachers(String subjectId) async {
    setState(() => isLoadingTeachers = true
    );
    try {
      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/get-teachers'),
        body: {"subject_id": subjectId},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 1) {
          final List data = json['data'] ?? [];
          setState(() {
            teachers = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      _showSnackBar("Failed to load teachers", isError: true);
    } finally {
      setState(() => isLoadingTeachers = false);
    }
  }

  // Fetch Chapters
  // Future<void> fetchChapters(String subjectId) async {
  //   setState(() => isLoadingChapters = true);
  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://testora.codeeratech.in/api/get-chapters'),
  //       body: {"subject_id": subjectId},
  //     );
  //     if (response.statusCode == 200) {
  //       final json = jsonDecode(response.body);
  //       if (json['status'] == 1) {
  //         final List data = json['chapters'] ?? [];
  //         setState(() {
  //           chapters = data.cast<Map<String, dynamic>>();
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     _showSnackBar("Failed to load chapters", isError: true);
  //   } finally {
  //     setState(() => isLoadingChapters = false);
  //   }
  // }

  // Submit Doubt
  Future<void> submitDoubt() async {
    if (selectedSubject == null ||
        selectedTeacher == null ||
        descriptionController.text.trim().isEmpty) {
      _showSnackBar("Please fill all required fields", isError: true);
      return;
    }

    setState(() => isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final Map<String, String> body = {
        "apiToken": token,
        "subject_id": selectedSubject!['id'].toString(),
        "teacher_id": selectedTeacher!['teacher_id'].toString(),
        "description": descriptionController.text.trim(),
        // "chapter_id": "4",
      };
      print(body);

      // if (selectedChapter != null) {
      //   body["chapter_id"] = selectedChapter!['id'].toString();
      // }

      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/add-doubt'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );

      final json = jsonDecode(response.body);
      print(json);
      if (response.statusCode == 200 && json['status'] == 1) {
        _showSnackBar("Doubt submitted successfully!", isError: false);
        //Navigator.pop(context);
      } else {
        _showSnackBar(json['msg'] ?? "Failed to submit doubt", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error. Please try again.", isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text("Raise a Doubt",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.shade300, blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.help_outline, size: 60, color: Colors.white),
                    SizedBox(height: 12),
                    Text("Ask Your Doubt",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Get help from expert teachers",
                        style: TextStyle(fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    // Subject Dropdown
                    isLoadingSubjects
                        ? const LinearProgressIndicator(color: Colors.blue)
                        : _buildDropdown(
                      value: selectedSubject,
                      items: subjects,
                      itemBuilder: (s) => s['subject_name'] ?? 'Unknown Subject',
                      onChanged: onSubjectChanged,
                      label: "Select Subject *",
                      icon: Icons.book,
                    ),
                    const SizedBox(height: 20),

                    // Teacher Dropdown
                    isLoadingTeachers
                        ? const LinearProgressIndicator(color: Colors.blue)
                        : _buildDropdown(
                      value: selectedTeacher,
                      items: teachers,
                      itemBuilder: (t) => t['name'] ?? 'Unknown Teacher',
                      onChanged: (dynamic val) {
                        if (val != null) {
                          setState(() => selectedTeacher = val as Map<String, dynamic>);
                        }
                      },
                      label: "Select Teacher *",
                      icon: Icons.person,
                      enabled: selectedSubject != null && teachers.isNotEmpty,
                    ),
                    const SizedBox(height: 20),

                    // Chapter Dropdown (Optional)
                    // isLoadingChapters
                    //     ? const LinearProgressIndicator(color: Colors.blue)
                    //     : _buildDropdown(
                    //   value: selectedChapter,
                    //   items: chapters,
                    //   itemBuilder: (c) => c['name'] ?? 'Unknown Chapter',
                    //   onChanged: (dynamic val) {
                    //     if (val != null) {
                    //       setState(() => selectedChapter = val as Map<String, dynamic>);
                    //     }
                    //   },
                    //   label: "Select Chapter (Optional)",
                    //   icon: Icons.menu_book,
                    //   enabled: selectedSubject != null && chapters.isNotEmpty,
                    // ),
                    // const SizedBox(height: 25),

                    // Description Field
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: "Describe your doubt *",
                        hintText: "Explain clearly what you don't understand...",
                        prefixIcon: const Icon(Icons.edit, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue, width: 2)),
                      ),
                      validator: (v) => v!.trim().isEmpty ? "Please describe your doubt" : null,
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submitDoubt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Submit Doubt",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable Modern Dropdown
  Widget _buildDropdown({
    dynamic value,
    required List items,
    required String Function(dynamic) itemBuilder,
    required void Function(dynamic)? onChanged,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue, width: 2)),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(itemBuilder(item)));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: label.contains('*')
          ? (v) => v == null ? "This field is required" : null
          : null,
    );
  }
}