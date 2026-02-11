import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/Screens/AddQuestionsScreen.dart';
import 'package:online_classes/Screens/Auth/asktype.dart';
import 'package:online_classes/Screens/Student/notificcationstudents.dart';
import 'package:online_classes/Screens/Student/purchasedcourses.dart';
import 'package:online_classes/Screens/Student/result.dart';
import 'package:online_classes/Screens/Student/videos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../mcq.dart';
import '../../servcies.dart';
import '../All Courses.dart';
import '../Auth/signinScreen.dart';
import '../MCQQuestion.dart';
import '../Notification/notificationScreen.dart';
import '../Question.dart';
import '../SearchScreen.dart';
import 'ADDdoubtsbystudents.dart';
import 'ALLNewCourses.dart';
import 'carddeatils.dart';
import 'courses.dart';
import 'getnotes.dart';
import 'mydoubts.dart'; // Keep if you still need it

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();

}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {

  Map<String, dynamic>? apiData;
  bool isLoading = true;
  String sname = '';
  String simage = '';
  Map<String, dynamic>? apiData1;
  bool loading = true;
  List<dynamic> notices = [];

  Future<void> fetchNotices() async {
    setState(() => isLoading = true);

    SharedPreferences pref = await SharedPreferences.getInstance();
    String apiToken = pref.getString("token") ?? "";

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/active-notices"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": apiToken},
      );

      print("NOTICE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == 1) {
          setState(() => notices = data["data"]);
        }
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }



  @override
  void initState() {
    super.initState();
    SecureScreen.enable();

    fetchDashboardData();
    getname();
    fetchCourses();
    fetchNotices();
  }

  Future<void> fetchCourses() async {
    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-batches"),
        body: {
          if (token != null) "apiToken": token,
          "type": "free",
        },
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (decoded is Map && decoded["data"] != null) {
        setState(() {
          apiData1 = decoded["data"];
          loading = false;
        });
      } else {
        setState(() {
          apiData1 = {};
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        apiData1 = {};
        loading = false;
      });
    }
  }


  getname() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('studentname').toString();
    final image = prefs.getString('studentimage').toString();
    setState(() {
      sname = name;
      simage = image;
    });
  }

  Future<void> fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    print(token);
    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-batches"),
        body: {"apiToken": token, "type": "free"},
      );
      if (response.statusCode == 200) {
        print('yes');
        final json = jsonDecode(response.body);
        print(json);
        if(json['msg'].toString()=="Invalid Token"){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SigninScreen()));
        }

        setState(() {
          apiData = json["data"];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    SecureScreen.disable();

    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = apiData1?["categories"] ?? [];
    final courses = [
      ...?apiData?["trendingCourses"],
      ...?apiData?["freeCourses"],
      ...?apiData?["newCourses"],
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),

        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Ionicons.notifications_outline,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationScreen1()),
                  );
                },
              ),

              // 🔴 Red Dot
              if (notices.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),


          const SizedBox(width: 10),

        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting with name (small text)
            Row(
              children: [
                if (simage.isNotEmpty)
                  // CircleAvatar(
                  //   radius: 20,
                  //   backgroundImage: NetworkImage(simage),
                  // ),
                const SizedBox(width: 12),
                Text(
                  "Hi, $sname",
                  style: const TextStyle(fontSize: 26, color: Colors.black),
                ),

              ],
            ),
            const SizedBox(height: 20),
            // Find your lesson today
            const Text(
              "Find your Courses today",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Search bar
            TextField(
              readOnly: true, // Important: Prevents keyboard from opening
              onTap: () {
                // Navigate to the Course Search Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CourseSearchScreen(),
                  ),
                );
              },
              decoration: InputDecoration(
                hintText: "Search Courses...",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            const SizedBox(height: 15),
            // Explore section
            // const Text(
            //   "Explore",
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Course Categories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            if (categories.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final cat = categories[index] ?? {};
                    final name = cat["name"]?.toString() ?? "Category";
                    final id = cat["id"]?.toString() ?? "";

                    return InkWell(
                      onTap: id.isEmpty
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryDetailScreen(
                              categoryId: id,
                              categoryName: name,
                              allData: apiData ?? {},
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Material(
                            elevation: 2,
                            shape: const CircleBorder(),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              height: 80,
                              width: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blueAccent,
                              ),
                              child: const Icon(Icons.menu_book,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 80,
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // Container(height: 100,width: double.maxFinite
            //   ,decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(20),color: Colors.blueAccent
            //   ),)

            // GridView.count(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   crossAxisCount: 4,
            //   mainAxisSpacing: 16,
            //   crossAxisSpacing: 16,
            //   children: [
            //     InkWell(
            //       onTap: () => Navigator.push(
            //           context, MaterialPageRoute(builder: (_) => const CoursesScreen())),
            //       child: _dashboardButton(Icons.book_outlined, "Courses"),
            //     ),
            //     InkWell(
            //       onTap: () => Navigator.push(
            //           context, MaterialPageRoute(builder: (_) => const PaperTypeScreen())),
            //       child: _dashboardButton(Icons.assignment_outlined, "MCQ Test"),
            //     ),
            //     InkWell(
            //       onTap: () => Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //               builder: (_) => ResultScreen(paperId: '2', paperType: '2'))),
            //       child: _dashboardButton(Icons.person_outline, "Result"),
            //     ),
            //     InkWell(
            //       onTap: () {
            //         Navigator.push(
            //             context, MaterialPageRoute(builder: (context) => AskType()));
            //       },
            //       child: _dashboardButton(Icons.logout, "Logout"),
            //     ),
            //     InkWell(
            //       onTap: () => Navigator.push(
            //           context, MaterialPageRoute(builder: (_) => CreateDoubtScreen())),
            //       child: _dashboardButton(Icons.query_stats_sharp, "Add Doubts"),
            //     ),
            //     InkWell(
            //       onTap: () => Navigator.push(
            //           context, MaterialPageRoute(builder: (_) => MyDoubtsScreen())),
            //       child: _dashboardButton(Icons.assignment_outlined, "My Doubts"),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 30),
            // Courses in horizontal card view
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Courses",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AllCoursesScreen())),
                  child: const Text("See all", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (apiData != null)
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: courses.length > 3 ? 3 : courses.length, // ✅ SAFE
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width / 2 - 20,
                        child: _recommendedCourseCard(course),
                      ),
                    );
                  },
                ),
              )

            else
              const Center(child: Text("No courses available")),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Reusable Dashboard Button Widget (updated for blue theme)
  _dashboardButton(IconData icon, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(blurRadius: 12, offset: const Offset(0, 4), color: Colors.black12),
            ],
          ),
          child: Icon(icon, size: 28, color: Colors.blue),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget testoraBannerCard() {
    return InkWell(onTap: (){
     // Navigator.push(context, MaterialPageRoute(builder: (context)=>Videos()));
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
                        "Practice paper",
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

  /// 🔹 Decorative circle widget
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


  // Recommended Course Card - Updated style for modern UI, blue accents
  _recommendedCourseCard(dynamic item) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>CourseDetailScreen2(courseData: item,)));
        // Navigate to course detail if needed
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),

        ),
        child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                image: item["batch_image"] != null
                    ? DecorationImage(image:
                NetworkImage('https://truescoreedu.com/uploads/batch_image/${item["batch_image"]}'), fit: BoxFit.cover)
                    : null,
              ),
              child: item["batch_image"] == null
                  ? const Icon(Icons.menu_book, size: 36, color: Colors.blue)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              item["batch_name"] ?? "Untitled Course",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "${item["cat_name"] ?? ""} • ${item["sub_cat_name"] ?? ""}",
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}