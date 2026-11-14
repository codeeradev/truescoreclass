import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:online_classes/Screens/Student/Bottombar.dart';
import 'package:online_classes/Screens/Student/chapter_progress.dart';
import 'package:online_classes/Screens/Student/result.dart';
import 'package:online_classes/Screens/Student/subject_progress.dart';
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
    final qId = q['id']?.toString() ?? "";

    final key = "attempted_${batchId}_${questionType}_$qId";
    final attempted = prefs.getBool(key) ?? false;

    print("$key = $attempted");

    if (!attempted) return false;
  }

  return true;
}

/// =================================================
/// SCREEN 3: ATTEMPT PAPER (ONE QUESTION AT A TIME)
/// =================================================

class AttemptPaperScreen extends StatefulWidget {
  final String questionType;
  final String batchId;
  final String subjectName;
  final String chapterName;
  final String subjectId;
  final String chapterId;
  final String attemptedCount;

  const AttemptPaperScreen({
    super.key,
    required this.questionType,
    required this.batchId,
    required this.subjectName,
    required this.chapterName,
    required this.subjectId,
    required this.chapterId,
    required this.attemptedCount,
  });

  @override
  State<AttemptPaperScreen> createState() => _AttemptPaperScreenState();
}

class _AttemptPaperScreenState extends State<AttemptPaperScreen> {
  int currentIndex = 0;
  int currentQu = 0;
  int? selectedIndex;
  bool submitted = false;
  late String progressKey;

  List<dynamic> questions = [];
  String questionTotal = '0';

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final int pageSize = 10;

  @override
  void initState() {
    super.initState();
    progressKey =
        'currentQuestion${widget.batchId}/${widget.subjectId}/${widget.subjectName}/${widget.chapterName}/${widget.chapterId}/${widget.questionType}';

    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    final int? localCurrent = prefs.getInt(progressKey);
    final int attemptedCount = int.tryParse(widget.attemptedCount) ?? 0;

    final int cuIndex = localCurrent ?? attemptedCount;

    currentPage = cuIndex == 0 ? 1 : ((cuIndex - 1) ~/ pageSize) + 1;
    final int displayIndex = cuIndex == 0 ? 0 : (cuIndex - 1) % pageSize;
    await fetchApiCourseQuestions();

    print('displayIndex--$displayIndex');
    setState(() {
      currentQu = displayIndex;
      currentIndex = cuIndex;
      selectedIndex = null;
      submitted = false;
    });

    final totalQuestions = int.tryParse(questionTotal) ?? 0;

    if (currentIndex >= totalQuestions - 1) {
      _showResetDialog();
    }
  }

  // Future<void> _init() async {
  //   await fetchApiCourseQuestions();
  //   await _checkCompletion();
  //   final prefs = await SharedPreferences.getInstance();
  //   final savedQuestionId = prefs.getString(progressKey);
  //
  //   int savedIndex = 0;
  //   if (savedQuestionId != null) {
  //     int foundIndex = questions.indexWhere(
  //       (q) => q['id'].toString() == savedQuestionId,
  //     );
  //
  //     while (foundIndex == -1 && hasMore) {
  //       await fetchApiCourseQuestions(loadMore: true);
  //       foundIndex = questions.indexWhere(
  //         (q) => q['id'].toString() == savedQuestionId,
  //       );
  //     }
  //
  //     if (foundIndex != -1) savedIndex = foundIndex;
  //   }
  //
  //   if (!mounted) return;
  //   setState(() {
  //     currentIndex = savedIndex;
  //     selectedIndex = null;
  //     submitted = false;
  //   });
  // }

  // Future<void> _checkCompletion() async {
  //   print("questions: ${questions.length}");
  //   print("hasMore: $hasMore");
  //
  //   final completed = await isAllQuestionsAttempted(
  //     questions,
  //     widget.batchId,
  //     widget.questionType,
  //   );
  //
  //   print("completed: $completed");
  //
  //   if (completed && mounted) {
  //     print("Showing Reset Dialog");
  //     _showResetDialog();
  //   }
  // }

  Future<void> fetchApiCourseQuestions({bool loadMore = false}) async {
    if (loadMore && (isLoadingMore || !hasMore)) return;

    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() => isLoading = true);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // final int offset = (currentPage - 1) * pageSize;

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-course-questions"),
        body: {
          "apiToken": token,
          "courseId": widget.batchId,
          "page": currentPage.toString(),
          // "offset": offset.toString(),
          "question_type": widget.questionType,
          "subjectId": widget.subjectId,
          "chapterId": widget.chapterId,
        },
      );

      if (kDebugMode) {
        log("fetchApiCourseQuestions STATUS: ${response.statusCode}");
        log("fetchApiCourseQuestions BODY: ${response.body}");
      }

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }
      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }
      if (response.body.trim().startsWith('<')) {
        throw Exception("Server returned HTML instead of JSON");
      }

      final data = jsonDecode(response.body);

      final bool success = data["status"].toString() == "true" ||
          data["status"].toString() == "1";

      if (success) {
        setState(() {
          final List newQuestions = data["data"]["questions"] ?? [];
          if (!loadMore) {
            questions.clear();
          }
          if (newQuestions.isEmpty) {
            hasMore = false;
          } else {
            questions.addAll(newQuestions);
            currentPage++;
            if (newQuestions.length < pageSize) {
              hasMore = false;
            }
          }
          final pagination = data["data"]["pagination"];
          // currentPage = pagination["current_page"] + 1;
          // hasMore = int.parse(pagination['page'].toString()) > currentPage;
          questionTotal = pagination["total"].toString();
        });
      } else {
        hasMore = false;
      }
    } on TimeoutException {
      if (kDebugMode) log('fetchApiCourseQuestions error--Request timed out');
      hasMore = false;
    } catch (e) {
      if (kDebugMode) log('fetchApiCourseQuestions error--$e');
      hasMore = false;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _showCompletionDialog() async {
    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Completed",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        return PopScope(
          canPop: false, // Disable phone back button
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: AlertDialog(
              backgroundColor: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              content: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber.shade700,
                            size: 52,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Congratulations!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "You've successfully completed all the questions.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Your responses have been submitted successfully.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ModernBottomNav(selectedIndex: 1),
                                ),
                                (route) => false,
                              );

                              if (widget.questionType == '1') {
                                Future.delayed(
                                    const Duration(milliseconds: 200), () {
                                  if (widget.chapterId.isNotEmpty ||
                                      widget.chapterId != '') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChapterProgressScreen(
                                          batchId: widget.batchId,
                                          subjectId: widget.subjectId,
                                          subjectName: widget.subjectName,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubjectProgressScreen(
                                          batchId: widget.batchId,
                                        ),
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            child: const Text("View Progress"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Close Button
                  Positioned(
                    top: -12,
                    right: -12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                          Navigator.of(context).pop(); // Go back
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showResetDialog() async {
    final prefs = await SharedPreferences.getInstance();

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chapter Completed"),
        content: const Text(
          "This chapter is already completed. Do you want to attempt again from the start?",
        ),
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
      setState(() {
        currentPage = 0;
        currentIndex = 0;
        currentQu = 0;
        selectedIndex = null;
        submitted = false;
      });
      await prefs.remove(progressKey);
      await fetchApiCourseQuestions();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(progressKey, currentIndex);
  }

  // Future<void> resetChapterAttempts(
  //   List<dynamic> questionList,
  //   String batchId,
  //   String questionType,
  //   String chapterId,
  // ) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   for (var q in questionList) {
  //     final qId = q['id']?.toString() ?? "";
  //     if (qId.isEmpty) continue;
  //
  //     await prefs.remove("attempted_${batchId}_${questionType}_$qId");
  //   }
  //   await prefs.remove(
  //     "chapter_completed_${batchId}_${questionType}_$chapterId",
  //   );
  //   await prefs.remove(progressKey);
  // }

  String _getAttemptedKey(String questionId) {
    return "attempted_${widget.batchId}_${widget.questionType}_$questionId";
  }

  Future<void> _markAsAttempted() async {
    if (selectedIndex == null) return;
    final q = questions[currentQu];
    final questionId = q['id']?.toString() ??
        q['question_id']?.toString() ??
        currentIndex.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getAttemptedKey(questionId), true);
  }

  void openDoubtDialog(
    BuildContext context,
    String des,
    String batchId,
    List<String> options,
  ) {
    final TextEditingController problemController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = true;
        String? teacherAnswer;
        double matchPercent = 0;
        bool apiCalled = false;

        return StatefulBuilder(
          builder: (context, setState) {
            String optionsText = options
                .asMap()
                .entries
                .map((e) => "Option ${e.key + 1}: ${e.value}")
                .join("\n");

            String finalDescription = """
$des
Options: $optionsText
""";

            Future<void> checkSimilarity() async {
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token') ?? '';

                final response = await http.post(
                  Uri.parse('https://truescoreedu.com/api/similar-doubts'),
                  headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                  },
                  body: {
                    "apiToken": token,
                    "question": finalDescription,
                  },
                );

                final json = jsonDecode(response.body);
                log('json--te--${json['data']}');
                if (json['status'] == "true" && json['data'] != null) {
                  matchPercent =
                      double.tryParse(json['match_percent'].toString()) ?? 0;

                  if (matchPercent >= 80) {
                    teacherAnswer = json['data']['teacher_description'];
                  } else {
                    teacherAnswer = "No strong match found";
                  }
                } else {
                  teacherAnswer = json['msg'] ?? "No close match found";
                }
              } catch (e) {
                teacherAnswer = "Error checking match";
              }

              setState(() {
                isLoading = false;
              });
            }

            if (!apiCalled) {
              apiCalled = true;
              Future.microtask(() {
                checkSimilarity();
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Your Doubt",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading) const CircularProgressIndicator(),
                    if (!isLoading && teacherAnswer != null) ...[
                      teacherAnswer.toString() == "No close match found"
                          ? const SizedBox()
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Available Solution on this Doubt",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text("${teacherAnswer!}"),
                                ],
                              ),
                            ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: problemController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Type your problem here...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (problemController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter your problem"),
                        ),
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
                    submitDoubt(
                      des: finalDescription,
                      id: batchId,
                      subjectId: widget.subjectId,
                      chapterId: widget.chapterId,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> submitDoubt({
    required String des,
    required String id,
    required String chapterId,
    required String subjectId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final Map<String, String> body = {
        "apiToken": token,
        "batch_id": id,
        "description": des,
        "subject_id": subjectId,
        "chapter_id": chapterId,
      };
      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/add-doubt'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );
      if (kDebugMode) {
        log('body---$body');
        log('statusCode---${response.statusCode}');
        log('data---${response.body}');
      }
      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 1) {
        _showSnackBar("Doubt submitted successfully!", isError: false);
      } else {
        _showSnackBar(json['msg'] ?? "Failed to submit doubt", isError: true);
      }
    } catch (e) {
      if (kDebugMode) log("error-submitDoubt-$e");
      _showSnackBar("Network error. Please try again.", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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

    if (hasMath(question) && !hasHtml(question)) {
      return Math.tex(
        question,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }

    if (hasHtml(question)) {
      return Html(
        data: question,
        style: {
          "*": Style(fontSize: FontSize(18), fontWeight: FontWeight.bold),
        },
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
          TagExtension(
            tagsToExtend: {"span", "p", "div"},
            builder: (context) {
              final text = context.element?.text ?? "";
              if (hasMath(text)) {
                return Math.tex(text, textStyle: const TextStyle(fontSize: 20));
              }
              return Text(text, style: const TextStyle(fontSize: 18));
            },
          ),
        ],
      );
    }

    return Text(
      formatQuestion(question),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

    if (isMath(question)) {
      return Math.tex(
        question,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }

    if (question.contains("<")) {
      return Html(data: question);
    }

    return Text(
      formatQuestion(question),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

    if (isMath(option)) {
      return Math.tex(option, textStyle: const TextStyle(fontSize: 18));
    }

    return Text(formatQuestion(option), style: const TextStyle(fontSize: 16));
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
      return Math.tex(option, textStyle: const TextStyle(fontSize: 18));
    }

    if (option.contains("<")) {
      return Html(data: option);
    }

    return Text(option, style: const TextStyle(fontSize: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(widget.subjectName,
              style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(widget.subjectName,
              style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text("No questions available")),
      );
    }

    final q = questions[currentQu];
    final question = q['question']?.toString() ?? "";
    String image = q['question_image'] ?? "";

    final options =
        (q['options'] as List).map((e) => removeHtml(e.toString())).toList();

    final correctIndex = "ABCD".indexOf(q['right_answer']?.toString() ?? "");

    final answerType = q['answer_type'];
    final answerValue = q['answer_value'];

    bool isValue = currentIndex >= int.parse(questionTotal);
    bool isCorrect = selectedIndex == correctIndex;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.subjectName.isNotEmpty)
              Text(
                widget.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            if (widget.chapterName.isNotEmpty)
              Text(
                widget.chapterName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        actions: [
          InkWell(
            onTap: () {
              openDoubtDialog(context, question, widget.batchId, options);
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
                  Text("Raise Doubt", style: TextStyle(color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(Icons.question_mark, color: Colors.white, size: 18),
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
            LinearProgressIndicator(
              value: (currentIndex + 1) / int.parse(questionTotal),
            ),
            const SizedBox(height: 5),
            Text(
              "Question ${isValue ? currentIndex : currentIndex + 1}/$questionTotal",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: buildQuestionWidget(question),
              ),
            ),
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

              return Card(
                color: cardColor,
                margin: const EdgeInsets.only(bottom: 12),
                child: RadioListTile<int>(
                  title: buildOptionWidget(options[index].toString()),
                  value: index,
                  groupValue: selectedIndex,
                  onChanged: submitted
                      ? null
                      : (val) {
                          setState(() {
                            selectedIndex = val;
                          });
                        },
                  activeColor: isCorrect ? Colors.green : Colors.deepPurple,
                ),
              );
            }),
            const SizedBox(height: 20),
            if (submitted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isCorrect ? "Correct Answer!" : "Wrong Answer!",
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
            if (submitted && selectedIndex != correctIndex) ...[
              const SizedBox(height: 20),
              answerValue.toString() == "No explanation required"
                  ? const SizedBox()
                  : const Text(
                      "Explanation",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              const SizedBox(height: 10),
              if (answerType == "link" &&
                  (answerValue.toString().isNotEmpty || answerValue != null))
                GestureDetector(
                  onTap: () async {
                    final url = answerValue.toString();
                    final uri = Uri.tryParse(url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: answerValue.toString() == "No explanation required"
                      ? const SizedBox()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
              if ((answerType == "image" || answerType == "file") &&
                  answerValue.toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://truescoreedu.com/$answerValue",
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              if (answerType == "text" && answerValue.toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: buildQuestionText(answerValue.toString()),
                ),
            ],
            const SizedBox(height: 40),
            Row(
              children: [
                if (currentQu > 0)
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: currentIndex == 0
                            ? null
                            : () async {
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
                if (currentQu >= 1) const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (selectedIndex == null || isLoadingMore)
                          ? null
                          : () async {
                              if (!submitted) {
                                await _markAsAttempted();
                                setState(() {
                                  submitted = true;
                                });
                              } else {
                                await _nextQuestion(q['id'].toString());
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoadingMore
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              submitted ? "Next Question" : "Submit",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previousQuestion() async {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        currentQu--;
        selectedIndex = null;
        submitted = false;
      });
    }
  }

  // Future<void> _nextQuestion(String questionsId) async {
  //   saveProgressApi(questionsId);
  //   if (hasMore && !isLoadingMore && questions.length - currentIndex <= 3) {
  //     await fetchApiCourseQuestions(loadMore: true);
  //   }
  //   print("currentIndex--$currentIndex---${questions.length}---");
  //   if (currentIndex < questions.length - 1) {
  //     setState(() {
  //       currentIndex++;
  //       currentQu++;
  //       selectedIndex = null;
  //       submitted = false;
  //     });
  //     await _saveProgress();
  //   } else if (hasMore) {
  //     await fetchApiCourseQuestions(loadMore: true);
  //     if (currentIndex < questions.length - 1) {
  //       setState(() {
  //         currentIndex++;
  //         currentQu++;
  //         selectedIndex = null;
  //         submitted = false;
  //       });
  //       await _saveProgress();
  //     } else {
  //       _showCompletionDialog();
  //     }
  //   } else {
  //     _showCompletionDialog();
  //   }
  // }
  Future<void> _nextQuestion(String questionsId) async {
    saveProgressApi(questionsId);
    if ((questions.length - currentQu) <= 3) {
      isLoadingMore = false;
      hasMore = true;
      await fetchApiCourseQuestions(loadMore: true);
    }
    final int totalQuestions = int.tryParse(questionTotal) ?? 0;

    if (currentIndex >= totalQuestions - 1) {
      _showCompletionDialog();
      return;
    }

    if (hasMore && !isLoadingMore && (questions.length - currentQu) <= 3) {
      await fetchApiCourseQuestions(loadMore: true);
    }

    if (currentQu < questions.length - 1) {
      setState(() {
        currentIndex++;
        currentQu++;
        selectedIndex = null;
        submitted = false;
      });

      await _saveProgress();
      return;
    }

    if (hasMore) {
      await fetchApiCourseQuestions(loadMore: true);

      if (currentQu < questions.length - 1) {
        setState(() {
          currentIndex++;
          currentQu++;
          selectedIndex = null;
          submitted = false;
        });

        await _saveProgress();
        return;
      }
    }
    if (currentIndex >= totalQuestions - 1) {
      _showCompletionDialog();
    }
  }

  Future<void> saveProgressApi(String questionsId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/save-progress"),
        body: {
          "apiToken": token,
          "batch_id": widget.batchId,
          "subject_id": widget.subjectId,
          "chapter_id": widget.chapterId,
          "question_id": questionsId,
          "question_type": widget.questionType,
        },
      );

      if (kDebugMode) {
        log("saveProgressApi STATUS: ${response.statusCode}");
        log("saveProgressApi BODY: ${response.body}");
      }

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }
      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }
      if (response.body.trim().startsWith('<')) {
        throw Exception("Server returned HTML instead of JSON");
      }

      jsonDecode(response.body);
    } catch (e) {
      if (kDebugMode) log("saveProgressApi error--$e");
    }
  }
}

/// =================================================
/// SCREEN 2: CHAPTER LIST
/// =================================================

class ChapterListScreen extends StatefulWidget {
  final List<dynamic> chapters;
  final String batchId;
  final String questionType;
  final String subjectName;
  final String subjectId;
  final String chapterId;

  const ChapterListScreen({
    super.key,
    required this.chapters,
    required this.batchId,
    required this.questionType,
    required this.subjectName,
    required this.subjectId,
    required this.chapterId,
  });

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  List<String> _getChapters() {
    final set = <String>{};
    for (var q in widget.chapters) {
      final name = q['chapter_name']?.toString();
      set.add((name == null) ? "Syllabus" : name);
    }
    return set.toList();
  }

  Map<String, dynamic> _getChaptersData(chapterName) {
    return widget.chapters
        .firstWhere((element) => element['chapter_name'] == chapterName);
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _getChapters();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Select Chapter",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: chapters.isEmpty
          ? const Center(child: Text("No chapter available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final chapterData = _getChaptersData(chapter);
                bool isComplete = chapterData['complete'] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Material(
                    color: isComplete ? Colors.green.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: isComplete ? 0 : 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttemptPaperScreen(
                              questionType: widget.questionType,
                              batchId: widget.batchId,
                              subjectName: widget.subjectName,
                              subjectId: widget.subjectId,
                              chapterId: chapterData['chapter_id'].toString(),
                              attemptedCount:
                                  chapterData['attempted_count'].toString(),
                              chapterName: chapter,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isComplete
                                    ? Colors.green.withValues(alpha: .12)
                                    : Colors.purple.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isComplete
                                    ? Icons.check_circle
                                    : Icons.menu_book_rounded,
                                color:
                                    isComplete ? Colors.green : Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                chapter,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isComplete
                                      ? Colors.green.shade800
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isComplete)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  "Completed",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            if ((chapterData['question_count'] ?? '')
                                    .toString()
                                    .isNotEmpty &&
                                !isComplete)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${chapterData['question_count']}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
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

class SubjectListScreen extends StatefulWidget {
  final String courseId;
  final String questionType;

  const SubjectListScreen({
    super.key,
    required this.courseId,
    required this.questionType,
  });

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  List<dynamic> subjectsChapters = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApiCourseQuestions();
  }

  Future<void> fetchApiCourseQuestions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-course-subjects-chapters"),
        body: {
          "apiToken": token,
          "courseId": widget.courseId,
        },
      );

      if (kDebugMode) {
        log("fetchApiCourseQuestions STATUS: ${response.statusCode}");
        log("fetchApiCourseQuestions BODY: ${response.body}");
      }

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }

      if (response.body.trim().startsWith('<')) {
        throw Exception("Server returned HTML instead of JSON");
      }

      final data = jsonDecode(response.body);

      if (data["status"].toString() == "true") {
        subjectsChapters = data["data"] ?? [];
      }
    } on TimeoutException {
      print('error--Request timed out');
    } catch (e) {
      print('error--$e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<String> _getSubjects() {
    final Set<String> subjects = {};

    for (var q in subjectsChapters) {
      dynamic value = q['subject_name'];
      String subject;

      if (value == null) {
        subject = "Other Subjects";
      } else {
        subject = value.toString().trim();
        if (subject.isEmpty || int.tryParse(subject) != null) {
          subject = "Other Subjects";
        }
      }

      subjects.add(subject);
    }

    return subjects.toList();
  }

  List<dynamic> _bySubject(String subject) {
    return subjectsChapters.where((q) => q['subject_name'] == subject).toList();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _getSubjects();
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text(
          "Select Subject",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subjects.isEmpty
              ? const Center(child: Text("No subjects available"))
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final subjectQuestions = _bySubject(subject);
                    final Map<String, dynamic>? subjectMeta =
                        subjectsChapters.firstWhere(
                      (element) => element['subject_name'] == subject,
                      orElse: () => null,
                    );
                    final chaptersList =
                        List.from(subjectQuestions.first['chapters']);
                    bool isComplete = subjectMeta?['complete'] ?? false;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        if (chaptersList.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChapterListScreen(
                                chapters:
                                    subjectQuestions.first['chapters'] ?? [],
                                batchId: widget.courseId,
                                questionType: widget.questionType,
                                subjectName: subject,
                                subjectId:
                                    subjectMeta?['subject_id']?.toString() ??
                                        '',
                                chapterId:
                                    subjectMeta?['chapter_id']?.toString() ??
                                        '',
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AttemptPaperScreen(
                                questionType: widget.questionType,
                                batchId: widget.courseId,
                                subjectName: subject,
                                subjectId:
                                    subjectMeta?['subject_id']?.toString() ??
                                        '',
                                chapterId: '',
                                attemptedCount:
                                    subjectMeta?['attempted_count'] ?? '',
                                chapterName: '',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 86,
                        decoration: BoxDecoration(
                          color:
                              isComplete ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          spacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isComplete
                                    ? Colors.green.withValues(alpha: .12)
                                    : Colors.blue.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isComplete
                                    ? Icons.check_circle
                                    : Icons.menu_book_rounded,
                                color:
                                    isComplete ? Colors.green : Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subject,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isComplete
                                      ? Colors.green.shade800
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isComplete)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text(
                                  "Completed",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (chaptersList.isNotEmpty && !isComplete)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${chaptersList.length}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: Colors.grey,
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
