import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../Question.dart'; // Assuming PapersListScreen is here
import '../Youtubeplayer.dart';
import 'getnotes.dart'; // VideoPlayerScreen

class Videos extends StatefulWidget {
  final String id;
   Videos({super.key,required this.id});

  @override
  State<Videos> createState() => _VideosState();

}

class _VideosState extends State<Videos> {
  Map<String, dynamic>? apiData;
  bool loading = true;
  bool loder = false;

  List<dynamic> mockPapers = [];
  List<dynamic> practicePapers = [];
  List<dynamic>pyq = [];

  bool isLoadingPapers = true;
  String errorMsg = "";

  @override
  void initState() {
    super.initState();
    fetchCourses();
    fetchPapers();
  }
  Widget testoraBannerCard() {
    return InkWell(onTap: (){
      //Navigator.push(context, MaterialPageRoute(builder: (context)=>GetNotesScreen()));
    },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB), // deep blue
              Color(0xFF3B82F6), // light blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// 🔵 Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: _decorCircle(120, Colors.white.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: _decorCircle(100, Colors.white.withOpacity(0.08)),
            ),

            /// CONTENT
            Row(
              children: [
                /// ICON CONTAINER
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 16),

                /// TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Notes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Learn and grow faster",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                /// RIGHT DECOR ICON
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _decorCircle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }


  Future<void> fetchPapers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? apiToken = prefs.getString("token");
      print(apiToken);

      if (apiToken == null || apiToken.isEmpty) {
        setState(() {
          errorMsg = "Please login again";
          isLoadingPapers = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-active-questions"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": apiToken,
        "courseid":widget.id.toString()},
      );
      print(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        if (json['status'] == "1" && json['data'] != null) {
          final List data = json['data'];
          setState(() {
            mockPapers = data.where((e) => e['paper_type'] == "1").toList();
            practicePapers = data.where((e) => e['paper_type'] == "2").toList();
           // pyq = data.where((e) => e['paper_type'] == "3").toList();

            isLoadingPapers = false;
          });
        } else {
          setState(() {
            errorMsg = json['msg'] ?? "No papers available";
            isLoadingPapers = false;
          });
        }
      } else {
        setState(() {
          errorMsg = "Server error";
          isLoadingPapers = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Network error";
        isLoadingPapers = false;
      });
    }
  }

  Future<void> fetchCourses() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');

    final response = await http.post(
      Uri.parse("https://truescoreedu.com/api/get-batches"),
      body: {"apiToken": token, "type": "free"},
    );

    final data = jsonDecode(response.body);
    setState(() {
      apiData = data["data"];
      loading = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => loder = true);
    });
    print(apiData!["videoLectures"]);
  }

  Widget videoLecturesSection(List videoLectures) {
    if (videoLectures.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            "Video Lectures",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: videoLectures.length,
            itemBuilder: (context, index) {
              final video = videoLectures[index];
              final String youtubeUrl = video["url"] ?? "";
              final String videoId = getYoutubeVideoId(youtubeUrl);


              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          videoTitle: video["title"] ?? "Video Lecture",
                          youtubeUrl: youtubeUrl,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 290,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: videoId.isEmpty
                                  ? Container(
                                height: 160,
                                color: Colors.grey[300],
                                child: const Icon(Icons.play_circle, size: 70),
                              )
                                  : Image.network(
                                "https://img.youtube.com/vi/$videoId/hqdefault.jpg",
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.play_circle, size: 70),
                                ),
                              ),
                            ),

                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_fill, size: 80, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          video["title"] ?? "Untitled Lecture",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video["subject"] ?? "General",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  String getYoutubeVideoId(String url) {
    // Handle LIVE URLs
    final liveMatch = RegExp(r'youtube\.com/live/([^?&]+)').firstMatch(url);
    if (liveMatch != null) {
      return liveMatch.group(1)!;
    }

    // Handle normal URLs
    final normalId = YoutubePlayer.convertUrlToId(url);
    return normalId ?? "";
  }


  Widget _buildPaperCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
  })
  {
    final bool isEnabled = count > 0 && onTap != null;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEnabled ? [color, color.withOpacity(0.8)] : [Colors.grey, Colors.grey.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 70, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                count > 0 ? "$count Papers Available" : "Coming Soon",
                style: TextStyle(fontSize: 17, color: Colors.white.withOpacity(0.9)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Practice paper", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: loder == false
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await fetchCourses();
          await fetchPapers();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Video Lectures Section
              //if (apiData != null) videoLecturesSection(apiData!["videoLectures"] ?? []),
              // SizedBox(height: 20,),
              // testoraBannerCard(),
              SizedBox(height: 20,),


              // Papers Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Practice & Test Yourself",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),

                    if (isLoadingPapers)
                      const Center(child: CircularProgressIndicator())
                    else if (errorMsg.isNotEmpty)
                      Center(
                        child: Text(
                          "No MCQ Paper ",
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                        _buildPaperCard(
                          title: "Mock Tests",
                          count: mockPapers.length,
                          color: const Color(0xFF4A90E2),
                          icon: Icons.timer,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PapersListScreen(papers: mockPapers, title: "Mock Tests"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPaperCard(
                          title: "Practice Papers",
                          count: practicePapers.length,
                          color: const Color(0xFF50C878),
                          icon: Icons.menu_book,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PapersListScreen(papers: practicePapers, title: "Practice Papers"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // _buildPaperCard(
                        //   title: "Pyq Papers",
                        //   count: pyq.length,
                        //   color:  Colors.yellow,
                        //   icon: Icons.menu_book,
                        //   onTap: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (_) => PapersListScreen(papers: pyq, title: "Pyq Papers"),
                        //     ),
                        //   ),
                        // ),
                      ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}