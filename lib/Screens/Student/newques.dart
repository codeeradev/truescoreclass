import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ================= HTML CLEANER =================
String removeHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
}
class ChapterListScreen extends StatelessWidget {
  final List<dynamic> questions;
  final String batchId;
  final String questionType;
  final String subjectName;

  const ChapterListScreen({
    super.key,
    required this.questions,
    required this.batchId,
    required this.questionType,
    required this.subjectName,
  });

  /// 🔹 unique chapters (null → Others)
  List<String> get chapters {
    final set = <String>{};
    for (var q in questions) {
      final name = q['chapter_name']?.toString();
      set.add((name == null || name.isEmpty) ? "Others" : name);
    }
    return set.toList();
  }

  List<dynamic> _byChapter(String chapter) {
    if (chapter == "Others") {
      return questions.where((q) =>
      q['chapter_name'] == null ||
          q['chapter_name'].toString().isEmpty).toList();
    }
    return questions.where((q) => q['chapter_name'] == chapter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Chapter")),
      body:
      ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final chapterQuestions = _byChapter(chapter);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttemptPaperScreen(
                        questions: chapterQuestions,
                        questionType: questionType,
                        batchId: batchId,
                        subjectName: subjectName,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Row(
                    children: [

                      /// 🔥 LEFT ICON
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.purple,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// 🔥 FLEXIBLE TEXT AREA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),

                            /// Question count (professional touch)
                            // Text(
                            //   "${chapterQuestions.length} Questions",
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     color: Colors.grey.shade600,
                            //   ),
                            // ),
                          ],
                        ),
                      ),

                      /// 🔥 RIGHT ARROW
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },

      ),
    );
  }
}



class SubjectListScreen extends StatelessWidget {
  final List<dynamic> questions;
  final String batchId;
  final String questionType;

  const SubjectListScreen({
    super.key,
    required this.questions,
    required this.batchId,
    required this.questionType,
  });

  // 🔹 unique subjects
  List<String> get subjects {
    final set = <String>{};
    for (var q in questions) {
      final name = q['subject_name']?.toString();
      if (name != null && name.isNotEmpty) set.add(name);
    }
    return set.toList();
  }

  List<dynamic> _bySubject(String subject) {
    return questions.where((q) => q['subject_name'] == subject).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Subject")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];

          return InkWell(
            onTap: () {
              final subjectQuestions = _bySubject(subject);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterListScreen(
                    questions: subjectQuestions,
                    batchId: batchId,
                    questionType: questionType,
                    subjectName: subject,
                  ),
                ),
              );

            },
            child: Container(
              height: 70,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue),
              ),
              child: Center(
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


/// =================================================
///  SCREEN 1: QUESTION TYPE SELECTION (3 CARDS)
/// =================================================
class QuestionTypeSelectionScreen extends StatelessWidget {
  final List<dynamic> questions;
  final String batchId;

  const QuestionTypeSelectionScreen({
    super.key,
    required this.questions,
    required this.batchId,
  });

  List<dynamic> _filterByType(String type) {
    return questions.where((q) => q['question_type'] == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mcq = _filterByType("1");
    final ca = _filterByType("2");
    final pyq = _filterByType("3");

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _typeCard(context, "MCQ", "1", mcq, Colors.blue),
            _typeCard(context, "Current Affairs", "2", ca, Colors.orange),
            _typeCard(context, "PYQ", "3", pyq, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(
      BuildContext context,
      String title,
      String questionType,
      List<dynamic> list,
      Color color,
      ) {
    return InkWell(
      onTap: list.isEmpty
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectListScreen(
              questions: list,      // 👈 filtered by type
              batchId: batchId,
              questionType: questionType,
            ),
          ),
        );
      },
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            "$title (${list.length})",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// =================================================
///  SCREEN 2: ATTEMPT PAPER (ONE QUESTION AT A TIME)


class AttemptPaperScreen extends StatefulWidget {
  final List<dynamic> questions;
  final String questionType;
  final String batchId;
  final String subjectName; // 👈 ADD THIS

  const AttemptPaperScreen({
    super.key,
    required this.questions,
    required this.questionType,
    required this.batchId,
    required this.subjectName,
  });

  @override
  State<AttemptPaperScreen> createState() => _AttemptPaperScreenState();
}


class _AttemptPaperScreenState extends State<AttemptPaperScreen> {
  int currentIndex = 0;
  int? selectedIndex;
  bool submitted = false;

  /// 🔑 UNIQUE KEYS (Batch + Paper Type)
  String get progressKey =>
      "batch_${widget.batchId}_progress_${widget.questionType}";

  String get totalKey =>
      "batch_${widget.batchId}_total_${widget.questionType}";

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _saveTotalQuestions();
  }

  /// 💾 SAVE TOTAL QUESTIONS
  Future<void> _saveTotalQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(totalKey, widget.questions.length);
  }

  /// 🔁 LOAD SAVED PROGRESS
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(progressKey) ?? 0;

    setState(() {
      currentIndex =
      savedIndex < widget.questions.length ? savedIndex : 0;
      selectedIndex = null;
      submitted = false;
    });
  }

  /// 💾 SAVE CURRENT QUESTION INDEX
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(progressKey, currentIndex);
  }

  /// ❌ CLEAR PROGRESS (after finish)
  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(progressKey);
    await prefs.remove(totalKey);
  }
  void openDoubtDialog(BuildContext context, String des, String batchId, List<String> options,) {
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

                // 🔥 Convert options list to text
                String optionsText = options
                    .asMap()
                    .entries
                    .map((e) => "Option ${e.key + 1}: ${e.value}")
                    .join("\n");

                /// 🔥 Final description with options
                String finalDescription = """
$des

Options:
$optionsText

My problem:
${problemController.text.trim()}
""";

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


  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentIndex];

    final question = removeHtml(q['question']?.toString() ?? "");
    String image=q['question_image']??"";

    final options = (q['options'] as List)
        .map((e) => removeHtml(e.toString()))
        .toList();

    final correctIndex =
    "ABCD".indexOf(q['right_answer']?.toString() ?? "");

    final answerType = q['answer_type'];
    final answerValue = q['answer_value'];

    return Scaffold(
      appBar: AppBar(
        title:  Text(
          "${widget.subjectName} • Question ${currentIndex + 1}/${widget.questions.length}",
        ),
        actions: [
          InkWell(onTap: (){
            openDoubtDialog(
                context,
                question??'',widget.batchId.toString(),options // pass your batch id here
            );
            //  submitDoubt(htmlToPlainText(q['question']?.toString() ?? ""),widget.paperData['batch_id'].toString());


          },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,borderRadius: BorderRadius.circular(10)
              ),
              child: Row(
                children: [
                  Text("  Raise Doubt",style: TextStyle(color: Colors.white),),
                  Icon(Icons.question_mark,color: Colors.white,)
                ],
              ),
            ),
          )


        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            image.isEmpty?SizedBox(): Container(height: 150,width: 100,child: Image.network("https://truescoreedu.com/$image",fit: BoxFit.cover,),),
            const SizedBox(height: 20),

            /// OPTIONS
            ...List.generate(options.length, (index) {
              final isSelected = selectedIndex == index;
              final isCorrect = index == correctIndex;

              Color border = Colors.grey.shade300;
              if (submitted) {
                if (isCorrect) border = Colors.green;
                else if (isSelected) border = Colors.red;
              } else if (isSelected) {
                border = Colors.blue;
              }

              return InkWell(
                onTap: submitted
                    ? null
                    : () => setState(() => selectedIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: border,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(options[index])),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            /// SUBMIT / NEXT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedIndex == null
                    ? null
                    : () async {
                  if (!submitted) {
                    setState(() => submitted = true);
                  } else {
                    await _nextQuestion();
                  }
                },
                child: Text(submitted ? "Next" : "Submit"),
              ),
            ),

            /// EXPLANATION
            if (submitted && selectedIndex != correctIndex)
              _buildExplanation(answerType, answerValue),
          ],
        ),
      ),
    );
  }

  /// ▶ NEXT QUESTION
  Future<void> _nextQuestion() async {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
        submitted = false;
      });
      await _saveProgress(); // 👈 SAVE AFTER MOVE
    } else {
      //await _clearProgress(); // 👈 CLEAR AFTER FINISH
      Navigator.pop(context);
    }
  }

  /// 📘 EXPLANATION VIEW
  Widget _buildExplanation(String type, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Explanation",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          if (type == "text") Text(removeHtml(value)),
          if (type == "image") Image.network(value),
          if (type == "link")
            Text(
              value,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
        ],
      ),
    );
  }
}


