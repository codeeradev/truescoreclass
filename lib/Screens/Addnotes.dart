import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class AddNotesScreen extends StatefulWidget {
  final int? noteId; // null = add new, not null = update
  final String? initialTitle;
  final String? initialBatchId;
  final String? initialSubjectId;
  final String? initialChapterId;
  final String? initialFileName; // for display in update mode

  const AddNotesScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialBatchId,
    this.initialSubjectId,
    this.initialChapterId,
    this.initialFileName,
  });

  @override
  State<AddNotesScreen> createState() => _AddNotesScreenState();
}

class _AddNotesScreenState extends State<AddNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  List<dynamic> subjects = [];
  List<dynamic> chapters = [];
  List<dynamic> batches = [];

  bool isLoadingSubjects = true;
  bool isLoadingChapters = false;
  bool isLoadingBatches = true;
  bool isSubmitting = false;

  dynamic selectedSubject;
  dynamic selectedChapter;
  dynamic selectedBatch;

  PlatformFile? pickedFile; // Selected PDF file

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';

    fetchSubjects();
    fetchBatches();

    // If updating, pre-fill values
    if (widget.noteId != null) {
      if (widget.initialSubjectId != null) {
        // We'll set after subjects load
      }
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      final response = await http.get(
        Uri.parse('https://testora.codeeratech.in/api/get-subjects'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          subjects = json['data'] ?? [];
          isLoadingSubjects = false;

          // Pre-select subject if updating
          if (widget.initialSubjectId != null) {
            selectedSubject = subjects.firstWhere(
                  (s) => s['id'].toString() == widget.initialSubjectId,
              orElse: () => null,
            );
            if (selectedSubject != null) {
              fetchChapters(selectedSubject['id'].toString());
            }
          }
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load subjects");
    } finally {
      setState(() => isLoadingSubjects = false);
    }
  }

  Future<void> fetchChapters(String subjectId) async {
    setState(() {
      isLoadingChapters = true;
      chapters.clear();
      selectedChapter = null;
    });
    try {
      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/get-chapters'),
        body: {"subject_id": subjectId},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          chapters = json['chapters'] ?? [];
          isLoadingChapters = false;

          // Pre-select chapter if updating
          if (widget.initialChapterId != null) {
            selectedChapter = chapters.firstWhere(
                  (c) => c['id'].toString() == widget.initialChapterId,
              orElse: () => null,
            );
          }
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load chapters");
    } finally {
      setState(() => isLoadingChapters = false);
    }
  }

  Future<void> fetchBatches() async {
    setState(() => isLoadingBatches = true);
    try {
      final response = await http.get(
        Uri.parse('https://testora.codeeratech.in/api/get-active-batches'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          batches = json['data'] ?? [];
          isLoadingBatches = false;

          // Pre-select batch if updating
          if (widget.initialBatchId != null) {
            selectedBatch = batches.firstWhere(
                  (b) => b['id'].toString() == widget.initialBatchId,
              orElse: () => null,
            );
          }
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load batches");
    } finally {
      setState(() => isLoadingBatches = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        pickedFile = result.files.single;
      });
    }
  }

  Future<void> _submitNote() async {
    // if (!_formKey.currentState!.validate()) return;
    if (pickedFile == null && widget.noteId == null) {
      _showSnackBar("Please select a PDF file", Colors.red);
      return;
    }

    setState(() => isSubmitting = true);

    final token = await _getToken();
    if (token == null) {
      _showSnackBar("Authentication token missing", Colors.red);
      setState(() => isSubmitting = false);
      return;
    }

    var uri = Uri.parse('https://testora.codeeratech.in/api/add-notes');
    var request = http.MultipartRequest('POST', uri);
    print(selectedBatch['id'].toString());
    print(selectedSubject['id'].toString());




    request.fields['title'] = _titleController.text.trim();
    request.fields['apiToken'] = token;
    if (selectedBatch != null) {
      request.fields['batch'] = selectedBatch['id'].toString();
    }
    if (selectedSubject != null) {
      request.fields['subject'] = selectedSubject['id'].toString();
    }
    // if (selectedChapter != null) {
     request.fields['chapter'] = 'hu';
    // }
    // if (widget.noteId != null) {
    //   request.fields['note_id'] = widget.noteId.toString();
    // }

    if (pickedFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', pickedFile!.path!),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print(response.body);


      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.body);
        final json = jsonDecode(response.body);
        if (json['status'] == true || json['success'] == true) {
          _showSnackBar("Notes ${widget.noteId == null ? 'added' : 'updated'} successfully!", Colors.green);
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          _showSnackBar(json['message'] ?? "Failed to save note", Colors.red);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Network error: $e", Colors.red);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
        fillColor: Colors.blue.shade50.withOpacity(0.3),
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
      validator: label.contains("Subject") || label.contains("Course")
          ? null // Optional
          : (v) => v == null ? "Required" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.noteId == null ? "Add New Notes" : "Update Notes",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Note Title *",
                  prefixIcon: const Icon(Icons.title, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (v) => v?.trim().isEmpty == true ? "Title is required" : null,
              ),
              const SizedBox(height: 20),

              // Subject Dropdown
              isLoadingSubjects
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown(
                label: "Subject (Optional)",
                icon: Icons.book,
                value: selectedSubject,
                items: subjects,
                displayText: (s) => s['subject_name'],
                onChanged: (val) {
                  setState(() => selectedSubject = val);
                  if (val != null) fetchChapters(val['id'].toString());
                },
              ),
              const SizedBox(height: 20),

              // Chapter Dropdown
              isLoadingChapters
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown(
                label: "Chapter (Optional)",
                icon: Icons.menu_book,
                value: selectedChapter,
                items: chapters,
                displayText: (c) => c['name'],
                onChanged: (val) => setState(() => selectedChapter = val),
                enabled: selectedSubject != null,
              ),
              const SizedBox(height: 20),

              // Batch (Single Select)
              isLoadingBatches
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDropdown(
                label: "Course / Batch",
                icon: Icons.group,
                value: selectedBatch,
                items: batches,
                displayText: (b) => b['batch_name'],
                onChanged: (val) => setState(() => selectedBatch = val),
              ),
              const SizedBox(height: 30),

              // File Picker
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade300, style: BorderStyle.solid),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.shade100, blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          pickedFile?.name ?? widget.initialFileName ?? "Tap to select PDF file *",
                          style: TextStyle(
                            fontSize: 16,
                            color: pickedFile == null && widget.noteId == null ? Colors.grey.shade600 : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.cloud_upload, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              if (pickedFile == null && widget.noteId == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 12),
                  child: Text("PDF file is required", style: TextStyle(color: Colors.red, fontSize: 12)),
                ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    widget.noteId == null ? "Add Notes" : "Update Notes",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}