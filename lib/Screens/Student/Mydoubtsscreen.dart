import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GetDoubtsScreenstudent extends StatefulWidget {
  const GetDoubtsScreenstudent({super.key});

  @override
  State<GetDoubtsScreenstudent> createState() => _GetDoubtsScreenstudentState();

}

class _GetDoubtsScreenstudentState extends State<GetDoubtsScreenstudent> {
  bool isLoading = true;
  List<dynamic> doubts = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDoubts();
  }

  Future<void> fetchDoubts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Change key if needed (e.g., 'authToken')

    if (token == null) {
      setState(() {
        errorMessage = "Please login again";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://testora.codeeratech.in/api/get-doubts"),
        body: {
          "apiToken": token,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print(json);

        if (json['status'] == 1) {
          setState(() {
            doubts = json['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = json['msg'] ?? "No doubts found";
            isLoading = false;
          });
        }
      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load doubts. Check your connection.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "My Doubts",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        )
            : errorMessage != null
            ? _errorState()
            : doubts.isEmpty
            ? _emptyState()
            : RefreshIndicator(
          onRefresh: fetchDoubts,
          color: Colors.blue,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doubts.length,
            itemBuilder: (context, index) {
              final doubt = doubts[index];
              final String question =
                  doubt["description"] ?? "No question";
              final String answer =
                  doubt["teacher_description"] ?? "";

              return _doubtCard(question, answer);
            },
          ),
        ),
      ),
    );
  }
  Widget _doubtCard(String question, String answer) {
    return Container(height: 220,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar
          Container(
            width: 5,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question chip
                  Row(
                    children: [
                      Icon(Icons.help_outline,
                          size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      const Text(
                        "Question",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  if (answer.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 6),

                    // Answer chip
                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline,
                            size: 18, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          "Answer",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      answer,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchDoubts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer_outlined,
              size: 90, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text(
            "No doubts yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your questions will appear here",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }




}