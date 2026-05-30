import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Keep if needed elsewhere
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class CreateLiveClassScreen extends StatefulWidget {
  const CreateLiveClassScreen({super.key});

  @override
  State<CreateLiveClassScreen> createState() => _CreateLiveClassScreenState();
}

class _CreateLiveClassScreenState extends State<CreateLiveClassScreen> {
  // Data
  List<dynamic> batches = [];
  List<dynamic> subjects = [];
  List<dynamic> chapters = [];

  dynamic selectedBatch;
  dynamic selectedSubject;
  dynamic selectedChapter;

  bool isLoadingBatches = false;
  bool isLoadingSubjects = false;
  bool isLoadingChapters = false;
  bool isCreating = false;

  // Controllers
  final titleController = TextEditingController();
  final linkController = TextEditingController();
  final dateController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchBatches();
    fetchSubjects();
  }

  // Fetch Batches
  Future<void> fetchBatches() async {
    setState(() => isLoadingBatches = true);
    try {
      final res = await http.get(
        Uri.parse('https://truescoreedu.com/api/get-active-batches'),);
      final json = jsonDecode(res.body);
      batches = json['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching batches: $e');
    }
    setState(() => isLoadingBatches = false);
  }

  // Fetch Subjects
  Future<void> fetchSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      final res = await http.get(
        Uri.parse('https://truescoreedu.com/api/get-subjects'),
      );
      final json = jsonDecode(res.body);
      subjects = json['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    }
    setState(() => isLoadingSubjects = false);
  }

  // Fetch Chapters
  Future<void> fetchChapters(String subjectId) async {
    setState(() {
      isLoadingChapters = true;
      chapters.clear();
      selectedChapter = null;
    });
    try {
      final res = await http.post(
        Uri.parse('https://truescoreedu.com/api/get-chapters'),
        body: {"subject_id": subjectId},
      );
      final json = jsonDecode(res.body);
      chapters = json['chapters'] ?? [];
    } catch (e) {
      debugPrint('Error fetching chapters: $e');
    }
    setState(() => isLoadingChapters = false);
  }

  // Create Class
  Future<void> createClass() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedBatch == null || selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Batch and Subject")),
      );
      return;
    }

    setState(() => isCreating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    print('token$token');

    final body = {
      "apiToken": token,
      "batch_id": selectedBatch['id'].toString(),
      "subject_id": selectedSubject['id'].toString(),
      "chapter_id": selectedChapter?['id']?.toString() ?? "0",
      "title": titleController.text.trim(),
      "meeting_link": linkController.text.trim(),
      "start_time": startTimeController.text,
      "end_time": endTimeController.text,
      "date": dateController.text,
      "type_class": '2',
    };

    try {
      final res = await http.post(
        Uri.parse("https://truescoreedu.com/api/save-live-class"),
        body: body,
      );
      final data = jsonDecode(res.body);
      print(data);
      print(res.body);
      print(res.statusCode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Live class created successfully!")),
      );

      if (data['status'] == true || data['success'] == true) {
        Navigator.pop(context); // Go back on success
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create class. Please try again.")),
      );
    } finally {
      setState(() => isCreating = false);
    }
  }

  // Date Picker
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.blue.shade700),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Time Picker
  Future<void> pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      controller.text = "$hour:$minute:00";
    }
  }

  // Reusable Input Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  // Reusable Dropdown (Modern Style)
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    dynamic value,
    required List<dynamic> items,
    required String Function(dynamic) itemBuilder,
    required void Function(dynamic)? onChanged,
    bool isLoading = false,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: items.contains(value) ? value : null,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),

      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            itemBuilder(item),
            maxLines: 1, // 🔥 FIX
            overflow: TextOverflow.ellipsis, // 🔥 FIX
            softWrap: false,
            style: const TextStyle(fontSize: 15),
          ),
        );
      }).toList(),

      /// 🔥 IMPORTANT FIX
      selectedItemBuilder: (context) {
        return items.map<Widget>((item) {
          return Text(
            itemBuilder(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          );
        }).toList();
      },

      onChanged: onChanged,

      validator: (v) => v == null ? "Required" : null,

      icon: isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.keyboard_arrow_down, color: Colors.grey),

      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Live Class",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {}, // Add help/info if needed
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card / Info
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.video_camera_front, size: 40, color: Colors.blue.shade700),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Schedule a New Live Session",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Google Meet • Fill all required fields",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Form Fields in Cards
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDropdown(
                        label: "Select Batch",
                        icon: Icons.group,
                        value: selectedBatch,
                        items: batches,
                        itemBuilder: (item) => item['batch_name']?.toString() ?? "Unnamed Batch",
                        onChanged: (val) => setState(() => selectedBatch = val),
                        isLoading: isLoadingBatches,
                      ),
                      const SizedBox(height: 20),

                      _buildDropdown(
                        label: "Select Subject",
                        icon: Icons.book,
                        value: selectedSubject,
                        items: subjects,
                        itemBuilder: (item) => item['subject_name']?.toString() ?? "",
                        onChanged: (val) {
                          setState(() => selectedSubject = val);
                          if (val != null) fetchChapters(val['id'].toString());
                        },
                        isLoading: isLoadingSubjects,
                      ),
                      const SizedBox(height: 20),

                      _buildDropdown(
                        label: "Select Chapter (Optional)",
                        icon: Icons.menu_book,
                        value: selectedChapter,
                        items: chapters,
                        itemBuilder: (item) => item['name']?.toString() ?? "",
                        onChanged: (val) => setState(() => selectedChapter = val),
                        isLoading: isLoadingChapters,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: titleController,
                        label: "Class Title",
                        icon: Icons.title,
                        hint: "e.g., Physics - Newton's Laws",
                        validator: (v) => v!.trim().isEmpty ? "Title is required" : null,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: linkController,
                        label: "Meeting Link",
                        icon: Icons.link,
                        hint: "Paste Google Meet URL",
                        keyboardType: TextInputType.url,
                        validator: (v) => v!.trim().isEmpty ? "Meeting link is required" : null,
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: dateController,
                        label: "Date",
                        icon: Icons.calendar_today,
                        readOnly: true,
                        onTap: pickDate,
                        validator: (v) => v!.isEmpty ? "Date is required" : null,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: startTimeController,
                              label: "Start Time",
                              icon: Icons.access_time,
                              readOnly: true,
                              onTap: () => pickTime(startTimeController),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: endTimeController,
                              label: "End Time",
                              icon: Icons.access_time_filled,
                              readOnly: true,
                              onTap: () => pickTime(endTimeController),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Create Button
              ElevatedButton(
                onPressed: isCreating ? null : createClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: isCreating
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text(
                  "Create Live Class",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    linkController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }
}