import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
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
import '../Teachers/screens/getmeeting.dart';
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

  List<dynamic> liveClasses = [];
  bool isLoading1 = true;
  bool hasError = false;

  Future<void> fetchLiveClasses() async {
    setState(() {
      isLoading1 = true;
      hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception("Token not found");
      }

      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/get-live-class'),
        body: {"apiToken": token},
      );
      print('chck');
      print(response.body);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 1) {
          setState(() {
            liveClasses = jsonData['data'] ?? [];
          });
        } else {
          throw Exception(jsonData['msg'] ?? "Failed to fetch classes");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => hasError = true);

      debugPrint("Error fetching live classes: $e");

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text("Failed to load live classes: $e")),
      // );
    } finally {
      setState(() => isLoading1 = false);
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
    fetchLiveClasses();
    initNotificationListener();
  }

  Future<void> fetchCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-batches"),
        body: {if (token != null) "apiToken": token, "type": "free"},
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
        if (json['msg'].toString() == "Invalid Token") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SigninScreen()),
          );
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

  bool hasNewNotice = false;
  int newNoticeCount = 0;

  void initNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await fetchNotices();
    });
  }

  Future<void> fetchNotices() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String apiToken = pref.getString("token") ?? "";

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/active-notices"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": apiToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == 1) {
          List<dynamic> notices = data["data"] ?? [];

          int currentCount = notices.length;

          int lastCount = pref.getInt("last_notice_count") ?? 0;
          setState(() {
            newNoticeCount =
                currentCount > lastCount ? currentCount - lastCount : 0;
          });
          print(
            "currentCount--$currentCount---lastCount$lastCount--newNoticeCount$newNoticeCount",
          );
        }
      }
    } catch (e) {
      print("Error: $e");
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
      ...?apiData?["purchasedCourses"],
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen1(),
                    ),
                  );
                  setState(() {
                    newNoticeCount = 0;
                  });
                },
              ),

              if (newNoticeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen1(),
                        ),
                      );
                      setState(() {
                        newNoticeCount = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$newNoticeCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 10),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    liveClasses.isEmpty
                        ? SizedBox()
                        : InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => getclassscreen(),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            height: 50,
                            width: double.maxFinite,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Check Your Google Meeting',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 20),

                    // Find your lesson today
                    const Text(
                      "Find your Courses today",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    TextField(
                      readOnly:
                          true, // Important: Prevents keyboard from opening
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
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.blue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                              onTap:
                                  id.isEmpty
                                      ? null
                                      : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => CategoryDetailScreen(
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
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      height: 80,
                                      width: 80,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blueAccent,
                                      ),
                                      child: const Icon(
                                        Icons.menu_book,
                                        color: Colors.white,
                                        size: 32,
                                      ),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AllCoursesScreen(),
                                ),
                              ),
                          child: const Text(
                            "See all",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (courses.isNotEmpty)
                      SizedBox(
                        height: 210,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width:
                                    (MediaQuery.of(context).size.width - 56) /
                                    2.2,
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
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 4),
                color: Colors.black12,
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: Colors.blue),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget testoraBannerCard() {
    return InkWell(
      onTap: () {
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // Recommended Course Card - Updated style for modern UI, blue accents
  _recommendedCourseCard(dynamic item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen2(courseData: item),
          ),
        );
        // Navigate to course detail if needed
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,

              height: 100,

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),

                color: Colors.white,

                image:
                    item["batch_image"] != null
                        ? DecorationImage(
                          image: NetworkImage(
                            'https://truescoreedu.com/uploads/batch_image/${item["batch_image"]}',
                          ),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  item["batch_image"] == null
                      ? const Icon(
                        Icons.menu_book,
                        size: 36,
                        color: Colors.blue,
                      )
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
