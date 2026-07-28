import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/Screens/Student/notificcationstudents.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../servcies.dart';
import '../All Courses.dart';
import '../Auth/signinScreen.dart';
import '../SearchScreen.dart';
import '../Teachers/screens/getmeeting.dart';
import 'ALLNewCourses.dart';
import 'carddeatils.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<dynamic> vacancies = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

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
    fetchVacancies();
    _startAutoScroll();
  }

  void _showVacancyDialog(
    BuildContext context,
    Map<String, dynamic> vacancy,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vacancy["title"]?.toString() ?? "",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const Divider(height: 20),
              _VacancyDetail(
                vacancy: vacancy,
                onOpenFile: _openUrl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchVacancies() async {
    try {
      final response = await http
          .post(
            Uri.parse("https://truescoreedu.com/api/get-vacancies"),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print("fetchVacancies STATUS: ${response.statusCode}");
        print("fetchVacancies BODY: ${response.body}");
      }

      if (response.statusCode != 200) return;
      if (response.body.trim().isEmpty) return;
      if (response.body.trim().startsWith('<')) return;

      final data = jsonDecode(response.body);
      if (!mounted) return;

      final bool success = data["status"].toString() == "1" ||
          data["status"].toString() == "true";

      if (success) {
        setState(() {
          vacancies = data["data"] ?? [];
        });
      }
    } catch (e) {
      if (kDebugMode) print("fetchVacancies error--$e");
      // Fails silently on purpose — this is a promo banner, not a
      // critical screen, so it just stays hidden if the call fails.
    }
  }

  void _startAutoScroll() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!_scrollController.hasClients) return;

      _scrollController.jumpTo(_scrollController.offset + 1);
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the notice.")),
        );
      }
    } catch (e) {
      if (kDebugMode) print("openUrl error--$e");
    }
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

  // bool hasNewNotice = false;
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
          // List<dynamic> notices = data["data"] ?? [];

          // int currentCount = notices.length;
          //
          // int lastCount = pref.getInt("last_notice_count") ?? 0;
          // setState(() {
          //   newNoticeCount =
          //       currentCount > lastCount ? currentCount - lastCount : 0;
          // });
          setState(() {
            newNoticeCount = data['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  String get _tickerText => vacancies
      .map((v) => v["title"]?.toString() ?? "")
      .where((t) => t.isNotEmpty)
      .join("     •     ");

  @override
  void dispose() {
    SecureScreen.disable();
    _scrollTimer?.cancel();
    _scrollController.dispose();
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen1(),
                    ),
                  ).whenComplete(
                    () {
                      fetchNotices();
                    },
                  );
                },
              ),
              if (newNoticeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen1(),
                        ),
                      ).whenComplete(
                        () {
                          fetchNotices();
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        newNoticeCount > 99 ? "99+" : newNoticeCount.toString(),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 100000,
                      itemBuilder: (context, index) {
                        final vacancy = vacancies[index % vacancies.length];
                        return InkWell(
                          onTap: () => _showVacancyDialog(context, vacancy),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                vacancy["title"] ?? "",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.red),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      // if (simage.isNotEmpty)
                      // CircleAvatar(
                      //   radius: 20,
                      //   backgroundImage: NetworkImage(simage),
                      // ),
                      // const SizedBox(width: 12),
                      Text(
                        "Hi, $sname",
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  // SizedBox(height: 20),
                  // if (liveClasses.isNotEmpty)
                  //   InkWell(
                  //     onTap: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => getclassscreen(),
                  //         ),
                  //       );
                  //     },
                  //     child: Container(
                  //       margin: EdgeInsets.symmetric(horizontal: 10),
                  //       height: 50,
                  //       width: double.maxFinite,
                  //       decoration: BoxDecoration(
                  //         color: Colors.blue,
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //       child: Center(
                  //         child: Text(
                  //           'Check Your Google Meeting',
                  //           style: TextStyle(color: Colors.white),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
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
                    readOnly: true,
                    onTap: () {
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
                      if (courses.length >= 4)
                        TextButton(
                          onPressed: () => Navigator.push(
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
                        itemCount: min(4, courses.length),
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: (MediaQuery.of(context).size.width - 56) /
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
                image: item["batch_image"] != null
                    ? DecorationImage(
                        image: NetworkImage(
                          'https://truescoreedu.com/uploads/batch_image/${item["batch_image"]}',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item["batch_image"] == null
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

class _VacancyDetail extends StatelessWidget {
  final Map<String, dynamic> vacancy;
  final ValueChanged<String> onOpenFile;

  const _VacancyDetail({required this.vacancy, required this.onOpenFile});

  @override
  Widget build(BuildContext context) {
    final String description = vacancy["description"]?.toString() ?? "";
    final String startDate = vacancy["start_date"]?.toString() ?? "";
    final String lastDate = vacancy["last_date"]?.toString() ?? "";
    final String mode = vacancy["mode"]?.toString() ?? "";
    final String fileUrl = vacancy["file_url"]?.toString() ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
                fontSize: 13.5, color: Colors.black87, height: 1.4),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (startDate.isNotEmpty)
              _infoChip(Icons.play_circle_outline_rounded, "Starts $startDate"),
            if (lastDate.isNotEmpty)
              _infoChip(Icons.event_busy_rounded, "Last date $lastDate"),
            if (mode.isNotEmpty)
              _infoChip(Icons.laptop_chromebook_rounded, mode),
          ],
        ),
        if (fileUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onOpenFile(fileUrl),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text("View Notice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
