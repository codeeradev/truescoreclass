// File: lib/Screens/All Courses.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'carddeatils.dart'; // Make sure this is your CourseDetailScreen2

class AllCoursesScreen extends StatefulWidget {
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();

}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  Map<String, dynamic>? apiData;
  bool isLoading = true;
  List<dynamic> allCourses = [];

  @override
  void initState() {
    super.initState();
    fetchCoursesData();
  }

  Future<void> fetchCoursesData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-batches"),
        body: {
          "apiToken": token,
          "type": "free",
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"];
        print(data);

        List<dynamic> combined = [
          ...?data["trendingCourses"] as List?,
          ...?data["freeCourses"] as List?,
          ...?data["newCourses"] as List?,
        ];

        setState(() {
          apiData = data;
          allCourses = combined;
          isLoading = false;
        });

      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load courses")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive settings
    final double screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    double childAspectRatio = 0.75;
    double horizontalPadding = 16;
    double spacing = 16;

    if (screenWidth >= 800) {
      // Large tablets
      crossAxisCount = 4;
      childAspectRatio = 0.78;
      horizontalPadding = 32;
      spacing = 20;
    } else if (screenWidth >= 600) {
      // Medium tablets / landscape phones
      crossAxisCount = 3;
      childAspectRatio = 0.76;
      horizontalPadding = 24;
      spacing = 18;
    } else if (screenWidth < 400) {
      // Very small phones
      crossAxisCount = 2;
      childAspectRatio = 0.72;
      horizontalPadding = 12;
      spacing = 14;
    }

    return
      Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: const Text(
          "All Courses",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      )
          : allCourses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No courses available",
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
          ],
        ),
      )
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: allCourses.length,
          itemBuilder: (context, index) {
            final course = allCourses[index];
            return _courseCard(course);
          },
        ),
      ),
    );

  }

  Widget _courseCard(dynamic item) {
    final String title = item["batch_name"] ?? "Untitled Course";
    final String category = item["cat_name"] ?? "";
    final String subCategory = item["sub_cat_name"] ?? "";
    final String imageUrl = item["batch_image"]?.toString() ?? "";

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallCard = constraints.maxWidth < 170;

        final double titleFont = isSmallCard ? 13 : 15;
        final double metaFont = isSmallCard ? 11 : 12.5;
        final double iconSize = isSmallCard ? 16 : 18;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailScreen2(courseData: item),
              ),
            );
          },
          child: Card(
            elevation: 6,
            shadowColor: Colors.blue.withOpacity(0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// IMAGE (flexible height)
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      'https://truescoreedu.com/uploads/batch_image/$imageUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                    )
                        : _imageFallback(),
                  ),
                ),

                /// CONTENT
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// TITLE
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// CATEGORY
                      Text(
                        "$category${subCategory.isNotEmpty ? " • $subCategory" : ""}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: metaFont,
                          color: Colors.grey.shade800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// FOOTER
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: iconSize,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Lessons available",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: metaFont,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Image fallback widget
  Widget _imageFallback() {
    return Container(
      color: Colors.blue.shade50,
      child: const Center(
        child: Icon(Icons.menu_book, size: 42, color: Colors.blue),
      ),
    );
  }

}