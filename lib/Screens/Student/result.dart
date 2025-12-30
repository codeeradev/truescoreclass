import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ResultScreen extends StatefulWidget {
  final String paperId;
  final String paperType;

  const ResultScreen({
    super.key,
    required this.paperId,
    required this.paperType,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool loading = true;
  String errorMsg = "";
  Map resultData = {};

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
        Uri.parse("https://testora.codeeratech.in/api/answer-sheet"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "apiToken": token,
          "paper_id": widget.paperId,
          "paper_type": widget.paperType,
        },
      );

      final json = jsonDecode(response.body);
      print("RESULT JSON: $json");

      if (json["status"] == "1") {
        resultData = json["data"];
      } else {
        errorMsg = json["msg"];
      }
    } catch (e) {
      errorMsg = "Error: $e";
    }

    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(errorMsg)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Result"),
        centerTitle: true,
      ),
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
                  colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Overall Score",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${resultData['percentage']}%",
                    style: const TextStyle(
                      fontSize: 42,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Attempted: ${resultData['attempted_question']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Date: ${resultData['date']}",
                    style: const TextStyle(color: Colors.white60),
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

            ...resultData["question_answer"].entries.map((e) {
              String qid = e.key;
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
                    Text("Q$qid",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),

                    Row(
                      children: [
                        const Text("Your Answer: ",
                            style: TextStyle(fontSize: 14)),
                        Text(
                          ans,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
