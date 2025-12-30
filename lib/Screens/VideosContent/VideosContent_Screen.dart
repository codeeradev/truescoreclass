import 'dart:ui';

import 'package:flutter/material.dart';
import 'VideoPlayerScreen.dart';

class VideoListScreen extends StatefulWidget {
  final bool isUserEnrolled;

  const VideoListScreen({super.key, required this.isUserEnrolled});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final List<String> subjects = [
    'Quantitative Aptitude',
    'English',
    'Reasoning',
    'General Awareness',
  ];

  int selectedSubjectIndex = 0;
  bool enrolled = false;

  @override
  void initState() {
    if(widget.isUserEnrolled == true){
      setState(() {
        enrolled = true;
      });
    }
    super.initState();
  }


  // Mock video data
  final List<Map<String, String>> allVideos = [
    {
      'title': 'Percentage Tricks',
      'subject': 'Quantitative Aptitude',
      'duration': '12 mins',
      'uploaded': 'May 5, 2025',
      'desc': 'Learn shortcuts and formulas to solve percentage questions quickly.'
    },
    {
      'title': 'Subject-Verb Agreement',
      'subject': 'English',
      'duration': '10 mins',
      'uploaded': 'April 28, 2025',
      'desc': 'Master grammar rules related to subject-verb agreement for error spotting.'
    },
    {
      'title': 'Coding-Decoding Techniques',
      'subject': 'Reasoning',
      'duration': '15 mins',
      'uploaded': 'April 25, 2025',
      'desc': 'Understand pattern-based and letter-based coding-decoding questions.'
    },
    {
      'title': 'Puzzle Solving Strategy',
      'subject': 'Reasoning',
      'duration': '11 mins',
      'uploaded': 'March 29, 2025',
      'desc': 'Step-by-step approach to solve seating arrangement and puzzle questions.'
    },
    {
      'title': 'Data Interpretation Basics',
      'subject': 'Quantitative Aptitude',
      'duration': '14 mins',
      'uploaded': 'April 20, 2025',
      'desc': 'Interpret tables, pie charts, and graphs efficiently in exams.'
    },
    {
      'title': 'Ancient History Highlights',
      'subject': 'General Awareness',
      'duration': '18 mins',
      'uploaded': 'April 10, 2025',
      'desc': 'Quick revision of important events and dynasties from ancient Indian history.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredVideos = allVideos
        .where((video) => video['subject'] == subjects[selectedSubjectIndex])
        .toList();


    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal subject selector
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == selectedSubjectIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSubjectIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Center(
                          child: Text(
                            subjects[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Video list
              if (filteredVideos.isEmpty) const Text("No videos found for this subject.") else ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filteredVideos.length,
                itemBuilder: (context, index) {
                  final video = filteredVideos[index];
                  final isPlayable = widget.isUserEnrolled || index == 0;

                  return GestureDetector(
                    onTap: () {
                      if (isPlayable) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoplayerScreen(isUserEnrolled: enrolled),
                          ),
                        );
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
                          child: Container(
                            height: 140,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/s1.png',
                                  width: 100,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video['title']!,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Duration: ${video['duration']}",
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                      ),
                                      Text(
                                        "Uploaded: ${video['uploaded']}",
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        video['desc']!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Blur overlay if not playable
                        if (!isPlayable)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  color: Colors.black.withOpacity(0.2),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "Enroll to Watch",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}
