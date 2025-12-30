import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'Details/detailScreen.dart';
import 'Student/carddeatils.dart';

class CourseSearchScreen extends StatefulWidget {
  const CourseSearchScreen({super.key});

  @override
  State<CourseSearchScreen> createState() => _CourseSearchScreenState();
}

class _CourseSearchScreenState extends State<CourseSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> courses = [];
  bool isLoading = false;
  bool hasSearched = false;
  String errorMessage = '';

  // Debounce timer
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> searchCourses(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        courses = [];
        hasSearched = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("https://testora.codeeratech.in/api/search-courses"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "key": query.trim(),
          if (token != null) "apiToken": token, // Optional if needed
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          setState(() {
            courses = json['data'] ?? [];
            isLoading = false;
            hasSearched = true;
          });
        } else {
          setState(() {
            errorMessage = json['message'] ?? 'No results found';
            isLoading = false;
            hasSearched = true;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error';
          isLoading = false;
          hasSearched = true;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please try again.';
        isLoading = false;
        hasSearched = true;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      searchCourses(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Search Courses"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Search for courses",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      courses = [];
                      hasSearched = false;
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // Results
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasSearched
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Start typing to search courses",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : courses.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage.isEmpty ? "No courses found" : errorMessage,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildCourseCard(course);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final String name = course['batch_name'] ?? 'Unnamed Course';
    final String category = course['category_name'] ?? '';
    final String subCategory = course['sub_category_name'] ?? '';
    final String startDate = course['start_date'] ?? '';
    final String endDate = course['end_date'] ?? '';
    final String price = course['batch_price']?.isEmpty ?? true
        ? (course['batch_offer_price']?.isEmpty ?? true ? 'Free' : '₹${course['batch_offer_price']}')
        : '₹${course['batch_price']}';
    final String imageUrl = course["batch_image"]?.toString() ?? "";



    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=>CourseDetailScreen2(courseData: course,)));

          // TODO: Navigate to course details screen
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text("Selected: $name")),
          // );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.indigo[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Placeholder for course image
            imageUrl.isNotEmpty?
            Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(16),

                ),
                child: Image.network('https://testora.codeeratech.in/uploads/batch_image/${imageUrl}'),
              ):Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.indigo[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.book),
            ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (category.isNotEmpty)
                      Text(
                        "$category ${subCategory.isNotEmpty ? '• $subCategory' : ''}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          "$startDate to $endDate",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// Don't forget to import timer if not already
