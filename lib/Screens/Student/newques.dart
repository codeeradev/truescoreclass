import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// ================= HTML CLEANER =================
String removeHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
}

/// =================================================
/// HELPER: Check if all questions in a list are attempted
/// =================================================
Future<bool> isAllQuestionsAttempted(
    List<dynamic> questionList,
    String batchId,
    String questionType,
    ) async {
  final prefs = await SharedPreferences.getInstance();
  for (var q in questionList) {
    final qId = q['id']?.toString() ?? q['question_id']?.toString() ?? "";
    if (qId.isEmpty) continue;
    final key = "attempted_${batchId}_${questionType}_$qId";
    final attempted = prefs.getBool(key) ?? false;
    if (!attempted) return false;
  }
  return true;
}

/// =================================================
/// SCREEN 3: ATTEMPT PAPER (ONE QUESTION AT A TIME)
/// =================================================
class AttemptPaperScreen extends StatefulWidget {
  final List<dynamic> questions;
  final String questionType;
  final String batchId;
  final String subjectName;

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
  late String chapterName;
  late String progressKey;

  @override
  void initState() {
    super.initState();
    chapterName = widget.questions.isNotEmpty
        ? (widget.questions[0]['chapter_name']?.toString() ?? "Syllabus")
        : "Syllabus";
    progressKey =
    "batch_${widget.batchId}_progress_${widget.questionType}_${widget.subjectName}_$chapterName";
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(progressKey) ?? 0;
    setState(() {
      currentIndex = savedIndex < widget.questions.length ? savedIndex : 0;
      selectedIndex = null;
      submitted = false;
    });

    // Check if chapter is completed
    final isCompleted = await isAllQuestionsAttempted(
        widget.questions, widget.batchId, widget.questionType);
    if (isCompleted) {
      _showResetDialog();
    }
  }

  Future<void> _showResetDialog() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chapter Completed"),
        content: const Text(
            "This chapter is already completed. Do you want to attempt again from the start?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      await _clearProgress();
      setState(() {
        currentIndex = 0;
        selectedIndex = null;
        submitted = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(progressKey, currentIndex);
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(progressKey);
  }

  String _getAttemptedKey(String questionId) {
    return "attempted_${widget.batchId}_${widget.questionType}_$questionId";
  }

  Future<void> _markAsAttempted() async {
    if (selectedIndex == null) return;
    final q = widget.questions[currentIndex];
    final questionId =
        q['id']?.toString() ?? q['question_id']?.toString() ?? currentIndex.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getAttemptedKey(questionId), true);
  }

  void openDoubtDialog(
      BuildContext context, String des, String batchId, List<String> options) {
    final TextEditingController problemController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Your Problem", style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: problemController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Type your problem here...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (problemController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter your problem")),
                  );
                  return;
                }
                String optionsText = options
                    .asMap()
                    .entries
                    .map((e) => "Option ${e.key + 1}: ${e.value}")
                    .join("\n");
                String finalDescription = """
$des
Options: $optionsText
My problem: ${problemController.text.trim()}
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

  Future<void> submitDoubt(String des, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final Map<String, String> body = {
        "apiToken": token,
        "batch_id": id,
        "description": des,
      };
      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/add-doubt'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 1) {
        _showSnackBar("Doubt submitted successfully!", isError: false);
      } else {
        _showSnackBar(json['msg'] ?? "Failed to submit doubt", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error. Please try again.", isError: true);
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

  Widget buildQuestionText(String question) {

    bool hasMath(String text) {
      return text.contains(r"\frac") ||
          text.contains(r"\sqrt") ||
          text.contains(r"\sum") ||
          text.contains("^") ||
          text.contains("_");
    }

    bool hasHtml(String text) {
      return text.contains("<") && text.contains(">");
    }

    /// 🔥 CASE 1: PURE MATH (no html, only latex)
    if (hasMath(question) && !hasHtml(question)) {
      return Math.tex(
        question,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    /// 🔥 CASE 2: HTML (with or without math inside)
    if (hasHtml(question)) {
      return Html(
        data: question,

        style: {
          "*": Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
          ),
        },

        /// 👇 handle math inside html
        extensions: [
          TagExtension(
            tagsToExtend: {"math"},
            builder: (context) {
              final tex = context.element?.text ?? "";
              return Math.tex(
                tex,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),

          /// 👇 AUTO detect latex inside normal html text
          TagExtension(
            tagsToExtend: {"span", "p", "div"},
            builder: (context) {
              final text = context.element?.text ?? "";

              if (hasMath(text)) {
                return Math.tex(
                  text,
                  textStyle: const TextStyle(fontSize: 20),
                );
              }

              return Text(
                text,
                style: const TextStyle(fontSize: 18),
              );
            },
          ),
        ],
      );
    }

    /// 🔥 CASE 3: NORMAL TEXT
    return Text(
      formatQuestion(question),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  Widget buildQuestionWidget(String question) {

    bool isMath(String text) {
      return text.contains(r"\frac") ||
          text.contains("^") ||
          text.contains("_") ||
          text.contains(r"\sqrt") ||
          text.contains(r"\sum");
    }

    /// If math equation
    if (isMath(question)) {
      return Math.tex(
        question,
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    /// If HTML content exists
    if (question.contains("<")) {
      return Html(data: question);
    }

    /// Normal text
    return Text(
      formatQuestion(question),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  String formatQuestion(String text) {
    text = text.trim();
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1);
  }


  Widget buildOptionText(String option) {
    bool isMath(String text) {
      return text.contains(r"\frac") ||
          text.contains("^") ||
          text.contains("_") ||
          text.contains(r"\sqrt") ||
          text.contains(r"\sum");
    }

    /// 🧮 If math detected → render equation
    if (isMath(option)) {
      return Math.tex(
        option,
        textStyle: const TextStyle(
          fontSize: 18,
        ),
      );
    }

    /// 🔤 Normal text
    return Text(formatQuestion(option),style:    const TextStyle(
      fontSize: 16,
    ));
  }
  Widget buildOptionWidget(String option) {

    bool isMath(String text) {
      return text.contains(r"\frac") ||
          text.contains("^") ||
          text.contains("_") ||
          text.contains(r"\sqrt") ||
          text.contains(r"\sum");
    }

    if (isMath(option)) {
      return Math.tex(
        option,
        textStyle: const TextStyle(
          fontSize: 18,
        ),
      );
    }

    if (option.contains("<")) {
      return Html(data: option);
    }

    return Text(
      option,
      style: const TextStyle(fontSize: 16),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentIndex];

    final question = q['question']?.toString() ?? "";
    String image = q['question_image'] ?? "";

    final options =
    (q['options'] as List).map((e) => removeHtml(e.toString())).toList();

    final correctIndex =
    "ABCD".indexOf(q['right_answer']?.toString() ?? "");

    final answerType = q['answer_type'];
    final answerValue = q['answer_value'];

    bool isCorrect = selectedIndex == correctIndex;
    // final q = widget.questions[currentIndex];
    // final question = removeHtml(q['question']?.toString() ?? "");
    // String image = q['question_image'] ?? "";
    // final options =
    // (q['options'] as List).map((e) => removeHtml(e.toString())).toList();
    // final correctIndex = "ABCD".indexOf(q['right_answer']?.toString() ?? "");
    // final answerType = q['answer_type'];
    // final answerValue = q['answer_value'];
   // print(answerValue);


    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.subjectName} • Question ${currentIndex + 1}/${widget.questions.length}"),
        actions: [
          InkWell(
            onTap: () {
              openDoubtDialog(
                context,
                question,
                widget.batchId.toString(),
                options,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text("Raise Doubt",
                      style: TextStyle(color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(Icons.question_mark,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: (currentIndex + 1) / widget.questions.length),
            SizedBox(height: 5,),


            /// QUESTION INDEX
            Text(
              "Question ${currentIndex + 1}/${widget.questions.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// QUESTION CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: buildQuestionWidget(question),
                ),
              ),
            ),

            /// QUESTION IMAGE
            if (image.isNotEmpty) ...[
              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  "https://truescoreedu.com/$image",
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 80),
                ),
              ),
            ],

            const SizedBox(height: 20),

            /// OPTIONS
            ...List.generate(options.length, (index) {

              bool isSelected = selectedIndex == index;
              bool isOptionCorrect = index == correctIndex;

              Color? cardColor;

              if (submitted) {
                if (isOptionCorrect) {
                  cardColor = Colors.green.shade100;
                } else if (isSelected) {
                  cardColor = Colors.red.shade100;
                }
              }

              return
                Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),

                child: RadioListTile<int>(
                  title:  buildOptionWidget(options[index].toString()),

                  value: index,
                  groupValue: selectedIndex,

                  onChanged: submitted
                      ? null
                      : (val) {
                    setState(() {
                      selectedIndex = val;
                    });
                  },

                  activeColor:
                  isCorrect ? Colors.green : Colors.deepPurple,
                ),
              );
            }),

            const SizedBox(height: 20),

            /// RESULT MESSAGE
            if (submitted)
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.shade50
                      : Colors.red.shade50,

                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(
                    color: isCorrect
                        ? Colors.green
                        : Colors.red,
                  ),
                ),

                child: Row(
                  children: [

                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: isCorrect
                          ? Colors.green
                          : Colors.red,
                      size: 32,
                    ),

                    const SizedBox(width: 12),

                    Text(
                      isCorrect
                          ? "Correct Answer!"
                          : "Wrong Answer!",

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            /// EXPLANATION
            if (submitted && selectedIndex != correctIndex) ...[

              const SizedBox(height: 20),

              answerValue.toString()=="No explanation required"?SizedBox(): Text(
                "Explanation",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              /// LINK
              if (answerType == "link" &&
                  (answerValue.toString().isNotEmpty||answerValue!=null))

                GestureDetector(
                  onTap: () async {

                    final url = answerValue.toString();

                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }

                  },

                  child: answerValue.toString()=="No explanation required"?SizedBox():Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),

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

                        Text(
                          "View Detailed Open Url",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              /// IMAGE
              if ((answerType == "image" ||answerType == "file")
                  &&
                  answerValue.toString().isNotEmpty
              )

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: answerValue==null?SizedBox():Image.network(
                    "https://truescoreedu.com/$answerValue",
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),

              /// TEXT
              if (answerType == "text" &&
                  answerValue.toString().isNotEmpty)

                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),

                  child:buildQuestionText(answerValue.toString())
                  // Text(
                  //   answerValue.toString(),
                  //   style: const TextStyle(fontSize: 15),
                  // ),
                ),
            ],

            const SizedBox(height: 40),

            /// NEXT BUTTON
            ///
            ///

            // SizedBox(
            //   width: double.infinity,
            //   height: 54,
            //
            //   child: ElevatedButton(
            //
            //     onPressed: selectedIndex == null
            //         ? null
            //         : () async {
            //
            //       if (!submitted) {
            //
            //         await _markAsAttempted();
            //
            //         setState(() {
            //           submitted = true;
            //         });
            //
            //       } else {
            //
            //         await _nextQuestion();
            //
            //       }
            //
            //     },
            //
            //     style: ElevatedButton.styleFrom(
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //
            //     child: Text(
            //       submitted ? "Next Question" : "Submit",
            //       style: const TextStyle(fontSize: 16),
            //     ),
            //   ),
            // ),
            Row(
              children: [

                /// PREVIOUS BUTTON
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: currentIndex == 0 ? null : () async {
                        await _previousQuestion();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Previous",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                /// SUBMIT / NEXT BUTTON
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: selectedIndex == null
                          ? null
                          : () async {

                        if (!submitted) {

                          await _markAsAttempted();

                          setState(() {
                            submitted = true;
                          });

                        } else {

                          await _nextQuestion();

                        }

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        submitted ? "Next Question" : "Submit",
                        style:  TextStyle(fontSize: 16,color: Colors.white),
                      ),
                    ),
                  ),
                ),

              ],
            )
          ],
        ),
      ),
    );
  }
  Future<void> _previousQuestion() async {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        selectedIndex = null;
        submitted = false;
      });

      await _saveProgress();
    }
  }
  Future<void> _nextQuestion() async {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedIndex = null;
        submitted = false;
      });
      await _saveProgress();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildExplanation(String type, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Explanation",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 12),
          if (type == "text") Text(removeHtml(value), style: const TextStyle(fontSize: 15)),
          if (type == "image") Image.network(value, fit: BoxFit.cover),
          if (type == "link")
            Text(
              value,
              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
            ),
        ],
      ),
    );
  }
}

/// =================================================
/// SCREEN 2: CHAPTER LIST
/// =================================================
class ChapterListScreen extends StatefulWidget {
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

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  Map<String, bool> _chapterCompleted = {};

  @override
  void initState() {
    super.initState();
    _loadChapterCompletion();
  }

  Future<void> _loadChapterCompletion() async {
    final chapters = _getChapters();
    final Map<String, bool> status = {};
    for (var chapter in chapters) {
      final chapQs = _byChapter(chapter);
      final done = await isAllQuestionsAttempted(chapQs, widget.batchId, widget.questionType);
      status[chapter] = done;
    }
    if (mounted) {
      setState(() => _chapterCompleted = status);
    }
  }

  List<String> _getChapters() {
    final set = <String>{};
    for (var q in widget.questions) {
      print(q);
      final name = q['chapter_name']?.toString();
      set.add((name == null) ? "Syllabus" : name);
    }
    return set.toList();
  }

  List<dynamic> _byChapter(String chapter) {
    if (chapter == "Syllabus") {
      return widget.questions
          .where((q) => q['chapter_name'] == null || q['chapter_name'].toString().isEmpty)
          .toList();
    }
    return widget.questions.where((q) => q['chapter_name'] == chapter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _getChapters();
    return Scaffold(
      appBar: AppBar(title: const Text("Select Chapter")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final chapterQuestions = _byChapter(chapter);
          final isCompleted = _chapterCompleted[chapter] ?? false;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: isCompleted ? Colors.green.shade50 : Colors.white,
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
                        questionType: widget.questionType,
                        batchId: widget.batchId,
                        subjectName: widget.subjectName,
                      ),
                    ),
                  ).then((_) => _loadChapterCompletion());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.withOpacity(0.2)
                              : Colors.purple.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle : Icons.menu_book_rounded,
                          color: isCompleted ? Colors.green : Colors.purple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: isCompleted ? Colors.green.shade800 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${chapterQuestions.length} Questions",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle, color: Colors.green, size: 24)
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
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

/// =================================================
/// SCREEN 1: SUBJECT LIST
/// =================================================
class SubjectListScreen extends StatefulWidget {
  final List<dynamic> questions;
  final String batchId;
  final String questionType;

  const SubjectListScreen({
    super.key,
    required this.questions,
    required this.batchId,
    required this.questionType,
  });

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  Map<String, bool> _subjectCompleted = {};

  @override
  void initState() {
    super.initState();
    _loadSubjectCompletion();
  }

  Future<void> _loadSubjectCompletion() async {
    final subs = _getSubjects();
    final Map<String, bool> status = {};
    for (var sub in subs) {
      final subQs = _bySubject(sub);
      final done = await isAllQuestionsAttempted(subQs, widget.batchId, widget.questionType);
      status[sub] = done;
    }
    if (mounted) setState(() => _subjectCompleted = status);
  }

  List<String> _getSubjects() {
    final set = <String>{};
    for (var q in widget.questions) {
      final name = q['subject_name']?.toString();
      if (name != null && name.isNotEmpty) set.add(name);
    }
    return set.toList();
  }

  List<dynamic> _bySubject(String subject) {
    return widget.questions.where((q) => q['subject_name'] == subject).toList();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _getSubjects();
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Select Subject",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final subjectQuestions = _bySubject(subject);
          final isCompleted = _subjectCompleted[subject] ?? false;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChapterListScreen(
                    questions: subjectQuestions,
                    batchId: widget.batchId,
                    questionType: widget.questionType,
                    subjectName: subject,
                  ),
                ),
              ).then((_) => _loadSubjectCompletion());
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 86,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isCompleted ? Border.all(color: Colors.green, width: 1.8) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.15)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.menu_book_rounded,
                      color: isCompleted ? Colors.green : Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? Colors.green.shade800 : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCompleted ? "Done" : "${subjectQuestions.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// =================================================
/// SCREEN 0: QUESTION TYPE SELECTION
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _typeCard(context, "MCQ", "1", mcq, Colors.blue),
            const SizedBox(height: 16),
            _typeCard(context, "Current Affairs", "2", ca, Colors.orange),
            const SizedBox(height: 16),
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
    final bool isEmpty = list.isEmpty;
    return InkWell(
      // Disable tap when empty
      onTap: isEmpty
          ? null
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectListScreen(
              questions: list,
              batchId: batchId,
              questionType: questionType,
            ),
          ),
        );
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isEmpty ? Colors.grey.withOpacity(0.08) : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEmpty ? Colors.grey.shade400 : color,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$title (${list.length})",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isEmpty ? Colors.grey.shade600 : color,
                ),
              ),
              if (isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    "No questions available",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}