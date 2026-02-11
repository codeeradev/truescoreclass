import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../servcies.dart';
import 'Student/result.dart';


class PaperTypeScreen extends StatefulWidget {
  const PaperTypeScreen({super.key});
  @override
  State<PaperTypeScreen> createState() => _PaperTypeScreenState();
}

class _PaperTypeScreenState extends State<PaperTypeScreen> {
  List<dynamic> mockPapers = [];
  List<dynamic> practicePapers = [];
  bool isLoading = true;
  String errorMsg = "";

  @override
  void initState() {
    super.initState();
    fetchPapers();
  }

  Future<void> fetchPapers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? apiToken = prefs.getString("token");

      if (apiToken == null || apiToken.isEmpty) {
        setState(() {
          errorMsg = "API Token Missing!";
          isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-active-questions"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "apiToken": apiToken,  // 🔥 PASS TOKEN HERE
        },
      );

      print("Raw Response: ${response.body}"); // DEBUG

      if (response.statusCode == 200) {
        /// Clean HTML and newline junk
        String cleanedBody = response.body
            .replaceAll('\\r\\n', ' ')
            .replaceAll('\\n', ' ')
            .replaceAll('> <', '><')
            .trim();

        final Map<String, dynamic> json = jsonDecode(cleanedBody);

        if (json['status'] == "1" && json['data'] != null) {
          final List data = json['data'];

          setState(() {
            mockPapers = data.where((e) => e['paper_type'] == "1").toList();
            practicePapers = data.where((e) => e['paper_type'] == "2").toList();
            isLoading = false;
          });

          print("Mock Papers Count: ${mockPapers.length}");
          print("Practice Papers Count: ${practicePapers.length}");
        } else {
          setState(() {
            errorMsg = json['msg'] ?? "No data";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMsg = "Server Error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception: $e");
      setState(() {
        errorMsg = "Failed to load: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Testora"),
      //   backgroundColor: Colors.deepPurple,
      //   foregroundColor: Colors.white,
      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
          ? Center(child: Text(errorMsg, style: const TextStyle(color: Colors.red)))
          :
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Select Paper Type",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            _buildBigCard(
              title: "Mock Papers",
              count: mockPapers.length,
              color: Colors.blue,
              icon: Icons.timer,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PapersListScreen(papers: mockPapers, title: "Mock Papers"),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildBigCard(
              title: "Practice Papers",
              count: practicePapers.length,
              color: Colors.green,
              icon: Icons.school,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PapersListScreen(papers: practicePapers, title: "Practice Papers"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: count == 0 ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "$count Available",
              style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9)),
            ),
            if (count == 0)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text("Coming Soon", style: TextStyle(color: Colors.white70)),
              ),
          ],
        ),
      ),
    );
  }
}

// Papers List Screen
class PapersListScreen extends StatefulWidget {
  final List papers;
  final String title;
  const PapersListScreen({super.key, required this.papers, required this.title});

  @override
  State<PapersListScreen> createState() => _PapersListScreenState();
}

class _PapersListScreenState extends State<PapersListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.papers.isEmpty
          ? const Center(child: Text("No papers found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.papers.length,
        itemBuilder: (_, i) {
          final p = widget.papers[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamScreen(paperData: p,title: widget.title.toString(),))),
              leading: CircleAvatar(backgroundColor: Colors.deepPurple, child: Text("${i + 1}")),
              title: Text(p['paper_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${p['total_questions']} Qs • ${p['time_duration']} min • Negative: ${p['negative_percent']}"),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      ),
    );
  }
}

// Exam Screen (Same as before but with HTML fix)


class ExamScreen extends StatefulWidget {
  final Map<String, dynamic> paperData;
  final String title; // "Practice Papers" or "Mock Papers"

  const ExamScreen({super.key, required this.paperData, required this.title});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late Timer _timer;
  int remainingSeconds = 0;
  int currentIndex = 0;
  Map<String, String> selectedAnswers = {};
  bool showResult = false;

  late DateTime startTime;
  late String formattedStartTime;

  late SharedPreferences prefs;

  // Unique key for saving progress: e.g., "practice_12" or "mock_15"
  String get _progressKey => "${widget.title.replaceAll(' ', '_').toLowerCase()}_${widget.paperData['paper_id']}";

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();

    _initSharedPrefsAndResume();
  }


  Future<void> _initSharedPrefsAndResume() async {
    prefs = await SharedPreferences.getInstance();

    // Load saved answers and last index
    String? savedData = prefs.getString(_progressKey);
    if (savedData != null) {
      Map<String, dynamic> saved = jsonDecode(savedData);
      selectedAnswers = Map<String, String>.from(saved['answers'] ?? {});
      currentIndex = saved['last_index'] ?? 0;

      // Move to next unanswered question
      final questions = widget.paperData['questions'] as List;
      while (currentIndex < questions.length &&
          selectedAnswers.containsKey(questions[currentIndex]['id'].toString())) {
        currentIndex++;
      }

      // If all answered, go to last
      if (currentIndex >= questions.length) {
        currentIndex = questions.length - 1;
      }
    }

    // Set timer
    remainingSeconds = int.tryParse(widget.paperData['time_duration'].toString())! * 60;
    startTime = DateTime.now();
    formattedStartTime = startTime.toIso8601String().substring(0, 19).replaceAll('T', ' ');

    startTimer();
    setState(() {}); // Refresh UI after loading saved progress
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        timer.cancel();
        submitExam(auto: true);
      }
    });
  }

  // Save progress whenever question changes
  Future<void> _saveProgress() async {
    Map<String, dynamic> progress = {
      'last_index': currentIndex,
      'answers': selectedAnswers,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_progressKey, jsonEncode(progress));
  }

  @override
  void dispose() {
    SecureScreen.disable();

    _timer.cancel();
    super.dispose();
  }

  String formatTime(int s) => "${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}";

  Future<void> submitExam({bool auto = false}) async {
    // Clear saved progress on final submit
    await prefs.remove(_progressKey);

    final DateTime submitTime = DateTime.now();
    final String formattedSubmitTime = submitTime.toIso8601String().substring(0, 19).replaceAll('T', ' ');

    final token = prefs.getString('token') ?? '';

    Map answers = {};
    for (var q in widget.paperData['questions']) {
      answers[q['id'].toString()] = selectedAnswers[q['id'].toString()] ?? "";
    }

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/submit-paper"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "apiToken": token,
          "paper_id": widget.paperData['paper_id'].toString(),
          "paper_type": widget.paperData['paper_type'].toString(),
          "question_answer": jsonEncode(answers),
          "paper_name": widget.paperData['paper_name'].toString(),
          "start_time": formattedStartTime,
          "submit_time": formattedSubmitTime,
          "total_question": widget.paperData['total_questions'].toString(),
          "time_duration": widget.paperData['time_duration'].toString(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"].toString() == "1") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auto ? "Time Up! Auto Submitted!" : "Exam Submitted Successfully!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                paperId: widget.paperData['paper_id'].toString(),
                paperType: widget.paperData['paper_type'].toString(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  void openDoubtDialog(BuildContext context, String des, String batchId) {
    final TextEditingController problemController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Your Problem",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: problemController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Type your problem here...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (problemController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter your problem")),
                  );
                  return;
                }

                /// 🔥 Combine description text
                String finalDescription =
                    "$des\n my problem is: ${problemController.text.trim()}";

                submitDoubt(finalDescription, batchId);

                Navigator.pop(context);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Future<void> submitDoubt(String des,String id) async {
    print(des);
    print(id);


    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final Map<String, String> body = {
        "apiToken": token,
        "batch_id": id,
        "description":des ,
        // "chapter_id": "4",
      };
      print(body);

      // if (selectedChapter != null) {
      //   body["chapter_id"] = selectedChapter!['id'].toString();
      // }

      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/add-doubt'),
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
  String htmlToPlainText(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }



  @override
  Widget build(BuildContext context) {
    final questions = widget.paperData['questions'] as List;
    if (questions.isEmpty) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text("No questions")));
    }

    final q = questions[currentIndex];
    String? selectedOption = selectedAnswers[q['id'].toString()];
    bool isCorrect = selectedOption == q['right_answer'].toString().toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.paperData['paper_name']),
        actions: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: remainingSeconds < 300 ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              formatTime(remainingSeconds),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 20,),
          InkWell(onTap: (){
            openDoubtDialog(
              context,
                htmlToPlainText(q['question']?.toString() ?? ""),widget.paperData['batch_id'].toString() // pass your batch id here
            );
          //  submitDoubt(htmlToPlainText(q['question']?.toString() ?? ""),widget.paperData['batch_id'].toString());


          },
            child:  Container(
              height: 30,
              decoration: BoxDecoration(
                  color: Colors.green,borderRadius: BorderRadius.circular(10)
              ),
              child: Row(
                children: [
                  Text("  Raise Doubt",style: TextStyle(color: Colors.white),),
                  Icon(Icons.question_mark,color: Colors.white,size: 20,)
                ],
              ),
            ),
          )

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            LinearProgressIndicator(value: (currentIndex + 1) / questions.length),
            const SizedBox(height: 8),
            Text("Question ${currentIndex + 1} / ${questions.length}",
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 30),

            // Question
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Html(data: q['question'].toString()),
              ),
            ),
            const SizedBox(height: 20),

            // Options
            ...List.generate(q['options'].length, (i) {
              String optionKey = String.fromCharCode(65 + i);
              String optionText = q['options'][i].toString().trim();

              return Card(
                color: selectedOption == optionKey
                    ? (isCorrect ? Colors.green.shade100 : Colors.red.shade100)
                    : null,
                child: RadioListTile<String>(
                  title: Html(data: optionText),
                  value: optionKey,
                  groupValue: selectedOption,
                  onChanged: selectedOption == null
                      ? (val) {
                    setState(() {
                      selectedAnswers[q['id'].toString()] = val!;
                      showResult = true;
                    });
                    _saveProgress(); // Save immediately
                  }
                      : null,
                  activeColor: isCorrect ? Colors.green : Colors.red,
                ),
              );
            }),

            const SizedBox(height: 20),

            // Feedback
            if (showResult)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isCorrect ? Colors.green : Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      isCorrect ? "Correct Answer!" : "Wrong Answer!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            if (showResult && !isCorrect) ...[
              const SizedBox(height: 20),
              const Text("Explanation:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              if (q['answer_type'] == "link" && q['answer_value'].toString().isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final url = q['answer_value'].toString();
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.link, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("View Detailed Explanation",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              if (q['answer_type'] == "file" && q['answer_value'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://truescoreedu.com/${q['answer_value']}",
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade200,
                      child: const Text("Image not available"),
                    ),
                  ),
                ),
              if (q['answer_type'] == "text" && q['answer_value'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(q['answer_value'], style: const TextStyle(fontSize: 15)),
                ),
            ],

            const SizedBox(height: 40),

            // Next / Submit Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (currentIndex < questions.length - 1) {
                    setState(() {
                      currentIndex++;
                      showResult = false;
                    });
                    await _saveProgress();
                  } else {
                    submitExam();
                  }
                },
                icon: Icon(currentIndex == questions.length - 1 ? Icons.check : Icons.arrow_forward),
                label: Text(currentIndex == questions.length - 1 ? "Submit Exam" : "Next Question"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _ExamScreenState extends State<ExamScreen> {
//   late Timer _timer;
//   int remainingSeconds = 0;
//   int currentIndex = 0;
//   Map<String, String> selectedAnswers = {};
//   bool showResult = false;
//
//   late DateTime startTime;  // ← ADD THIS
//   late String formattedStartTime;  // ← ADD THIS
//
//   @override
//   void initState() {
//     super.initState();
//     // Record start time
//     startTime = DateTime.now();
//     formattedStartTime = startTime.toIso8601String().substring(0, 19).replaceAll('T', ' ');
//
//     remainingSeconds = int.tryParse(widget.paperData['time_duration'].toString())! * 60;
//     startTimer();
//   }
//
//   // ... (rest of your code remains same until submitExam)
//
//   // REPLACE YOUR submitExam() WITH THIS FULLY UPDATED VERSION
//   Future<void> submitExam({bool auto = false}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token') ?? '';
//
//     if (token.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Token missing!")),
//       );
//       return;
//     }
//
//     // Collect user answers
//     Map<String, String> answers = {};
//     for (var q in widget.paperData['questions']) {
//       answers[q['id'].toString()] = selectedAnswers[q['id'].toString()] ?? "";
//     }
//
//     // Current time when submitting
//     final DateTime submitTime = DateTime.now();
//     final String formattedSubmitTime = submitTime.toIso8601String().substring(0, 19).replaceAll('T', ' ');
//
//     try {
//       final response = await http.post(
//         Uri.parse("https://truescoreedu.com/api/submit-paper"),
//         headers: {
//           "Content-Type": "application/x-www-form-urlencoded",
//         },
//         body: {
//           "apiToken": token,                                      // ← your backend key
//           "paper_id": widget.paperData['paper_id'].toString(),
//           "paper_type": widget.paperData['paper_type'] == "1" ? "mock" : "practice",
//           "paper_name": widget.paperData['paper_name'].toString(),
//           "start_time": formattedStartTime,                       // ← NEW
//           "submit_time": formattedSubmitTime,                     // ← NEW
//           "total_question": widget.paperData['total_questions'].toString(),
//           "time_duration": widget.paperData['time_duration'].toString(),
//           "question_answer": jsonEncode(answers),
//         },
//       );
//
//       print("Submit Request Body: ${{
//         "apiToken": token,
//         "paper_id": widget.paperData['paper_id'],
//         "paper_type": widget.paperData['paper_type'] == "1" ? "mock" : "practice",
//         "paper_name": widget.paperData['paper_name'],
//         "start_time": formattedStartTime,
//         "submit_time": formattedSubmitTime,
//         "total_question": widget.paperData['total_questions'],
//         "time_duration": widget.paperData['time_duration'],
//         "question_answer": jsonEncode(answers),
//       }}");
//
//       if (!mounted) return;
//
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);
//         if (json["status"].toString() == "1") {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               backgroundColor: Colors.green,
//               content: Text(auto ? "Time Up! Auto Submitted!" : "Exam Submitted Successfully!"),
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Warning: ${json['msg']}")),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Server Error: ${response.statusCode}")),
//         );
//       }
//
//       // Go back to home
//       Navigator.popUntil(context, (route) => route.isFirst);
//
//     } catch (e) {
//       print("Submit Exception: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Network Error: $e")),
//         );
//       }
//     }
//   }
//
// // ... rest of your build() method remains unchanged
// }