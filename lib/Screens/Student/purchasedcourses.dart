// File: lib/Screens/All Courses.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/Screens/Student/videos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'carddeatils.dart'; // Make sure this is your CourseDetailScreen2

class purchasedcourses extends StatefulWidget {
  const purchasedcourses({super.key});

  @override
  State<purchasedcourses> createState() => _purchasedcoursesState();

}

class _purchasedcoursesState extends State<purchasedcourses> {

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
        Uri.parse("https://testora.codeeratech.in/api/get-batches"),
        body: {
          "apiToken": token,
          "type": "paid",
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
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          title: const Text(
            "Purchased Courses",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.green),
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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Videos()
                //CourseDetailScreen2(courseData: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 8,
        shadowColor: Colors.blue.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 1.4, // Consistent image height
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  'https://testora.codeeratech.in/uploads/batch_image/${imageUrl}',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.blue.shade50,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.blue.shade50,
                      child: const Icon(Icons.menu_book, size: 50, color: Colors.green),
                    );
                  },
                )
                    : Container(
                  color: Colors.blue.shade50,
                  child: const Icon(Icons.menu_book, size: 50, color: Colors.green),
                ),
              ),
            ),

            // Course Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Category & Subcategory
                    Text(
                      "$category${subCategory.isNotEmpty ? " • $subCategory" : ""}",
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Lessons indicator
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 18, color: Colors.blue.shade600),
                        const SizedBox(width: 6),
                        Text(
                          "Lessons available",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}