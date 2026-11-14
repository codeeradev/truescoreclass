import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ResultScreen extends StatefulWidget {
  final String paperId;
  final String paperType;
  final bool showTryAgain;

  const ResultScreen({
    super.key,
    required this.paperId,
    required this.paperType,
    this.showTryAgain = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool loading = true;
  String errorMsg = "";
  Map resultData = {};
  int correctAnswers = 0;
  int wrongAnswers = 0;

  @override
  void initState() {
    super.initState();
    fetchResult();
  }

  Future<void> fetchResult() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/answer-sheet"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "apiToken": token,
          "paper_id": widget.paperId,
          "paper_type": widget.paperType,
        },
      );
if(response.body.trim().isEmpty){

  throw Exception('response is empty');
}
      final json = jsonDecode(response.body);
      print("response ${response.body}");

      if (json["status"] == "1") {
        resultData = json["data"];

          correctAnswers = json['data']['right_question'] ?? 0;
          wrongAnswers = json['data']['wrong_question'] ?? 0;

      } else {
        errorMsg = json["msg"];
      }
    } catch (e) {
      print("error---$e");
      errorMsg = "Error: $e";
    }

    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMsg.isNotEmpty) {
      return Scaffold(body: Center(child: Text(errorMsg)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Your Result"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🎯 SCORE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0f0c29),
                    Color(0xFF302b63),
                    Color(0xFF24243e),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Overall Score",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${resultData['percentage']}%",
                    style: const TextStyle(
                      fontSize: 44,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      /// Correct Answers
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.greenAccent,
                                size: 30,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "$correctAnswers",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Correct",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// Wrong Answers
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cancel_rounded,
                                color: Colors.redAccent,
                                size: 30,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "$wrongAnswers",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Wrong",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    height: 1,
                    color: Colors.white24,
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.quiz_outlined,
                            size: 17,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Attempted: ${resultData['attempted_question']}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${resultData['date']}",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📌 Detailed Answer List
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Your Answers",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
            const SizedBox(height: 10),

            ...resultData["question_answer"].entries
                .toList()
                .asMap()
                .entries
                .map((entry) {
                  int index = entry.key; // index number
                  var e = entry.value;

                  String ans = e.value;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Question index
                        Text(
                          "Q${index + 1}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        Row(
                          children: [
                            const Text(
                              "Your Answer: ",
                              style: TextStyle(fontSize: 14),
                            ),

                            Text(
                              ans,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                })
                .toList(),

            if (widget.showTryAgain) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, "retry");
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
