import 'package:flutter/material.dart';
import '../../ThemeConstent/themeData.dart';
import '../NotesList/NotesListScreen.dart';
import '../PDFList/PDFListScreen.dart';
import '../VideosContent/VideosContent_Screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String name;

  CourseDetailScreen({required this.name});


  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final String courseTitle = "SSC CGL Complete Preparation";

  /// to check user is enrolled orr not
  bool isUserEnrolled = false;

  final String courseDescription =
      "A complete guide for SSC CGL exam covering all subjects with mock tests and expert mentorship.";

  final String duration = "6 Months";

  final String price = "₹6,999";

  final List<String> topics = [
    "Quantitative Aptitude",
    "Reasoning Ability",
    "English Language",
    "General Awareness",
    "Mock Tests",
    "Previous Year Papers",
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: Text(
            "Course Details",
            style: TextStyle(color: AppTheme.iconColor2),
          ),
          iconTheme: const IconThemeData(color: AppTheme.iconColor2),
          backgroundColor: AppTheme.primeryColor,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black87,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: "Course"),
              Tab(text: "Videos"),
              Tab(text: "PDF"),
              Tab(text: "Notes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCourseDetails(context), // Course tab
            VideoListScreen(isUserEnrolled: isUserEnrolled ),        // Videos tab
            PDFListScreen(isUserEnrolled: isUserEnrolled),           // PDF tab
            NotesListScreen(isUserEnrolled: isUserEnrolled),         // Notes tab
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDetails(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // space for the button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                "assets/images/s5.png",
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("A complete guide for ${widget.name} exam covering all subjects with mock tests and expert mentorship.",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.schedule),
                        SizedBox(width: 8),
                        Text("Duration: $duration"),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money),
                        SizedBox(width: 8),
                        Text("Price: $price"),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text("What you'll learn:",
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ...topics.map((topic) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(child: Text(topic)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 0,
          left: 0,
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primeryColor,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() {
                  isUserEnrolled = true;
                });
              },
              child: Text("Enroll Now",
                  style: TextStyle(fontSize: 16, color: Colors.green)),
            ),
          ),
        ),
      ],
    );
  }
}
