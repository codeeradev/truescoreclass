import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  String answerType = "text"; // text, link, image

  List<dynamic> subjects = [];
  List<dynamic> chapters = [];
  bool isLoadingSubjects = true;
  bool isLoadingChapters = false;
  bool isSubmitting = false;
  dynamic selectedBatch;
  bool isLoadingBatches = true;
  List<dynamic> batches = [];
  final List<Map<String, dynamic>> questionTypes = [
    {"id": 1, "name": "MCQ"},
    {"id": 2, "name": "CURRENT AFFAIR"},
    {"id": 3, "name": "PYQ"},
  ];
  Map<String, dynamic>? selectedQuestionType;





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
          // if (widget.initialBatchId != null) {
          //   selectedBatch = batches.firstWhere(
          //         (b) => b['id'].toString() == widget.initialBatchId,
          //     orElse: () => null,
          //   );
          // }
        });
      }
    } catch (e) {
      print(e);
     // _showSnackBar("Failed to load batches");
    } finally {
      setState(() => isLoadingBatches = false);
    }
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
      validator: label.contains("Subject") || label.contains("Course")
          ? null // Optional
          : (v) => v == null ? "Required" : null,
    );
  }

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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  get()async{
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print(token);
  }
  String correctAnswer='A';


  Future<void> restoreSavedSubject() async {
    final saved = await getSavedSubject();

    if (saved['id'] != null) {
      final match = subjects.firstWhere(
            (s) => s['id'].toString() == saved['id'],
        orElse: () => null,
      );

      if (match != null) {
        setState(() => selectedSubject = match);
        fetchChapters(saved['id']!);
      }
    }
  }


  @override
  void initState() {
    super.initState();
    selectedQuestionType = questionTypes.first; // MCQ default

    get();
    fetchBatches();
    fetchSubjects();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    questionCtr.dispose();
    option1Ctr.dispose();
    option2Ctr.dispose();
    option3Ctr.dispose();
    option4Ctr.dispose();
    answerValueCtr.dispose();
    super.dispose();
  }

  // Fetch Subjects
  Future<void> fetchSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      final response = await http.get(Uri.parse('https://testora.codeeratech.in/api/get-subjects'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('sub');
        print(json);
        setState(() {
          subjects = json['data'] ?? [];
          isLoadingSubjects = false;
        });
      }
      restoreSavedSubject();

    } catch (e) {
      _showSnackBar("Failed to load subjects", isError: true);
    } finally {
      setState(() => isLoadingSubjects = false);
    }
  }

  // Fetch Chapters based on selected subject
  Future<void> fetchChapters(String subjectId) async {
    setState(() {
      isLoadingChapters = true;
      selectedChapter = null;
      chapters.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/get-chapters'),
        body: {"subject_id": subjectId},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print(json);
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

  // Submit Question
  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedSubject == null || selectedChapter == null) {
      _showSnackBar("Please select subject and chapter", isError: true);
      return;
    }
    if (selectedBatch == null) {
      _showSnackBar("Please select batch", isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print("token$token");

    try {
      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/add-questions'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "apiToken": token.toString(),
          "question": questionCtr.text.trim(),
          "subject_id": selectedSubject['id'].toString(),
          "chapter_id": selectedChapter['id'].toString(),
          "course_id":selectedBatch.toString(),
          "question_type":selectedQuestionType?["id"].toString() ,
          "option1": option1Ctr.text.trim(),
          "option2": option2Ctr.text.trim(),
          "option3": option3Ctr.text.trim(),
          "option4": option4Ctr.text.trim(),
          "answer":correctAnswer.toString(),


          "answer_type": answerType,
          "answer_value": answerType == "text"
              ? option1Ctr.text.trim() // or correct answer logic
              : answerValueCtr.text.trim(),
        },
      );

      final json = jsonDecode(response.body);
      print(json);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(json['message'] ?? "Question added successfully!", isError: false);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const QuestionListScreen()),
        // );
        //_resetForm();
      } else {
        _showSnackBar(json['message'] ?? "Failed to add question", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error: $e", isError: true);
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
    setState(() {
      selectedSubject = null;
      selectedChapter = null;
      answerType = "text";
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
          child:
          Column(
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
                      isLoadingBatches
                          ? const Center(child: CircularProgressIndicator())
                          : _buildDropdown1(
                        label: "Course / Batch",
                        icon: Icons.group,
                        value: selectedBatch,
                        items: batches,
                        displayText: (b) => b['batch_name'],
                        onChanged: (val) => setState(() => selectedBatch = val),
                      ),
                      SizedBox(height: 20,),

                      // Subject Dropdown
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
                      _buildDropdown1(
                        label: "Question Type",
                        icon: Icons.quiz,
                        value: selectedQuestionType,
                        items: questionTypes,
                        displayText: (item) => item["name"],
                        onChanged: (val) {
                          setState(() {
                            selectedQuestionType = val;
                          });

                          // 👇 THIS IS WHAT YOU SEND TO API
                          final int selectedId = val["id"];
                          print("Selected ID: $selectedId");
                        },
                      ),
                      SizedBox(height: 20,),


                      // Chapter Dropdown
                      isLoadingChapters
                          ? const LinearProgressIndicator(color: Colors.blue)
                          : _buildDropdown(
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
                      _buildDropdown(
                        value: correctAnswer,
                        items: const ["A", "B", "C", "D"],
                        itemBuilder: (opt) => "Option $opt",
                        onChanged: (val) => setState(() => correctAnswer = val!),
                        label: "Correct Answer",
                        icon: Icons.check_box,
                      ),
                      const SizedBox(height: 25),


                      // Answer Type
                      _buildDropdown(
                        value: answerType,
                        items: const ["text", "link", "image"],
                        itemBuilder: (type) => type[0].toUpperCase() + type.substring(1),
                        onChanged: (val) => setState(() => answerType = val!),
                        label: "Answer Type",
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(height: 20),

                      // Answer Value (if link/image)
                      if (answerType != "text")
                        _buildTextField(
                          answerValueCtr,
                          answerType == "link" ? "Answer Link (PDF/URL)" : "Answer Image URL",
                          answerType == "link" ? Icons.link : Icons.image,
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

  // Modern Blue & White TextField
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue, width: 2)),
      ),
      validator: (v) => v!.trim().isEmpty ? "Required" : null,
    );
  }

  // Modern Dropdown with itemBuilder support
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
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.blue, width: 2)),
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