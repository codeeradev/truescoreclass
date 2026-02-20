import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../servcies.dart';

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
    SecureScreen.enable();

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

  File? selectedFile; // image or pdf
  String? selectedFileType; // "image" | "pdf"


  @override
  void dispose() {
    SecureScreen.disable();

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
        Uri.parse('https://truescoreedu.com/api/get-teacher-doubts'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": token},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        print(json);
        if (json['status'] == 1) {
          final List data = json['data'] ?? [];
          final List<Map<String, dynamic>> sorted = data.cast<Map<String, dynamic>>();

          sorted.sort((a, b) {
            final aAnswer = (a['teacher_description'] ?? '').toString().trim();
            final bAnswer = (b['teacher_description'] ?? '').toString().trim();

            // unanswered first
            if (aAnswer.isEmpty && bAnswer.isNotEmpty) return -1;
            if (aAnswer.isNotEmpty && bAnswer.isEmpty) return 1;

            return 0; // keep relative order otherwise
          });

          setState(() {
            doubts = sorted;
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
  void showSuccessDialog(BuildContext context, {String message = "Successfully Submitted"}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// ✅ SUCCESS ICON
                Container(
                  height: 70,
                  width: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 16),

                /// TITLE
                const Text(
                  "Success",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                /// MESSAGE
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                /// OK BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff8cff22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("OK"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }


  // Teacher replies to a doubt
  Future<void> replyToDoubt(String doubtId, String reply) async {
    print('yes');
    if (reply.trim().isEmpty) {
      _showSnackBar("Please write a reply", isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://truescoreedu.com/api/update-teacher-doubts'),
      );
      req.headers.addAll({
        "Accept": "application/json",
        // If backend uses apiToken in body (already), Authorization may be optional
        // Use ONLY if backend expects it:
        // "Authorization": "Bearer $token",
      });

      req.fields.addAll({
        "apiToken": token,
        "doubt_id": doubtId,
        "description": reply.trim(),
      });

      // 🔹 FILE UPLOAD (image or pdf)
      if (selectedFile != null) {
        req.files.add(
          await http.MultipartFile.fromPath(
            "file", // 🔑 backend file key
            selectedFile!.path,
          ),
        );
      }

      final streamed = await req.send();
      final response = await http.Response.fromStream(streamed);
      final json = jsonDecode(response.body);
      print(json);
      print(response.body);

      if (response.statusCode == 200 && json['status'] == 1) {
        _showSnackBar("Reply submitted successfully!", isError: false);
        selectedFile = null;
        selectedFileType = null;
       // r.clear();
        fetchTeacherDoubts();

        Navigator.pop(context);
        showSuccessDialog(context);

      } else {
        _showSnackBar(json['msg'] ?? "Failed to submit reply", isError: true);
      }
    } catch (e) {
      print(e);
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Reply to Student",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: replyController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Write your explanation here...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 FILE PICK BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text("Image"),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked =
                            await picker.pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setDialogState(() {
                                selectedFile = File(picked.path);
                                selectedFileType = "image";
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("PDF"),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null) {
                              setDialogState(() {
                                selectedFile = File(result.files.single.path!);
                                selectedFileType = "pdf";
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🔹 FILE PREVIEW
                  if (selectedFile != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedFileType == "pdf"
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFile!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                selectedFile = null;
                                selectedFileType = null;
                              });
                            },
                          )
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
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
             // Navigator.pop(context);
              replyToDoubt(
                doubt['doubt_id'].toString(),
                replyController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Text("Submit Reply",
                style: TextStyle(color: Colors.white)),
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
  Widget buildMathText(
      String text, {
        double fontSize = 15,
        FontWeight fontWeight = FontWeight.normal,
      }) {
    bool isMath(String t) {
      return t.contains(r"\frac") ||
          t.contains("^") ||
          t.contains("_") ||
          t.contains(r"\sqrt") ||
          t.contains(r"\sum");
    }

    /// 🧮 IF MATH → horizontal scroll
    if (isMath(text)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          text,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      );
    }

    /// 🔤 NORMAL TEXT
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.5,
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
                                  "At: ${doubt['created_at'] ?? ''}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  "From: ${student['name'] ?? 'Unknown Student'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                // Text(
                                //   "Subject: ${subject['name'] ?? 'Unknown'}",
                                //   style: const TextStyle(color: Colors.grey),
                                // ),
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
                      buildMathText(
                        doubt['description'] ?? 'No description',
                      ),

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