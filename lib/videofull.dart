import 'dart:developer';

import 'package:flutter/material.dart';

import 'Screens/Youtubeplayer.dart';

class VideoListScreenfull extends StatelessWidget {
  final List<dynamic> videoLectures;

  const VideoListScreenfull({super.key, required this.videoLectures});

  bool _isNumeric(String value) {
    return int.tryParse(value) != null;
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
        title: const Text("Video Subjects"),
      ),
      body: groupedVideos.isEmpty
          ? const Center(
        child: Text("No videos available"),
      )
          : ListView.builder(
        itemCount: groupedVideos.length,
        itemBuilder: (context, index) {
          final subject = groupedVideos.keys.elementAt(index);

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: ListTile(
              leading: const Icon(
                Icons.folder,
                color: Colors.orange,
                size: 30,
              ),
              title: Text(
                subject,
                style: const TextStyle(
                    fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  "${groupedVideos[subject]!.length} Videos"),
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
        title: Text(subject),
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