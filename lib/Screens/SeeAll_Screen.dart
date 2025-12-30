import 'package:flutter/material.dart';
import 'package:online_classes/Screens/All%20Courses.dart';
import 'package:online_classes/Screens/subCategories/SubCategoriesScreen.dart';

import '../ThemeConstent/themeData.dart';
import 'Details/detailScreen.dart';
import 'SearchScreen.dart';

class SeeallScreen extends StatefulWidget {
  final String title;

  const SeeallScreen({super.key, required this.title});

  @override
  State<SeeallScreen> createState() => _SeeallScreenState();
}

class _SeeallScreenState extends State<SeeallScreen> {
  /// function to filter the screen's
  Widget _screenFilter() {
    if (widget.title == 'Top Categories') {
      return _topCategories();
    } else {
      return _topExams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _screenFilter();
  }

  /// widget for top exams
  Widget _topExams() {
    final List<Map<String, String>> examData = [
      {'title': 'Bank PO', 'image': 'assets/images/s1.png'},
      {'title': 'Railway NTPC', 'image': 'assets/images/s2.png'},
      {'title': 'UPSC CSE', 'image': 'assets/images/s3.png'},
      {'title': 'SSC CGL', 'image': 'assets/images/s4.png'},
      {'title': 'Defence Exams', 'image': 'assets/images/l1.png'},
      {'title': 'UPPSC', 'image': 'assets/images/l2.png'},
      {'title': 'State PSC', 'image': 'assets/images/l3.png'},
      {'title': 'Teaching Exams', 'image': 'assets/images/l4.png'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Top Exams", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CoursesScreen()),
                );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: examData.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 26,
            childAspectRatio: 4 / 2,
          ),
          itemBuilder: (context, index) {
            final exam = examData[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CourseDetailScreen(name: exam['title']!),
                  ),
                );
              },
              child: Material(
                elevation: 6,
                shadowColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(exam['image']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exam['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }



  /// widget for top categories
  Widget _topCategories() {
    final List<Map<String, String>> topCategoryData = [
      {'title': 'UPSC', 'image': 'assets/images/upsc.png'},
      {'title': 'SSC', 'image': 'assets/images/ssc.png'},
      {'title': 'NDA', 'image': 'assets/images/nda.png'},
      {'title': 'CDS', 'image': 'assets/images/cds.png'},
      {'title': 'HSSC', 'image': 'assets/images/hssc.png'},
      {'title': 'State PSC', 'image': 'assets/images/hssc.png'},
      {'title': 'Railway Exams', 'image': 'assets/images/hssc.png'},
      {'title': 'Banking', 'image': 'assets/images/hssc.png'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Top Exam Categories", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoursesScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 4 / 5.2,
            ),
            itemCount: topCategoryData.length,
            itemBuilder: (context, index) {
              final item = topCategoryData[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SubCategoriesScreen(),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Card(
                      elevation: 1,
                      color: AppTheme.primeryColor,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.22,
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: ClipOval(
                          child: Image.asset(
                            item['image']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}
