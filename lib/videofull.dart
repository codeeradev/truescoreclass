import 'package:flutter/material.dart';

import 'Screens/Youtubeplayer.dart';

class VideoListScreenfull extends StatelessWidget {
  final List<dynamic> videoLectures;

  const VideoListScreenfull({
    super.key,
    required this.videoLectures,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Video Lectures"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: videoLectures.isEmpty
          ? const Center(
        child: Text(
          "No videos available",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videoLectures.length,
        itemBuilder: (context, index) {
          final video = videoLectures[index];
          final String title = video["title"] ?? "Untitled";
          final String url = video["url"] ?? "";
          final String subject = video["subject"] ?? "";

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.red,
                  size: 34,
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                subject,
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: url.isNotEmpty
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(
                      videoTitle: title,
                      youtubeUrl: url,
                    ),
                  ),
                );
              }
                  : null,
            ),
          );
        },
      ),
    );
  }
}
