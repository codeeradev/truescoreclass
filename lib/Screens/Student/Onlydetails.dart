import 'package:flutter/material.dart';
import 'package:online_classes/Screens/Student/percentage.dart';
import 'package:online_classes/Screens/Student/videos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../servcies.dart';
import '../../videofull.dart';
import '../Youtubeplayer.dart';
import 'getnotes.dart';
import 'newques.dart';

class PurchasedCourseVideosScreen extends StatefulWidget {
  final String courseId;
  const PurchasedCourseVideosScreen({super.key, required this.courseId});

  @override
  State<PurchasedCourseVideosScreen> createState() => _PurchasedCourseVideosScreenState();
}

class _PurchasedCourseVideosScreenState extends State<PurchasedCourseVideosScreen>
    with TickerProviderStateMixin {
  bool isLoading = true;
  bool isPurchased = false;
  Map<String, dynamic>? courseData;
  List<dynamic> videoLectures = [];
  List<dynamic> allQuestions = [];
  String? errorMessage;

  late TabController _tabController;
  List<String> availableTabs = [];
  bool isLoading2 = true;
  List<dynamic> notes = [];
  //String? errorMessage;
  Future<void> fetchNotes() async {
    setState(() {
      isLoading2 = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        errorMessage = "Please login again";
        isLoading2 = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-notes"),
        body: {
          "apiToken": token,
          "course_id":widget.courseId.toString()
        },
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 1) {
          setState(() {
            notes = json['notes'] ?? [];
            isLoading2 = false;
          });
        } else {
          setState(() {
            errorMessage = json['message'] ?? "No notes found";
            isLoading2 = false;
          });

        }

      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load notes. Check your connection.";
        isLoading2 = false;
      });
    }
  }

  Map<String, List<dynamic>> questionsByType = {
    "MCQ": [],
    "Current Affairs": [],
    "PYQ": [],
  };

  @override
  void initState() {

    super.initState();
    SecureScreen.enable();

    fetchCourseDetails();
    fetchNotes();
  }

  Future<void> fetchCourseDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');


    if (token == null) {
      setState(() {
        errorMessage = "You are not logged in.";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-batche-details"),
        body: {
          "apiToken": token,
          "courseId": widget.courseId,
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "true" && data["data"]["isPurchased"] == true) {
        setState(() {
          isPurchased = true;
          courseData = data["data"]["course"];
          videoLectures = data["data"]["videoLectures"] ?? [];
          allQuestions = data["data"]["questions"] ?? [];

          // Group questions by type
          questionsByType = {"MCQ": [], "Current Affairs": [], "PYQ": []};
          availableTabs.clear();

          for (var q in allQuestions) {
            String type = q["question_type"]?.toString() ?? "1";
            List<dynamic> targetList;
            String tabName;

            if (type == "1") {
              tabName = "MCQ";
              targetList = questionsByType["MCQ"]!;
            } else if (type == "2") {
              tabName = "Current Affairs";
              targetList = questionsByType["Current Affairs"]!;
            } else if (type == "3") {
              tabName = "PYQ";
              targetList = questionsByType["PYQ"]!;
            } else {
              continue;
            }

            targetList.add(q);
            if (!availableTabs.contains(tabName)) availableTabs.add(tabName);
          }

          // Sort tabs: MCQ → Current Affairs → PYQ
          availableTabs.sort((a, b) {
            List<String> order = ["MCQ", "Current Affairs", "PYQ"];
            return order.indexOf(a).compareTo(order.indexOf(b));
          });

          _tabController = TabController(length: availableTabs.length, vsync: this);
          isLoading = false;
        });
      } else {
        setState(() {
          isPurchased = false;
          errorMessage = data["msg"] ?? "Course not purchased.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Network error. Please try again.";
        isLoading = false;
      });
    }
  }

  Widget testoraBannerCard() {
    return InkWell(onTap: (){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>Videos(id: widget.courseId.toString(),)));
    },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB), // deep blue
              Color(0xFF3B82F6), // light blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// 🔵 Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: _decorCircle(120, Colors.white.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: _decorCircle(100, Colors.white.withOpacity(0.08)),
            ),

            /// CONTENT
            Row(
              children: [
                /// ICON CONTAINER
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.question_answer,
                    size: 30,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 16),

                /// TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Exams",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                    ],
                  ),
                ),

                /// RIGHT DECOR ICON
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _decorCircle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  @override
  void dispose() {
    SecureScreen.disable();

    if (availableTabs.isNotEmpty) _tabController.dispose();
    super.dispose();
  }

  Widget buildQuestionCard(dynamic question) {
    final String ques = question["question"] ?? "No question";
    final List<dynamic> options = question["options"] ?? [];
    final String rightAnswer = question["right_answer"] ?? "";
    final int correctIndex = "ABCD".indexOf(rightAnswer);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ques,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...List.generate(options.length, (index) {
              final String optionLetter = String.fromCharCode(65 + index);
              final bool isCorrect = index == correctIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          optionLetter,
                          style: TextStyle(
                            color: isCorrect ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[index] ?? "",
                        style: TextStyle(
                          fontSize: 15,
                          color: isCorrect ? Colors.green[800] : Colors.black87,
                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrect) const Icon(Icons.check, color: Colors.green, size: 22),
                  ],
                ),
              );
            }),
            const Divider(height: 30),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Correct Answer: $rightAnswer",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.blue, title: const Text("Loading...", style: TextStyle(color: Colors.white))),
        body: const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (!isPurchased) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.blue, title: const Text("Access Denied", style: TextStyle(color: Colors.white))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey[600]),
                const SizedBox(height: 20),
                Text(errorMessage ?? "You don't have access.", style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back")),
              ],
            ),
          ),
        ),
      );
    }

    final String batchName = courseData!["batch_name"] ?? "Course";
    final String category = courseData!["cat_name"] ?? "";
    final String subCategory = courseData!["sub_cat_name"] ?? "";
    final String description = (courseData!["description"] ?? "").toString().replaceAll("null", "").trim();
    final String imageUrl = courseData!["batch_image"] ?? "";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text("My Course", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            Container(color: Colors.blue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 30, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text("Congrats for this course!",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),

                ],
              ),
            ),

            // Course Image
            // Container(
            //   width: double.infinity,
            //   height: 220,
            //   decoration: BoxDecoration(
            //     color: Colors.blue.shade50,
            //     image: imageUrl.isNotEmpty
            //         ? DecorationImage(
            //       image: NetworkImage("https://truescoreedu.com/uploads/batch_image/$imageUrl"),
            //       fit: BoxFit.cover,
            //     )
            //         : null,
            //   ),
            //   child: imageUrl.isEmpty ? const Icon(Icons.menu_book_rounded, size: 80, color: Colors.blue) : null,
            // ),


            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batchName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("$category ${subCategory.isNotEmpty ? '• $subCategory' : ''}",
                      style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 20),

                  // Purchased Success

                  const SizedBox(height: 30),
                  InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>CourseProgressScreen(batchId: widget.courseId.toString(),)));
                    },
                    child: Container(decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),color: Colors.blueAccent
                    ),height: 50,child: Center(child: Text("Progress",style: TextStyle(color: Colors.white),))
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      // _optionCard(
                      //   title: "MCQ",
                      //   icon: Icons.quiz_rounded,
                      //   color: const Color(0xFF4F46E5),
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (_) => QuestionTypeSelectionScreen(
                      //           questions: allQuestions,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                      videoLectures.length==0?SizedBox():_optionCard(
                        title: "Videos",
                        icon: Icons.play_circle_fill_rounded,
                        color: const Color(0xFF16A34A),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>VideoListScreenfull(videoLectures: videoLectures,)));


                        },
                      ),
                      notes.isEmpty?SizedBox(): _optionCard(
                        title: "Notes",
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFFF97316),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>GetNotesScreen(batchid: widget.courseId.toString(),)));
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 30,),
                  Container(
                    height: 420,
                    child:  QuestionTypeSelectionScreen(
                      questions: allQuestions, batchId: widget.courseId.toString(),
                    ),
                  ),
                  testoraBannerCard(),


                  // Description
                  // if (description.isNotEmpty) ...[
                  //   const Text("About this Course", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  //   const SizedBox(height: 10),
                  //   Text(description, style: const TextStyle(fontSize: 15, height: 1.6)),
                  //   const SizedBox(height: 30),
                  // ],

                  // Video Lectures
                  // if (videoLectures.isNotEmpty) ...[
                  //   const Text("Video Lectures", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  //   const SizedBox(height: 12),
                  //   ListView.builder(
                  //     shrinkWrap: true,
                  //     physics: const NeverScrollableScrollPhysics(),
                  //     itemCount: videoLectures.length,
                  //     itemBuilder: (context, index) {
                  //       final video = videoLectures[index];
                  //       final String title = video["title"] ?? "Untitled";
                  //       final String url = video["url"] ?? "";
                  //
                  //       return Card(
                  //         margin: const EdgeInsets.symmetric(vertical: 8),
                  //         child: ListTile(
                  //           leading: Container(
                  //             width: 50,
                  //             height: 50,
                  //             decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                  //             child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 34),
                  //           ),
                  //           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  //           subtitle: Text(video["subject"] ?? "", style: TextStyle(color: Colors.grey[600])),
                  //           trailing: const Icon(Icons.arrow_forward_ios),
                  //           onTap: url.isNotEmpty
                  //               ? () => Navigator.push(
                  //             context,
                  //             MaterialPageRoute(
                  //               builder: (_) => VideoPlayerScreen(videoTitle: title, youtubeUrl: url),
                  //             ),
                  //           )
                  //               : null,
                  //         ),
                  //       );
                  //     },
                  //   ),
                  //   const SizedBox(height: 30),
                  // ],
                  //
                  // // Practice Questions (at bottom)
                  // if (availableTabs.isNotEmpty) ...[
                  //   const Text("Practice Questions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  //   const SizedBox(height: 16),
                  //   TabBar(
                  //     controller: _tabController,
                  //     isScrollable: availableTabs.length > 2,
                  //     labelColor: Colors.blue,
                  //     unselectedLabelColor: Colors.grey,
                  //     indicatorColor: Colors.blue,
                  //     tabs: availableTabs.map((tab) => Tab(text: tab)).toList(),
                  //   ),
                  //   SizedBox(
                  //     height: 600,
                  //     child: TabBarView(
                  //       controller: _tabController,
                  //       children: availableTabs.map((tabName) {
                  //         final questions = questionsByType[tabName] ?? [];
                  //         return ListView.builder(
                  //           padding: const EdgeInsets.only(top: 16),
                  //           itemCount: questions.length,
                  //           itemBuilder: (context, index) => buildQuestionCard(questions[index]),
                  //         );
                  //       }).toList(),
                  //     ),
                  //   ),
                  // ] else ...[
                  //   const Center(
                  //     child: Text("No practice questions available yet.", style: TextStyle(color: Colors.grey)),
                  //   ),
                  // ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}