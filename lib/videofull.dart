import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'Screens/Youtubeplayer.dart';

class VideoListScreenfull extends StatefulWidget {
  final String courseId;

  const VideoListScreenfull({super.key, required this.courseId});

  @override
  State<VideoListScreenfull> createState() => _VideoListScreenfullState();
}

class _VideoListScreenfullState extends State<VideoListScreenfull> {
  bool _isNumeric(String value) => int.tryParse(value) != null;

  List videoLectures = [];
  bool isLoading = true; // first load
  bool isLoadingMore = false; // subsequent pages
  bool hasMore = true; // stop when API returns empty
  int currentPage = 1;
  final int pageSize = 10; // how many per request

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchApiCourseVideos();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMore) {
        fetchApiCourseVideos(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchApiCourseVideos({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        currentPage = 1;
        hasMore = true;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final int offset = (currentPage - 1) * pageSize;

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-course-videos"),
        body: {
          "apiToken": token,
          "courseId": widget.courseId,
          "page": currentPage.toString(),
          "offset": offset.toString(),
        },
      );

      if (kDebugMode) {
        log("STATUS: ${response.statusCode}");
        log("BODY: ${response.body}");
      }

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }

      if (response.body.trim().startsWith('<')) {
        throw Exception(
            "Server returned HTML instead of JSON — check API endpoint/params");
      }

      final data = jsonDecode(response.body);

      if (kDebugMode) {
        log("fetchApiCourseVideos---${response.statusCode}\ndata--$data");
      }

      if (data["status"].toString() == "true") {
        final List newVideos = data["data"]["videoLectures"] ?? [];

        setState(() {
          if (newVideos.isEmpty) {
            hasMore = false;
          } else {
            videoLectures.addAll(newVideos);
            currentPage++; // move to next page for the next call
            if (newVideos.length < pageSize) {
              hasMore = false; // last page had fewer than pageSize items
            }
          }
        });
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('error--$e');
      hasMore = false;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<dynamic>> groupedVideos = {};
    for (var video in videoLectures) {
      dynamic subjectValue = video["subject_name"];
      String subject;
      if (subjectValue == null) {
        subject = "Other Subjects";
      } else if (subjectValue is int) {
        subject = "Other Subjects";
      } else {
        subject = subjectValue.toString().trim();
        if (subject.isEmpty || _isNumeric(subject)) {
          subject = "Other Subjects";
        }
      }
      groupedVideos.putIfAbsent(subject, () => []).add(video);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Video Subjects",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedVideos.isEmpty
              ? const Center(child: Text("No videos available"))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: groupedVideos.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= groupedVideos.length) {
                      if (isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox(height: 20);
                    }

                    final subject = groupedVideos.keys.elementAt(index);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.folder,
                            color: Colors.orange, size: 30),
                        title: Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text("${groupedVideos[subject]!.length} Videos"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubjectVideosScreen(
                                subject: subject,
                                videos: groupedVideos[subject]!,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class SubjectVideosScreen extends StatelessWidget {
  final String subject;
  final List<dynamic> videos;

  const SubjectVideosScreen({
    super.key,
    required this.subject,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          subject,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];

          final title = video["title"]?.toString() ?? "Untitled";
          final url = video["url"]?.toString() ?? "";

          return Card(
            child: ListTile(
              leading: const Icon(
                Icons.play_circle_fill,
                color: Colors.red,
                size: 35,
              ),
              title: Text(title),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: url.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(
                            videoLectures: video,
                          ),
                        ),
                      );
                    },
            ),
          );
        },
      ),
    );
  }
}
