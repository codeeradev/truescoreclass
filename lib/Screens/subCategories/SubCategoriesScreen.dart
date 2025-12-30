import 'package:flutter/material.dart';
import 'package:online_classes/Screens/Details/detailScreen.dart';

import '../../ThemeConstent/themeData.dart';
import '../SearchScreen.dart';

class SubCategoriesScreen extends StatefulWidget {
  const SubCategoriesScreen({super.key});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {


  final List<Map<String, String>> sscData = [
    {
      'title': 'SSC CGL',
      'image': 'assets/images/ssc.png',
    },
    {
      'title': 'SSC CHSL',
      'image': 'assets/images/ssc.png',
    },
    {
      'title': 'SSC GD',
      'image': 'assets/images/ssc.png',
    },
    {
      'title': 'SSC JE',
      'image': 'assets/images/ssc.png',
    },
    {
      'title': 'SSC CGL',
      'image': 'assets/images/ssc.png',
    },
    {
      'title': 'SSC CHSL',
      'image': 'assets/images/ssc.png',
    },
    {
      'title': 'SSC GD',
      'image': 'assets/images/ssc.png',
    },
    {
      'title': 'SSC JE',
      'image': 'assets/images/ssc.png',
    },
  ];




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("SubCategories", style: TextStyle(color: AppTheme.textColor)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color:AppTheme.iconColor2), // This sets default icon color to white
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.search, color: AppTheme.iconColor2,),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const SearchScreen()),
          //     );
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                shrinkWrap: true, // Important to make it work inside SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // Prevent conflict with parent scroll
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cards per row
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio:  4 / 5.2, /// Reduce this value to increase card height
                ),
                itemCount: sscData.length, // Change this based on your data
                itemBuilder: (context, index) {

                  var sData = sscData[index];
                  return InkWell(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=> CourseDetailScreen(name: sData['title'].toString())));
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
                                sData['image']!, // Replace with your actual image path
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Text(sData['title']!)
                      ],
                    ),

                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
