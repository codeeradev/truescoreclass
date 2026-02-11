import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../servcies.dart';

class AddQuestionScreenedit extends StatefulWidget {
  final int? id; // null → add new, non-null → edit
  final Map<String, dynamic>? initialQuestion;

  const AddQuestionScreenedit({
    super.key,
    this.id,
    this.initialQuestion,
  });

  @override
  State<AddQuestionScreenedit> createState() => _AddQuestionScreeneditState();
}

class _AddQuestionScreeneditState extends State<AddQuestionScreenedit>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final questionCtr = TextEditingController();
  final option1Ctr = TextEditingController();
  final option2Ctr = TextEditingController();
  final option3Ctr = TextEditingController();
  final option4Ctr = TextEditingController();
  final answerTextCtr = TextEditingController();
  final answerLinkCtr = TextEditingController();

  // States
  dynamic selectedSubject;
  dynamic selectedChapter;
  dynamic selectedBatch;
  String answerType = "text";
  String correctAnswer = 'A';
  File? selectedImage;

  List<dynamic> subjects = [];
  List<dynamic> chapters = [];
  List<dynamic> batches = [];

  bool isLoadingSubjects = true;
  bool isLoadingChapters = false;
  bool isLoadingBatches = true;
  bool isSubmitting = false;

  final List<Map<String, dynamic>> questionTypes = [
    {"id": 1, "name": "MCQ"},
    {"id": 2, "name": "CURRENT AFFAIR"},
    {"id": 3, "name": "PYQ"},
  ];
  Map<String, dynamic>? selectedQuestionType;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();

    selectedQuestionType = questionTypes.first;
    fetchBatches();
    fetchSubjects();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Load data if editing
    if (widget.id != null && widget.initialQuestion != null) {
      _loadQuestionForEdit(widget.initialQuestion!);
    }
  }

  void _loadQuestionForEdit(Map<String, dynamic> q) {
    questionCtr.text = q['question'] ?? '';

    final opts = List<String>.from(q['options'] ?? ['', '', '', '']);
    option1Ctr.text = opts.isNotEmpty ? opts[0] : '';
    option2Ctr.text = opts.length > 1 ? opts[1] : '';
    option3Ctr.text = opts.length > 2 ? opts[2] : '';
    option4Ctr.text = opts.length > 3 ? opts[3] : '';

    correctAnswer = q['right_answer'] ?? 'A';
    answerType = q['answer_type'] ?? 'text';

    if (answerType == 'text') {
      answerTextCtr.text = q['answer_value'] ?? '';
    } else if (answerType == 'link') {
      answerLinkCtr.text = q['answer_value'] ?? '';
    }
    // Note: Image cannot be pre-loaded as File – show URL or skip prefill

    // Try to pre-select subject
    final subId = q['subject_id']?.toString();
    if (subId != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (subjects.isNotEmpty) {
          try {
            final match = subjects
                .firstWhere((s) => s['id'].toString() == subId, orElse: () => null);
            if (match != null) {
              setState(() {
                selectedSubject = match;
              });
              fetchChapters(subId);
            }
          } catch (_) {}
        }
      });
    }

    setState(() {});
  }

  @override
  void dispose() {
    SecureScreen.disable();
    _fadeController.dispose();
    questionCtr.dispose();
    option1Ctr.dispose();
    option2Ctr.dispose();
    option3Ctr.dispose();
    option4Ctr.dispose();
    answerTextCtr.dispose();
    answerLinkCtr.dispose();
    super.dispose();
  }

  Future<void> fetchSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      final response =
      await http.get(Uri.parse('https://truescoreedu.com/api/get-subjects'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          subjects = json['data'] ?? [];
          isLoadingSubjects = false;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load subjects", isError: true);
    } finally {
      setState(() => isLoadingSubjects = false);
    }
  }

  Future<void> fetchChapters(String subjectId) async {
    setState(() {
      isLoadingChapters = true;
      selectedChapter = null;
      chapters.clear();
    });
    try {
      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/get-chapters'),
        body: {"subject_id": subjectId},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          chapters = json['chapters'] ?? [];
          isLoadingChapters = false;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load chapters", isError: true);
    } finally {
      setState(() => isLoadingChapters = false);
    }
  }

  Future<void> fetchBatches() async {
    setState(() => isLoadingBatches = true);
    try {
      final response = await http.get(
        Uri.parse('https://truescoreedu.com/api/get-active-batches'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          batches = json['data'] ?? [];
          isLoadingBatches = false;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to load batches", isError: true);
    } finally {
      setState(() => isLoadingBatches = false);
    }
  }

  Future<void> _submitQuestion() async {
    if (selectedSubject == null || selectedBatch == null) {
      _showSnackBar("Please select Course and Subject", isError: true);
      return;
    }

    if (answerType == "image" && selectedImage == null) {
      _showSnackBar("Please select an image", isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final isEdit = widget.id != null;

    try {
      if (answerType == "image") {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("https://truescoreedu.com/api/add-questions"),
        );

        request.fields.addAll({
          "apiToken": token,
          if (isEdit) "question_id": widget.id.toString(),
          "question": questionCtr.text.trim(),
          "subject_id": selectedSubject['id'].toString(),
          "chapter_id": selectedChapter?['id']?.toString() ?? "",
          "course_id": selectedBatch["id"].toString(),
          "question_type": selectedQuestionType?["id"].toString() ?? "1",
          "option1": option1Ctr.text.trim(),
          "option2": option2Ctr.text.trim(),
          "option3": option3Ctr.text.trim(),
          "option4": option4Ctr.text.trim(),
          "answer": correctAnswer,
          "answer_type": answerType,
        });

        if (selectedImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            "answer_value",
            selectedImage!.path,
          ));
        }

        final res = await request.send();
        final respStr = await res.stream.bytesToString();
        final json = jsonDecode(respStr);

        if (res.statusCode == 200 || res.statusCode == 201) {
          _showSnackBar(
              isEdit ? "Question updated successfully" : "Question added",
              isError: false);
          if (isEdit) Navigator.pop(context, true);
        } else {
          _showSnackBar(json['msg'] ?? "Failed", isError: true);
        }
      } else {
        final body = {
          "apiToken": token,
          if (isEdit) "question_id": widget.id.toString(),
          "question": questionCtr.text.trim(),
          "subject_id": selectedSubject['id'].toString(),
          "chapter_id": selectedChapter?['id']?.toString() ?? "",
          "course_id": selectedBatch["id"].toString(),
          "question_type": selectedQuestionType?["id"].toString() ?? "1",
          "option1": option1Ctr.text.trim(),
          "option2": option2Ctr.text.trim(),
          "option3": option3Ctr.text.trim(),
          "option4": option4Ctr.text.trim(),
          "answer": correctAnswer,
          "answer_type": answerType,
          "answer_value": answerType == "text"
              ? answerTextCtr.text.trim()
              : answerLinkCtr.text.trim(),
        };

        final response = await http.post(
          Uri.parse('https://truescoreedu.com/api/add-questions'),
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: body,
        );

        final json = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSnackBar(
              isEdit ? "Question updated successfully" : "Question added",
              isError: false);
          if (isEdit) Navigator.pop(context, true);
        } else {
          _showSnackBar(json['msg'] ?? "Failed", isError: true);
        }
      }
    } catch (e) {
      _showSnackBar("Network error occurred", isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        title: Text(
          isEdit ? "Edit Question" : "Add New Question",
          style:
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.shade300,
                        blurRadius: 15,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.question_answer,
                        size: 60, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      isEdit ? "Update Question" : "Create New Question",
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      "MCQ for your students",
                      style: TextStyle(fontSize: 15, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 15,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Course / Batch
                      if (isLoadingBatches)
                        const Center(child: CircularProgressIndicator())
                      else
                        _buildDropdown1(
                          label: "Course / Batch",
                          icon: Icons.group,
                          value: selectedBatch,
                          items: batches,
                          displayText: (b) => b['batch_name'],
                          onChanged: (val) => setState(() => selectedBatch = val),
                        ),
                      const SizedBox(height: 20),

                      // Subject
                      if (isLoadingSubjects)
                        const LinearProgressIndicator(color: Colors.blue)
                      else
                        _buildDropdown(
                          value: selectedSubject,
                          items: subjects,
                          itemBuilder: (s) => s['subject_name'],
                          onChanged: (val) async {
                            setState(() => selectedSubject = val);
                            await fetchChapters(val['id'].toString());
                          },
                          label: "Select Subject",
                          icon: Icons.book,
                        ),
                      const SizedBox(height: 20),

                      // Question Type
                      _buildDropdown1(
                        label: "Question Type",
                        icon: Icons.quiz,
                        value: selectedQuestionType,
                        items: questionTypes,
                        displayText: (item) => item["name"],
                        onChanged: (val) {
                          setState(() => selectedQuestionType = val);
                        },
                      ),
                      const SizedBox(height: 20),

                      // Chapter
                      if (isLoadingChapters)
                        const LinearProgressIndicator(color: Colors.blue)
                      else
                        _buildDropdown(
                          value: selectedChapter,
                          items: chapters,
                          itemBuilder: (c) => c['name'],
                          onChanged: (val) => setState(() => selectedChapter = val),
                          label: "Select Chapter",
                          icon: Icons.menu_book,
                          enabled: selectedSubject != null,
                        ),
                      const SizedBox(height: 20),

                      // Question
                      _buildTextField(questionCtr, "Question", Icons.help_outline,
                          maxLines: 4),
                      const SizedBox(height: 20),

                      // Options
                      _buildTextField(option1Ctr, "Option A", Icons.looks_one),
                      const SizedBox(height: 15),
                      _buildTextField(option2Ctr, "Option B", Icons.looks_two),
                      const SizedBox(height: 15),
                      _buildTextField(option3Ctr, "Option C", Icons.looks_3),
                      const SizedBox(height: 15),
                      _buildTextField(option4Ctr, "Option D", Icons.looks_4),
                      const SizedBox(height: 25),

                      // Correct Answer
                      _buildDropdown(
                        value: correctAnswer,
                        items: const ["A", "B", "C", "D"],
                        itemBuilder: (opt) => "Option $opt",
                        onChanged: (val) => setState(() => correctAnswer = val!),
                        label: "Correct Answer",
                        icon: Icons.check_box,
                      ),
                      const SizedBox(height: 25),

                      // Answer Type + Value
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: answerType,
                            decoration: const InputDecoration(labelText: "Answer Type"),
                            items: const [
                              DropdownMenuItem(value: "text", child: Text("Text")),
                              DropdownMenuItem(value: "link", child: Text("Link")),
                              DropdownMenuItem(value: "image", child: Text("Image")),
                            ],
                            onChanged: (val) {
                              setState(() {
                                answerType = val!;
                                answerTextCtr.clear();
                                answerLinkCtr.clear();
                                selectedImage = null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),

                          if (answerType == "text")
                            TextFormField(
                              controller: answerTextCtr,
                              decoration: const InputDecoration(
                                labelText: "Answer Text",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                              v == null || v.trim().isEmpty ? "Required" : null,
                            ),

                          if (answerType == "link")
                            TextFormField(
                              controller: answerLinkCtr,
                              decoration: const InputDecoration(
                                labelText: "Answer Link",
                                hintText: "https://...",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) =>
                              v == null || v.trim().isEmpty ? "Required" : null,
                            ),

                          if (answerType == "image") ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo),
                                    label: const Text("Gallery"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text("Camera"),
                                  ),
                                ),
                              ],
                            ),
                            if (selectedImage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedImage!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (isEdit &&
                                widget.initialQuestion?['answer_type'] == 'image' &&
                                selectedImage == null &&
                                widget.initialQuestion?['answer_value'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  "Current image: ${widget.initialQuestion!['answer_value']}",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                          child: isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            isEdit ? "Update Question" : "Add Question",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue, width: 2)),
      ),
      validator: (v) => v!.trim().isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdown1({
    required String label,
    required IconData icon,
    required dynamic value,
    required List items,
    required String Function(dynamic) displayText,
    required void Function(dynamic)? onChanged,
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
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required dynamic value,
    required List items,
    required String Function(dynamic) itemBuilder,
    required void Function(dynamic) onChanged,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue, width: 2)),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(itemBuilder(item)));
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}