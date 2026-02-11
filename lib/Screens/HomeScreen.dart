import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:online_classes/Controllers/bannerController.dart';
import 'package:online_classes/Screens/All%20Courses.dart';
import 'package:online_classes/Screens/Banner_DetailsScreen.dart';
import 'package:online_classes/Screens/Details/detailScreen.dart';
import 'package:online_classes/Screens/Notification/notificationScreen.dart';
import 'package:online_classes/Screens/ProfileScreen.dart';
import 'package:online_classes/Screens/SeeAll_Screen.dart';
import 'package:online_classes/Screens/subCategories/SubCategoriesScreen.dart';
import 'package:share_plus/share_plus.dart';
import '../ThemeConstent/themeData.dart';
import 'SearchScreen.dart';
import 'Settingscreen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as https;

import '../Models/bannerBodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  // BannerControlle _banner = Get.put(BannerControlle());

  int selectedIndex = 0;
  late PageController _pageController;
  Timer? _timer;
  List categories = [];

  // final List<Map<String, String>> bannerData = [
  //   {'title': 'Principal of UX/UI Design', 'image': 'assets/images/s1.png'},
  //   {'title': 'Advanced Mobile UI', 'image': 'assets/images/s2.png'},
  //   {'title': 'Web UI Basics', 'image': 'assets/images/s3.png'},
  //   {'title': 'Design Systems', 'image': 'assets/images/s4.png'},
  //   {'title': 'Typography in UI', 'image': 'assets/images/s5.png'},
  // ];

  final List<Map<String, String>> courseData = [
    {'title': 'SSC', 'image': 'assets/images/ssc.png'},
    {'title': 'UPSC', 'image': 'assets/images/upsc.png'},
    {'title': 'NDA', 'image': 'assets/images/nda.png'},
    {'title': 'CDS', 'image': 'assets/images/cds.png'},
    {'title': 'HSSC', 'image': 'assets/images/hssc.png'},
  ];

  final List<Map<String, String>> lectureData = [
    {'title': 'SSC', 'image': 'assets/images/l1.png'},
    {'title': 'UPSC', 'image': 'assets/images/l2.png'},
    {'title': 'NDA', 'image': 'assets/images/l3.png'},
    {'title': 'CDS', 'image': 'assets/images/l4.png'},
  ];

  final List<Map<String, String>> videoData = [
    {'title': 'SSC', 'image': 'assets/images/v1.png'},
    {'title': 'UPSC', 'image': 'assets/images/v2.png'},
    {'title': 'NDA', 'image': 'assets/images/v3.png'},
    {'title': 'CDS', 'image': 'assets/images/v4.png'},
  ];

  List bannerData =  [];

  Map<String, dynamic>? apiData;

  bool isLoading = true;


  /// Calling Banner Api with this function
  getBanner() async {
    String _bashUrl = "https://digiacademy.onrender.com/digi/courses";

    print('starrt');
    final response = await https.get(Uri.parse(_bashUrl));

    if (response.statusCode == 200 || response.statusCode == 201) {
      // print("i am here ${response.body}");
      var data = jsonDecode(response.body);
      print("body ${data}");
      print(data[0]['title']);
      setState(() {
        bannerData=data;
      });
      print(bannerData);
    } else {
      print("statusCode ${response.statusCode}");
    }
  }


  @override
  void initState() {
    super.initState();
    fetchCourses();
    getBanner();

   // _banner.getBanner();
    _pageController = PageController(viewportFraction: 0.85);

    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.round() ?? 0) + 1;
        if (nextPage >= bannerData.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> fetchCourses() async {
    final response = await http.post(
      Uri.parse("https://truescoreedu.com/api/get-batches"),
      body: {
        "apiToken":
        "42065ca57e8859475dc0ceb6c1df197d53041adef155fb1097142aa053cea519",
        "type": "free"
      },
    );

    setState(() {
      apiData = jsonDecode(response.body)["data"];
      categories = jsonDecode(response.body)["data"]["categories"];

      isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print("data=${data}");

    return
      Scaffold(
      backgroundColor: Colors.grey.shade200,
      /// Nav Drawer
      drawer: Drawer(
        backgroundColor: Colors.white.withOpacity(0.8),
        child: Container(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                          'https://cdn.pixabay.com/photo/2018/08/04/11/30/draw-3583548_1280.png'),
                    ),
                    SizedBox(height: 10),
                    Text("Hello, User",
                        style: TextStyle(color: AppTheme.textColor, fontSize: 18)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: AppTheme.iconColor1),
                title: const Text('Profile', style: TextStyle(color: AppTheme.textColor1)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: AppTheme.iconColor1),
                title: const Text('Settings', style: TextStyle(color: AppTheme.textColor1)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfileSettingsScreen()));
                },
              ),

              ListTile(
                leading: const Icon(Icons.share, color: AppTheme.iconColor1),
                title: const Text('Share App', style: TextStyle(color: AppTheme.textColor1)),
                onTap: () {
                  Share.share(
                      'https://wa.me/?text=Check out this awesome app: https://play.google.com/store/apps/details?id=com.example.app',
                      subject: 'Awesome App');
                },
              ),

              const ListTile(
                leading: Icon(Icons.wb_sunny, color: AppTheme.iconColor1),
                title: Text('Change Theme', style: TextStyle(color: AppTheme.textColor1)),
              ),

              const ListTile(
                leading: Icon(Icons.logout, color: AppTheme.iconColor1),
                title: Text('Logout', style: TextStyle(color: AppTheme.textColor1)),
              ),

            ],
          ),
        ),
      ),

      /// AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
                'https://cdn.pixabay.com/photo/2018/08/04/11/30/draw-3583548_1280.png'),
          ),
        ),
        title: const Text("Dashboard", style: TextStyle(color: AppTheme.textColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.iconColor2),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.iconColor2),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),

      /// Body
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Search Bar
            Padding(
              padding: const EdgeInsets.all(10),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CoursesScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Search courses...',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

            /// Auto-scrolling Banner
            SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 5,
                  itemBuilder: (context, index) {

                    return
                      InkWell(
                      onTap: (){
                        // print('Banner tapes No.$index');
                      //  Navigator.push(context, MaterialPageRoute(builder: (context)=>BannerDetailsscreen(name: bannerData.first['title'].toString())));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(bannerData[index]['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.bottomLeft,

                        child:
                        Chip(
                          label: Text(bannerData[index]['title'],
                              style: const TextStyle(color: AppTheme.textColor)),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            /// Categories Section
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Categories",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),

            // SizedBox(
            //   height: 120,
            //   child: SingleChildScrollView(
            //     scrollDirection: Axis.horizontal,
            //     child: Row(
            //       children: List.generate(categories.length, (index) {
            //         final cat = categories[index];
            //
            //         return InkWell(
            //           onTap: () {
            //             // Navigate to subcategories
            //           },
            //           child: Column(
            //             children: [
            //               Material(
            //                 elevation: 2,
            //                 shape: const CircleBorder(),
            //                 child: Container(
            //                   margin: const EdgeInsets.symmetric(horizontal: 8),
            //                   height: 80,
            //                   width: 80,
            //                   decoration: const BoxDecoration(
            //                     shape: BoxShape.circle,
            //                     image: DecorationImage(
            //                       image: AssetImage("assets/placeholder.png"), // Use placeholder image
            //                       fit: BoxFit.cover,
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //               const SizedBox(height: 4),
            //               SizedBox(
            //                 width: 100,
            //                 child: Text(
            //                   cat["name"],
            //                   textAlign: TextAlign.center,
            //                   style: const TextStyle(fontSize: 12),
            //                   maxLines: 2,
            //                   overflow: TextOverflow.ellipsis,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         );
            //       }),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(courseData.length, (index) {
                    final course = courseData[index];
                    return InkWell(
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SubCategoriesScreen())),
                      child: Column(
                        children: [
                          Material(
                            elevation: 1,
                            shape: const CircleBorder(),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(course['image']!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 100,
                            child: Text(
                              course['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            /// Lectures
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Top Exams', style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
                  InkWell(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> SeeallScreen(title: 'Top Exams')));
                      },child: const Text('See all', style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold, color: Colors.blue))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: lectureData.length,
                itemBuilder: (_, index) {
                  final lecture = lectureData[index];
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CourseDetailScreen(name: bannerData[index]['title'].toString(),)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      height: 200,
                      width: 200,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primeryColor,
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: AssetImage(lecture['image']!),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lecture['title'] ?? '',
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
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            /// Videos
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: videoData.length,
                itemBuilder: (_, index) {
                  final video = videoData[index];
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CourseDetailScreen(name: bannerData[index]['title'].toString())),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      height: 200,
                      width: 200,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: AssetImage(video['image']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                video['title'] ?? '',
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
                  );
                },
              ),
            ),
            const SizedBox(height: 100)
          ],
        ),
      ),
    );
  }
}
