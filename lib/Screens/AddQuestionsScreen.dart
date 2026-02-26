import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servcies.dart';
import 'GetQues.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final questionCtr = TextEditingController();
  final option1Ctr = TextEditingController();
  final option2Ctr = TextEditingController();
  final option3Ctr = TextEditingController();
  final option4Ctr = TextEditingController();
  final answerValueCtr = TextEditingController();

  // Dropdowns
  dynamic selectedSubject;
  dynamic selectedChapter;
  dynamic selectedBatch;
  Map<String, dynamic>? selectedQuestionType;

  String answerType = "text"; // text | link | image

  final TextEditingController answerTextCtr = TextEditingController();
  final TextEditingController answerLinkCtr = TextEditingController();

  File? selectedImage;

  List<dynamic> subjects = [];
  List<dynamic> chapters = [];
  List<dynamic> batches = [];

  final List<Map<String, dynamic>> questionTypes = [
    {"id": 1, "name": "MCQ"},
    {"id": 2, "name": "CURRENT AFFAIR"},
    {"id": 3, "name": "PYQ"},
  ];

  bool isLoadingSubjects = true;
  bool isLoadingChapters = false;
  bool isLoadingBatches = true;
  bool isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String correctAnswer = 'A';

  // ─── SAVE / LOAD HELPERS ────────────────────────────────────────────────

  // Subject
  Future<void> saveSelectedSubject(dynamic subject) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_subject_id', subject['id'].toString());
    await prefs.setString('selected_subject_name', subject['subject_name']);
  }

  Future<Map<String, String?>> getSavedSubject() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('selected_subject_id'),
      'name': prefs.getString('selected_subject_name'),
    };
  }

  // Batch
  Future<void> saveSelectedBatch(dynamic batch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_batch_id', batch['id'].toString());
    await prefs.setString('selected_batch_name', batch['batch_name']);
  }

  Future<Map<String, String?>> getSavedBatch() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('selected_batch_id'),
      'name': prefs.getString('selected_batch_name'),
    };
  }

  // Question Type
  Future<void> saveSelectedQuestionType(dynamic qType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_qtype_id', qType['id'].toString());
    await prefs.setString('selected_qtype_name', qType['name']);
  }

  Future<Map<String, String?>> getSavedQuestionType() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('selected_qtype_id'),
      'name': prefs.getString('selected_qtype_name'),
    };
  }

  // Chapter
  Future<void> saveSelectedChapter(dynamic chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_chapter_id', chapter?['id']?.toString() ?? '');
    await prefs.setString('selected_chapter_name', chapter?['name'] ?? '');
  }

  Future<Map<String, String?>> getSavedChapter() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('selected_chapter_id'),
      'name': prefs.getString('selected_chapter_name'),
    };
  }

  // ─── RESTORE ALL SELECTIONS ─────────────────────────────────────────────
  Future<void> _restoreSavedSelections() async {
    // Subject
    final savedSubject = await getSavedSubject();
    if (savedSubject['id'] != null && subjects.isNotEmpty) {
      final match = subjects.firstWhere(
            (s) => s['id'].toString() == savedSubject['id'],
        orElse: () => null,
      );
      if (match != null) {
        setState(() => selectedSubject = match);
        // fetchChapters will now handle chapter restore automatically
        fetchChapters(savedSubject['id']!);
      }
    }

    // Batch
    final savedBatch = await getSavedBatch();
    if (savedBatch['id'] != null && batches.isNotEmpty) {
      final match = batches.firstWhere(
            (b) => b['id'].toString() == savedBatch['id'],
        orElse: () => null,
      );
      if (match != null) {
        setState(() => selectedBatch = match);
      }
    }

    // Question Type
    final savedQType = await getSavedQuestionType();
    if (savedQType['id'] != null) {
      final match = questionTypes.firstWhere(
            (qt) => qt['id'].toString() == savedQType['id'],
        orElse: () => questionTypes.first,
      );
      setState(() => selectedQuestionType = match);
    }

    // ─── NO CHAPTER RESTORE HERE ANYMORE ───
  }
  @override
  void initState() {
    super.initState();
    SecureScreen.enable();

    selectedQuestionType = questionTypes.first; // default

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Load data and restore selections
    fetchBatches().then((_) => _restoreSavedSelections());
    fetchSubjects().then((_) => _restoreSavedSelections());
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
    answerValueCtr.dispose();
    answerTextCtr.dispose();
    answerLinkCtr.dispose();
    super.dispose();
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
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => isLoadingBatches = false);
    }
  }

  Future<void> fetchSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      final response = await http.get(Uri.parse('https://truescoreedu.com/api/get-subjects'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          subjects = json['data'] ?? [];
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

        // ─── IMPORTANT: Restore chapter RIGHT AFTER chapters are set ───
        final savedChapter = await getSavedChapter();
        if (savedChapter['id'] != null && chapters.isNotEmpty) {
          final match = chapters.firstWhere(
                (c) => c['id'].toString() == savedChapter['id'],
            orElse: () => null,
          );
          if (match != null) {
            setState(() => selectedChapter = match);
          } else {
            print("Saved chapter ID ${savedChapter['id']} not found in current chapters");
          }
        }
      } else {
        setState(() => isLoadingChapters = false);
      }
    } catch (e) {
      print("fetchChapters error: $e");
      setState(() => isLoadingChapters = false);
      _showSnackBar("Failed to load chapters", isError: true);
    }
  }
  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => selectedImage = File(image.path));
    }
  }

  Future<void> _submitQuestion() async {
    if (selectedSubject == null || selectedBatch == null) {
      _showSnackBar("Please select Subject and Batch", isError: true);
      return;
    }
    if (answerType == "image" && selectedImage == null) {
      _showSnackBar("Please select an image for answer", isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      if (answerType == "image") {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("https://truescoreedu.com/api/add-questions"),
        );
        request.fields.addAll({
          "apiToken": token,
          "question": questionCtr.text.trim(),
          "subject_id": selectedSubject['id'].toString(),
          "chapter_id": selectedChapter?['id']?.toString() ?? "",
          "course_id": selectedBatch["id"].toString(),
          "question_type": selectedQuestionType?["id"].toString() ?? "",
          "option1": option1Ctr.text.trim(),
          "option2": option2Ctr.text.trim(),
          "option3": option3Ctr.text.trim(),
          "option4": option4Ctr.text.trim(),
          "answer": correctAnswer,
          "answer_type": "image",
        });
        request.files.add(
          await http.MultipartFile.fromPath("answer_value", selectedImage!.path),
        );
        final res = await request.send();
        final respStr = await res.stream.bytesToString();
        final json = jsonDecode(respStr);
        if (res.statusCode == 200 || res.statusCode == 201) {
          _showSnackBar(json['msg'] ?? "Question added", isError: false);
        } else {
          _showSnackBar(json['msg'] ?? "Failed to add", isError: true);
        }
      } else {
        final body = {
          "apiToken": token,
          "question": questionCtr.text.trim(),
          "subject_id": selectedSubject['id'].toString(),
          "chapter_id": selectedChapter?['id']?.toString() ?? "",
          "course_id": selectedBatch["id"].toString(),
          "question_type": selectedQuestionType?["id"].toString() ?? "",
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
          _showSnackBar(json['msg'] ?? "Question added", isError: false);
        } else {
          _showSnackBar(json['msg'] ?? "Failed to add", isError: true);
        }
      }
    } catch (e) {
      print(e);
      _showSnackBar("Network error", isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    questionCtr.clear();
    option1Ctr.clear();
    option2Ctr.clear();
    option3Ctr.clear();
    option4Ctr.clear();
    answerValueCtr.clear();
    answerTextCtr.clear();
    answerLinkCtr.clear();
    setState(() {
      selectedSubject = null;
      selectedChapter = null;
      selectedBatch = null;
      selectedQuestionType = questionTypes.first;
      answerType = "text";
      selectedImage = null;
    });
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
        elevation: 0,
        title: const Text("Add New Question", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.blue.shade300, blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.question_answer, size: 60, color: Colors.white),
                    SizedBox(height: 12),
                    Text("Create New Question", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Add MCQ for your students", style: TextStyle(fontSize: 15, color: Colors.white70)),
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
                  boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Batch / Course
                      isLoadingBatches
                          ? const Center(child: CircularProgressIndicator())
                          : _buildDropdown1(
                        label: "Course / Batch",
                        icon: Icons.group,
                        value: selectedBatch,
                        items: batches,
                        displayText: (b) => b['batch_name'],
                        onChanged: (val) {
                          setState(() => selectedBatch = val);
                          saveSelectedBatch(val);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Subject
                      isLoadingSubjects
                          ? const LinearProgressIndicator(color: Colors.blue)
                          : _buildDropdown(
                        value: selectedSubject,
                        items: subjects,
                        itemBuilder: (s) => s['subject_name'],
                        onChanged: (val) async {
                          setState(() => selectedSubject = val);
                          await saveSelectedSubject(val);
                          fetchChapters(val['id'].toString());
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
                          saveSelectedQuestionType(val);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Chapter
                      isLoadingChapters
                          ? const LinearProgressIndicator(color: Colors.blue)
                          : _buildDropdown(
                        value: selectedChapter,
                        items: chapters,
                        itemBuilder: (c) => c['name'],
                        onChanged: (val) {
                          setState(() => selectedChapter = val);
                          saveSelectedChapter(val);
                        },
                        label: "Select Chapter",
                        icon: Icons.menu_book,
                        enabled: selectedSubject != null,
                      ),

                      const SizedBox(height: 20),

                      // Question
                      _buildTextField(questionCtr, "Question", Icons.help_outline, maxLines: 4),

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

                      // Answer Type + Input
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
                            StatefulBuilder(
                              builder: (context, setLocalState) {
                                bool isMath(String text) {
                                  return text.contains(r"\frac") ||
                                      text.contains("^") ||
                                      text.contains("_") ||
                                      text.contains(r"\sqrt") ||
                                      text.contains(r"\sum");
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: answerTextCtr,
                                      maxLines: null,
                                      onChanged: (_) => setLocalState(() {}),
                                      decoration: InputDecoration(
                                        labelText: "Answer Text",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      validator: (v) => v == null || v.isEmpty ? "Required" : null,
                                    ),
                                    if (isMath(answerTextCtr.text.trim()))
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Math.tex(
                                            answerTextCtr.text,
                                            textStyle: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),

                          if (answerType == "link")
                            TextFormField(
                              controller: answerLinkCtr,
                              decoration: const InputDecoration(
                                labelText: "Answer Link",
                                hintText: "https://...",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? "Required" : null,
                            ),

                          if (answerType == "image")
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submitQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                          child: isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Add Question", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS (unchanged) ─────────────────────────────────────────

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
      }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool isMath(String text) {
          return text.contains(r"\frac") ||
              text.contains("^") ||
              text.contains("_") ||
              text.contains(r"\sqrt") ||
              text.contains(r"\sum");
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller,
              maxLines: null,
              onChanged: (_) => setLocalState(() {}),
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: Colors.blue.shade600),
                filled: true,
                fillColor: Colors.grey.shade50,
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
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              validator: (v) => v!.trim().isEmpty ? "Required" : null,
            ),
            if (isMath(controller.text.trim()))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Math.tex(
                  controller.text,
                  textStyle: const TextStyle(fontSize: 20),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown1({
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
      validator: (v) => v == null ? "Required" : null,
    );
  }

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
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(itemBuilder(item)));
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (v) => v == null ? "Required" : null,
    );
  }
}