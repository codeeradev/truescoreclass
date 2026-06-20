import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../servcies.dart';

class VideoPlayerScreen extends StatefulWidget {
  final dynamic videoLectures;

  const VideoPlayerScreen({
    super.key,
    required this.videoLectures,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _youtubeController;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isMuted = false;
  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _isMuted = false;
    final data = widget.videoLectures;
    final videoType = data['video_type'] ?? '';
    final url = data['url'] ?? '';

    if (videoType == 'youtube') {
      _initYoutube(url);
    } else {
      _initNetworkVideo(url);
    }
  }

  void _initYoutube(String url) {
    final videoId = getYoutubeVideoId(url);

    if (videoId.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    }
  }

  Future<void> _initNetworkVideo(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(_fixVideoUrl(url)),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,

        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,

        showControls: true,

        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade400,
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Video Error: $e");
    }
  }

  String _fixVideoUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }

    return "https://truescoreedu.com/$url";
  }

  @override
  void dispose() {
    _youtubeController?.dispose();

    _chewieController?.dispose();
    _videoController?.dispose();

    SecureScreen.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.videoLectures['title']?.toString() ?? "Video Lecture";

    final videoType =
        widget.videoLectures['video_type']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (videoType == "youtube" && _youtubeController != null)
              Stack(
                children: [
                  YoutubePlayerBuilder(
                    player: YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                    ),
                    builder: (context, player) {
                      return player;
                    },
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isMuted) {
                              _youtubeController?.unMute();
                              _isMuted = false;
                            } else {
                              _youtubeController?.mute();
                              _isMuted = true;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            else if (_chewieController != null)
              AspectRatio(
                aspectRatio:
                _videoController!.value.aspectRatio,
                child: Chewie(
                  controller: _chewieController!,
                ),
              )

            else
              Center(
                child: const Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              ),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getYoutubeVideoId(String url) {
    final liveMatch =
    RegExp(r'youtube\.com/live/([^?&]+)')
        .firstMatch(url);

    if (liveMatch != null) {
      return liveMatch.group(1)!;
    }

    return YoutubePlayer.convertUrlToId(url) ?? "";
  }
}