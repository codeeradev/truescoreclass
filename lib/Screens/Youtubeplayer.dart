// video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoTitle;
  final String youtubeUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoTitle,
    required this.youtubeUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();

    final videoId = getYoutubeVideoId(widget.youtubeUrl);

    if (videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.videoTitle)),
        body: const Center(child: Text("Invalid YouTube video")),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.videoTitle)),
          body: Column(
            children: [
              player,
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.videoTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

}
