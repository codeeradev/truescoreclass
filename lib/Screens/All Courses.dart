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
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    final categories = apiData?["categories"] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: RefreshIndicator(
        onRefresh: fetchCourses,
        color: Colors.deepPurple,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 40, 20, 16),
                child: Text(
                  "Explore Courses",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  "Categories",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index] ?? {};
                    final name = cat["name"]?.toString() ?? "Category";
                    final id = cat["id"]?.toString() ?? "";

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
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
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.blue, Colors.blueGrey],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.category_rounded, color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 80,
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // You can add video lectures or other sections here if needed
            // SliverToBoxAdapter(child: videoLecturesSection(videoLectures)),
          ],
        ),
      ),
    );
  }

// Keep your videoLecturesSection if you want to show global videos
// ...
}

// ONLY CHANGED PARTS MARKED 🔥

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

  List<dynamic> _getCoursesByType(String type) {
    final List courses = [
      ...(allData["$type"] ?? []),
    ].where((e) => e["cat_id"] == categoryId).toList();
    return courses;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    /// 🔥 RESPONSIVE GRID
    final int crossAxisCount = screenWidth < 400 ? 2 : 3;

    final trending = _getCoursesByType("trendingCourses");
    final free = _getCoursesByType("freeCourses");
    final newCourses = _getCoursesByType("newCourses");

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(categoryName),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [

          /// HEADER
          SliverToBoxAdapter(
            child: Container(
              height: 160,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
              ),
              child: const Center(
                child: Icon(Icons.school_rounded, size: 80, color: Colors.white70),
              ),
            ),
          ),

          if (trending.isNotEmpty) ...[
            _buildSectionHeader("Trending Courses 🔥"),
            _buildCourseGrid(trending, crossAxisCount, "Trending"),
          ],

          if (free.isNotEmpty) ...[
            _buildSectionHeader("Free Courses 🎁"),
            _buildCourseGrid(free, crossAxisCount, "Free"),
          ],

          if (newCourses.isNotEmpty) ...[
            _buildSectionHeader("New Courses ✨"),
            _buildCourseGrid(newCourses, crossAxisCount, "New"),
          ],
        ],
      ),
    );
  }

  /// 🔥 HEADER TEXT
  SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  /// 🔥 RESPONSIVE GRID FIX
  SliverPadding _buildCourseGrid(List courses, int crossAxisCount, String type) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,

          /// 🔥 FIXED RATIO
          childAspectRatio: crossAxisCount == 2 ? 0.62 : 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) =>
              _courseCard(courses[index], context, type),
          childCount: courses.length,
        ),
      ),
    );
  }

  /// 🔥 FULLY RESPONSIVE CARD
  Widget _courseCard(dynamic item, BuildContext context, String type) {

    final String imageUrl = item["batch_image"]?.toString() ?? "";

    return LayoutBuilder(
      builder: (context, constraints) {

        final isSmall = constraints.maxWidth < 180;
        final imageHeight = isSmall ? 110.0 : 140.0;

        final Color badgeColor = type == "Trending"
            ? Colors.orange
            : type == "Free"
            ? Colors.green
            : Colors.blueAccent;

        return InkWell(
          borderRadius: BorderRadius.circular(18),
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
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 IMAGE
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        'https://truescoreedu.com/uploads/batch_image/$imageUrl',
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : _imagePlaceholder(imageHeight),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                /// 🔥 TEXT (NO OVERFLOW)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          item["batch_name"] ?? "Course",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 13 : 14,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          item["sub_cat_name"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.school, size: 40),
      ),
    );
  }
}

