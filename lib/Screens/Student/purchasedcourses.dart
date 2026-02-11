import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../servcies.dart';
import 'Onlydetails.dart';

class PurchasedCoursesHorizontal extends StatefulWidget {
  const PurchasedCoursesHorizontal({super.key});

  @override
  State<PurchasedCoursesHorizontal> createState() =>
      _PurchasedCoursesHorizontalState();
}

class _PurchasedCoursesHorizontalState
    extends State<PurchasedCoursesHorizontal> {
  bool isLoading = true;
  List<Map<String, dynamic>> purchasedCourses = [];

  @override
  void initState() {
    super.initState();
    fetchPurchasedCourses();
  }

  Future<void> fetchPurchasedCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/purchased-batch"),
        body: {"apiToken": token},
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "true") {
        final List<dynamic> batches = data["data"]["mybatches"] ?? [];
        setState(() {
          purchasedCourses = batches.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 If loading or empty → show NOTHING
    if (isLoading || purchasedCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "My Purchased Courses",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: purchasedCourses.length,
            itemBuilder: (context, index) {
              final course = purchasedCourses[index];

              final String batchName =
                  course["batch_name"] ?? "Untitled";
              final String imageUrl =
                  course["batch_image"] ?? "";
              final String endDate =
                  course["end_date"] ?? "";
              final String courseId =
              course["id"].toString();

              return InkWell(onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PurchasedCourseVideosScreen(
                          courseId: courseId,
                        ),
                  ),
                );
              },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 14),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.blue.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGE
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            "https://truescoreedu.com/uploads/batch_image/$imageUrl",
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _imageFallback(),
                          )
                              : _imageFallback(),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batchName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    endDate,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 120,
      color: Colors.blue[50],
      child: const Center(
        child: Icon(Icons.menu_book_rounded,
            size: 50, color: Colors.blue),
      ),
    );
  }
}





class MyOnlyPurchased extends StatefulWidget {
  const MyOnlyPurchased({Key? key}) : super(key: key);

  @override
  State<MyOnlyPurchased> createState() => _MyOnlyPurchasedState();
}

class _MyOnlyPurchasedState extends State<MyOnlyPurchased> {
  bool isLoading = true;
  List<Map<String, dynamic>> purchasedCourses = [];

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    fetchPurchasedCourses();
  }

  Future<void> fetchPurchasedCourses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/purchased-batch"),
        body: {"apiToken": token},
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "true") {
        final List<dynamic> batches = data["data"]["mybatches"] ?? [];
        setState(() {
          purchasedCourses = batches.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount = screenWidth < 360 ? 1 : 2;
    final double childRatio = screenWidth < 360 ? 1.25 : 0.78;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Purchased Courses"),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchasedCourses.isEmpty
          ? const Center(
        child: Text(
          "No purchased courses found",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: purchasedCourses.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: childRatio,
        ),
        itemBuilder: (context, index) {
          final course = purchasedCourses[index];

          final String batchName =
              course["batch_name"] ?? "Untitled";
          final String imageUrl =
              course["batch_image"] ?? "";
          final String endDate =
              course["end_date"] ?? "";
          final String courseId =
          course["id"].toString();

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PurchasedCourseVideosScreen(
                    courseId: courseId,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE (Responsive)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        "https://truescoreedu.com/uploads/batch_image/$imageUrl",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imageFallback(),
                      )
                          : _imageFallback(),
                    ),
                  ),

                  // CONTENT (Flexible)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            batchName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 13,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  endDate,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
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
        },
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.blue[50],
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 50,
          color: Colors.blue,
        ),
      ),
    );
  }
}


