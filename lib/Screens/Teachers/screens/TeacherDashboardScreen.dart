import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:online_classes/Screens/AddQuestionsScreen.dart';
import 'package:online_classes/Screens/Auth/asktype.dart';
import 'package:online_classes/Screens/GetQues.dart';
import 'package:online_classes/Screens/Teachers/screens/Teacher_Notification_Screen.dart';
import 'package:online_classes/Screens/Teachers/screens/Teacher_Profile.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../ThemeConstent/themeData.dart';
import '../../Addnotes.dart';
import '../../teacherprofile.dart';
import 'CreateEventScreen.dart';
import 'DoubtClassScreen.dart';
import 'LiveClassScreen.dart';
import 'PostVideoScreen.dart';
import 'UploadNotesScreen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();

}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {

  final List<_DashboardItem> items = [

    _DashboardItem("Upload Questions", FontAwesomeIcons.listCheck, Colors.blue),
    _DashboardItem("Teacher Questions", FontAwesomeIcons.fileLines, Colors.orange),
    _DashboardItem("Doubt Class", FontAwesomeIcons.questionCircle, Colors.green),
    _DashboardItem("Post Video", FontAwesomeIcons.video, Colors.pink),
    _DashboardItem("Add Notes", FontAwesomeIcons.noteSticky, Colors.brown),
    _DashboardItem("Profile", FontAwesomeIcons.userLarge, Colors.indigo),
    _DashboardItem("Logout", Icons.logout, Colors.red),
  ];

  String name = 'Teacher';

  @override
  void initState() {
    super.initState();
    getname();
  }


  Future<void> getname() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      name = preferences.getString('teachername') ?? 'Teacher';
    });
  }


  void _navigateToScreen(String label) {
    Widget? targetScreen;
    switch (label) {
      case "Upload Questions":
        targetScreen = const AddQuestionScreen();
        break;
      case "Teacher Questions":
        targetScreen = const QuestionListScreen();
        break;
      case "Doubt Class":
        targetScreen = const TeacherDoubtsScreen();
        break;
      case "Post Video":
        targetScreen = const PostVideoScreen();
        break;
      case "Add Notes":
        targetScreen = const AddNotesScreen();
        break;
      case "Profile":
        targetScreen = const TeacherProfileScreen();
        break;
      case "Logout":
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AskType()));
        return;
    }

    if (targetScreen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;

    // Responsive grid settings
    int crossAxisCount = 2;
    double childAspectRatio = 1.1;
    double horizontalPadding = 20;
    double spacing = 20;

    if (screenWidth >= 800) {
      // Large tablets
      crossAxisCount = 4;
      childAspectRatio = 1.3;
      horizontalPadding = 40;
      spacing = 24;
    } else if (screenWidth >= 500) {
      // Medium devices
      crossAxisCount = 3;
      childAspectRatio = 1.2;
      horizontalPadding = 24;
      spacing = 20;
    } else if (screenWidth < 400) {
      // Very small phones
      crossAxisCount = 2;
      childAspectRatio = 1.0;
      horizontalPadding = 16;
      spacing = 16;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        // actions: [
        //   TextButton.icon(
        //     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherProfileScreen())),
        //     icon: const Icon(Icons.person),
        //     label: const Text("Profile"),
        //   ),
        // ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Welcome Section
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Welcome, $name",
                        style: TextStyle(
                          fontSize: screenWidth < 400 ? 28 : 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.notifications_outlined, size: screenWidth < 400 ? 28 : 32),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen()));
                      },
                    ),
                  ],
                ),
              ),

              // Responsive GridView
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => _navigateToScreen(item.label),
                      child: Card(
                        elevation: 10,
                        shadowColor: item.color.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                size: screenWidth < 500 ? 48 : 60,
                                color: item.color,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: screenWidth < 500 ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: item.color,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String label;
  final IconData icon;
  final Color color;

  _DashboardItem(this.label, this.icon, this.color);
}