import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class McqScreen extends StatefulWidget {
  const McqScreen({super.key});

  @override
  State<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  List<dynamic> questions = [];
  int currentIndex = 0;
  String? selectedOption;
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  fetchQuestions() async {
    final response = await http.get(
      Uri.parse("https://truescoreedu.com/api/get-active-questions"),
    );

    if (response.statusCode == 200) {

     // print(response.body);
      setState(() {
        questions = jsonDecode(response.body);
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

    return Scaffold(
      appBar:
      AppBar(title: Text("Question ${currentIndex + 1}/${questions.length}"),),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---- Question Text ----
            Html(data: q["question"]),

            const SizedBox(height: 20),

            /// ---- Options List ----
            Column(
              children: List.generate(q["options"].length, (i) {
                String option = q["options"][i];
                String optionKey = String.fromCharCode(65 + i); // A,B,C,D

                return Card(
                  child: RadioListTile(
                    value: optionKey,
                    groupValue: selectedOption,
                    title: Html(data: option),
                    onChanged: (val) {
                      setState(() {
                        selectedOption = val.toString();
                        showResult = true;
                      });
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            /// ---- Show Answer Feedback ----
            if (showResult)
              Text(
                selectedOption == q["right_answer"]
                    ? "✔ Correct Answer"
                    : "✘ Wrong Answer",
                style: TextStyle(
                  fontSize: 18,
                  color: selectedOption == q["right_answer"]
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 90),

            /// ---- Show Answer Explanation (Image or Link) ----
            if (q["answer_type"] == "link"&& showResult)
              selectedOption == q["right_answer"]?SizedBox(): GestureDetector(
                onTap: () async {
                  final url = q["answer_value"].toString();
                  print(url);

                  // ensure this contains the link

                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication, // opens in browser
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Unable to open link")),
                    );
                  }
                },
                child: Container(height: 30,decoration: BoxDecoration(border: Border.all(color: Colors.blue),borderRadius: BorderRadius.circular(15)),
                  
                  child: Center(
                    child: const Text(
                      "  View Explanation  ",
                      style: TextStyle(
                        color: Colors.blue,
                        //decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),


            if (q["answer_type"] == "file"&& showResult)
              selectedOption == q["right_answer"]?SizedBox():   Image.network(
                "https://truescoreedu.com/${q["answer_value"]}",
                height: 150,
              ),

            const Spacer(),

            /// ---- Next Button ----
            Container(alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  if (currentIndex < questions.length - 1) {
                    setState(() {
                      currentIndex++;
                      selectedOption = null;
                      showResult = false;
                    });
                  }
                },
                child: const Text("Next Question"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
