import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FreeCoursesScreen extends StatefulWidget {
  const FreeCoursesScreen({super.key});

  @override
  State<FreeCoursesScreen> createState() => _FreeCoursesScreenState();
}

class _FreeCoursesScreenState extends State<FreeCoursesScreen> {
  bool isLoading = true;
  List freeCourses = [];

  @override
  void initState() {
    super.initState();
    fetchFreeCourses();
  }

  Future<void> fetchFreeCourses() async {
    final url = Uri.parse("https://truescoreedu.com/api/get-batches");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded"
        },
        body: {
          "apiToken":
          "42065ca57e8859475dc0ceb6c1df197d53041adef155fb1097142aa053cea519",
          "type": "free",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == "true") {
        setState(() {
          freeCourses = data["data"]["freeCourses"];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Free Courses"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : freeCourses.isEmpty
          ? const Center(
        child: Text(
          "No Free Courses Found",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: freeCourses.length,
          itemBuilder: (context, index) {
            final course = freeCourses[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Image (If available)
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade200,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      image: course["batch_image"] != ""
                          ? DecorationImage(
                        image: NetworkImage(
                            "https://truescoreedu.com/${course["batch_image"]}"),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: course["batch_image"] == ""
                        ? const Center(
                      child: Icon(Icons.book,
                          size: 50, color: Colors.white),
                    )
                        : null,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course["batch_name"] ?? "",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${course["cat_name"]} • ${course["sub_cat_name"]}",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 18, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              "Start: ${course["start_date"]}",
                              style: TextStyle(
                                  color: Colors.grey.shade800),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(Icons.timer,
                                size: 18, color: Colors.deepPurple),
                            const SizedBox(width: 6),
                            Text(
                              "${course["start_time"]} - ${course["end_time"]}",
                              style: TextStyle(
                                  color: Colors.grey.shade800),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Enroll Now",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }
}
