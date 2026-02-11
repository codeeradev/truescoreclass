import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class McqScreen1 extends StatefulWidget {
  const McqScreen1({super.key});

  @override
  State<McqScreen1> createState() => _McqScreen1State();
}

class _McqScreen1State extends State<McqScreen1> {
  List questions = [];
  int currentIndex = 0;
  int? selectedOptionId; // User selected option
  bool answered = false; // Once selected answer freeze UI

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final url =
        "https://truescoreedu.com/api/questions?exam_type=mock_test&class_id=1";

    final res = await http.get(Uri.parse(url),headers: {
      "Content-Type": "application/json",
      "Authorization": token.toString()
      // "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiYzU1ZTA2YzQxM2Q3YzQxZWVhNTJkYWY4ZjU1NzNkOThjNTk1MTg4ZDdlZGM4Mzg3YTdmYWI3YmJjMzFlYWRiYjA0NWZlMjU2ODAxNWJmNjciLCJpYXQiOjE3NjM3MDc1MDIuMzMxMzksIm5iZiI6MTc2MzcwNzUwMi4zMzEzOTIsImV4cCI6MTc5NTI0MzUwMi4zMjg4ODYsInN1YiI6IjMiLCJzY29wZXMiOltdfQ.aAwJOaOGFewds5_sk-3IjerKjob2PM63Qe5YkhsVvqaFQ4JHnpNycD1Pi8i6brszIf0jhSoo3GHPsKtrMzkvPwneZuDTMrsUEVEuGBwEKd05zrhpJcfTlOMTV9YiWOlFn0IHAkB1U7g7lM0YXqLY-NYuMEcZkObQNfvWoHK8LKK4hebyN9YEunaTnO7x54TXra9juor_DT3so0o0T7N__6Nf4Hrhd8LV7BDZo48p7fhG3kKdSLiAOm9GkckIWO54Hux5KL8IAcVAK0v_QIoDlDp42iRLc4qAGysjCCn7KSeJhKcMsYCnR1c4EV4SVjggtePjj_69gFnoJLV9XcWmeIRSnScuEiN6KOGAOxWGJlFwzyN9Rm6fR6rkyKfOh7ks9oZPzs9akk0zvPiFN46UTD0MKj5942RIX2K3Jjrskajte3pxqKZDC8P-jxCgBX4ufH49dJvXolE2f4xZkns3DjPJg1-SJ1cRrbL3uWkRrknOA8wZPXzXRwDF02GRLxaY-3_VbHsaznZJLFEzwR4z5fCQsVLnNxXb77kCZ39DuzZSYrvBgcuV-nU3dKDeInxVP_Ye2ON8rVTC4JihSWXi8ouM9pY9trvGaiZL2r7O8ALl8sl9M7o-WxuwgSVEyJTK1IMbKy_695FgzaHMwpn3thFL9PXBvfIBdauLHOOxT3w",
    }
    );
    print(res.body);

    if (res.statusCode == 200) {
      setState(() {
        questions = jsonDecode(res.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final q = questions[currentIndex];
    final List options = q["options"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mock Test"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟦 marks at top
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Marks: ${q["marks"]}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Question text
            Text(
              "${currentIndex + 1}. ${q["question"]}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // OPTIONS LIST
            ...options.map((op) {
              bool isCorrect = op["is_correct"];
              bool isSelected = selectedOptionId == op["id"];

              Color borderColor = Colors.grey.shade300;
              IconData? icon;
              Color? iconColor;

              if (answered) {
                if (isSelected && isCorrect) {
                  borderColor = Colors.green;
                  icon = Icons.check_circle;
                  iconColor = Colors.green;
                } else if (isSelected && !isCorrect) {
                  borderColor = Colors.red;
                  icon = Icons.cancel;
                  iconColor = Colors.red;
                } else if (!isSelected && isCorrect) {
                  // Show correct answer after selecting wrong
                  borderColor = Colors.green;
                  icon = Icons.check_circle;
                  iconColor = Colors.green;
                }
              }

              return GestureDetector(
                onTap: answered
                    ? null
                    : () {
                  setState(() {
                    selectedOptionId = op["id"];
                    answered = true;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: answered
                            ? (isCorrect
                            ? Colors.green
                            : isSelected
                            ? Colors.red
                            : Colors.grey)
                            : Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          op["title"],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (icon != null)
                        Icon(icon, color: iconColor, size: 26),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 15),

            // Show wrong explanation
            if (answered)
              _buildExplanation(q),

            const Spacer(),

            // Next button
            if (answered)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (currentIndex < questions.length - 1) {
                    setState(() {
                      currentIndex++;
                      selectedOptionId = null;
                      answered = false;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Test Finished!")),
                    );
                  }
                },
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(dynamic q) {
    bool userCorrect = q["options"]
        .any((op) => op["id"] == selectedOptionId && op["is_correct"]);

    if (userCorrect) return const SizedBox(); // No need to show explanation

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Correct Answer Explanation:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        if (q["right_answer_type"] == "file")
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              "https://truescoreedu.com/${q["right_answer_document"]}",
              height: 180,
              fit: BoxFit.cover,
            ),
          ),

        if (q["right_answer_type"] == "link")
          InkWell(
            onTap: () => launchUrl(
                Uri.parse(q["right_answer_document"]),
                mode: LaunchMode.externalApplication),
            child: const Text(
              "Open Answer Explanation",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}
