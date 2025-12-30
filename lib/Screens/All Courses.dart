import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'Details/detailScreen.dart';
import 'Student/carddeatils.dart';
import 'Student/videos.dart';
import 'Youtubeplayer.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  Map<String, dynamic>? apiData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("https://testora.codeeratech.in/api/get-batches"),
        body: {
          if (token != null) "apiToken": token,
          "type": "free",
        },
      );

      final decoded = jsonDecode(response.body);

      if (!mounted) return;

      if (decoded is Map && decoded["data"] != null) {
        setState(() {
          apiData = decoded["data"];
          loading = false;
        });
      } else {
        setState(() {
          apiData = {};
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        apiData = {};
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final categories = apiData?["categories"] ?? [];
    final videoLectures = apiData?["videoLectures"] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: fetchCourses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔹 Categories
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              if (categories.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
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

              const SizedBox(height: 20),

              /// 🔹 Video Lectures
              //videoLecturesSection(videoLectures),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎥 SAFE VIDEO SECTION
  Widget videoLecturesSection(List videos) {
    if (videos.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            "Video Lectures",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index] ?? {};
              final String url = video["url"]?.toString() ?? "";
              final String title = video["title"]?.toString() ?? "Video";
              final String subject = video["subject"]?.toString() ?? "";

              final String videoId =
                  YoutubePlayer.convertUrlToId(url) ?? "";

              if (videoId.isEmpty) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          videoTitle: title,
                          youtubeUrl: url,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "https://img.youtube.com/vi/$videoId/0.jpg",
                          width: 280,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 280,
                            height: 160,
                            color: Colors.black12,
                            child: const Icon(Icons.play_circle,
                                size: 60, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 280,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                          const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (subject.isNotEmpty)
                        Text(
                          subject,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final Map<String, dynamic> allData;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.allData,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    /// ✅ Responsive grid count
    final int crossAxisCount = screenWidth < 360
        ? 2
        : screenWidth < 600
        ? 2
        : 3;

    final List courses = [
      ...(allData["trendingCourses"] ?? []),
      ...(allData["freeCourses"] ?? []),
      ...(allData["newCourses"] ?? []),
    ].where((e) => e["cat_id"] == categoryId).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(categoryName),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Header Banner
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange,Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            /// 🔹 Courses title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Courses",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            /// 🔹 Courses Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  return _courseCard(courses[index], context);
                },
              ),
            ),

            const SizedBox(height: 20),
            Container(height: 1000,child: Videos(),)
          ],
        ),
      ),
    );
  }

  /// 🔹 Course Card
  Widget _courseCard(dynamic item, BuildContext context) {
    final String imageUrl = item["batch_image"]?.toString() ?? "";

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen2(courseData: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                'https://testora.codeeratech.in/uploads/batch_image/$imageUrl',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) =>
                    _imagePlaceholder(),
              )
                  : _imagePlaceholder(),
            ),

            /// 🔹 Text
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["batch_name"]?.toString() ?? "Course",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item["sub_cat_name"]?.toString() ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 120,
      color: Colors.blue.shade50,
      child: const Center(
        child: Icon(Icons.school, size: 40, color: Colors.blue),
      ),
    );
  }
}

