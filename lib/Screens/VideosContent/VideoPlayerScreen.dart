import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoplayerScreen extends StatefulWidget {
  final String? initialVideoUrl;
  final bool isUserEnrolled;

  const VideoplayerScreen({
    super.key,
    this.initialVideoUrl,
    required this.isUserEnrolled,
  });

  @override
  State<VideoplayerScreen> createState() => _VideoplayerScreenState();
}

class _VideoplayerScreenState extends State<VideoplayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isError = false;
  bool seeMore = false;
  String? _currentVideoUrl;

  final List<Map<String, dynamic>> relatedVideos = [
    {
      'title': 'Big Buck Bunny',
      'duration': '9:56',
      'thumbnail': 'assets/images/s1.png',
      'uploadDate': 'May 5, 2025',
      'description': 'A giant rabbit with a heart bigger than himself',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
    },
    {
      'title': 'Elephant Dream',
      'duration': '10:53',
      'thumbnail': 'assets/images/s2.png',
      'uploadDate': 'May 6, 2025',
      'description': 'The first Blender Open Movie from 2006',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'
    },
    {
      'title': 'Sintel',
      'duration': '14:48',
      'thumbnail': 'assets/images/s3.png',
      'uploadDate': 'May 7, 2025',
      'description': 'Third Blender Open Movie from 2010',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.initialVideoUrl ?? relatedVideos[0]['url'];
    initializePlayer(_currentVideoUrl!);
  }

  Future<void> initializePlayer(String videoUrl) async {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    setState(() {
      _isInitialized = false;
      _isError = false;
    });

    try {
      _videoPlayerController = VideoPlayerController.network(videoUrl);
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.grey,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)));
        },
      );

      setState(() {
        _isInitialized = true;
        _currentVideoUrl = videoUrl;
      });
    } catch (error) {
      setState(() {
        _isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: $error')),
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _getCurrentVideoTitle() {
    return relatedVideos.firstWhere((video) => video['url'] == _currentVideoUrl, orElse: () => relatedVideos[0])['title'];
  }

  String _getCurrentVideoAuthor() {
    return relatedVideos.firstWhere((video) => video['url'] == _currentVideoUrl, orElse: () => relatedVideos[0])['description'].split(' ').take(2).join(' ');
  }

  String _getCurrentVideoDescription() {
    return relatedVideos.firstWhere((video) => video['url'] == _currentVideoUrl, orElse: () => relatedVideos[0])['description'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Video Player', style: TextStyle(color: Colors.black)),
        elevation: 1,
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 3.7,
            child: _isError
                ? const Center(child: Text('Error loading video'))
                : !_isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Chewie(controller: _chewieController!),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getCurrentVideoTitle(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('By ${_getCurrentVideoAuthor()}', style: const TextStyle(fontSize: 16, color: Colors.grey)),

                  Row(
                    children: [
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(seeMore ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                        onPressed: () => setState(() => seeMore = !seeMore),
                      ),
                    ],
                  ),
                  if (seeMore)
                    Text(_getCurrentVideoDescription(), style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 10),
                  const Text('Related Videos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  /// Related videos list
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: relatedVideos.length,
                    itemBuilder: (context, index) {
                      final video = relatedVideos[index];
                      final isPlayable = widget.isUserEnrolled || index == 0;
                      final isCurrent = video['url'] == _currentVideoUrl;

                      return GestureDetector(
                        onTap: () {
                          if (isPlayable) {
                            initializePlayer(video['url']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text("Please enroll to watch this video."),
                            ));
                          }
                        },
                        child: Stack(
                          children: [
                            Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 140,
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.asset(
                                              video['thumbnail'],
                                              width: 100,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  video['title'],
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text("Duration: ${video['duration']}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                Text("Uploaded: ${video['uploadDate']}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                const SizedBox(height: 6),
                                                Text(
                                                  video['description'],
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isCurrent)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Icon(Icons.play_arrow, color: Colors.blue),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Blur and lock overlay
                                    if (!isPlayable)
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black.withOpacity(0.4),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                                            child: const SizedBox(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            if (!isPlayable)
                              Positioned(
                                top: 50,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: const Text(
                                    "Enroll Now",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )

                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
