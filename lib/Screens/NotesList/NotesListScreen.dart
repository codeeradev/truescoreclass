import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:online_classes/Screens/NotesList/NoteViewer_Screen.dart';

class NotesListScreen extends StatefulWidget {
  final bool isUserEnrolled;

  const NotesListScreen({super.key, required this.isUserEnrolled});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final List<String> subjects = [
    'Quantitative Aptitude',
    'English',
    'Reasoning',
    'General Awareness',
  ];

  int selectedSubjectIndex = 0;

  final List<Map<String, String>> allNotes = [
    {
      'title': 'Percentage Notes',
      'subject': 'Quantitative Aptitude',
      'desc': 'Concepts and shortcuts for percentage problems.',
    },
    {
      'title': 'Data Interpretation Notes',
      'subject': 'Quantitative Aptitude',
      'desc': 'DI concepts with solved examples.',
    },
    {
      'title': 'Grammar Essentials',
      'subject': 'English',
      'desc': 'Important grammar rules for SSC exams.',
    },
    {
      'title': 'Reasoning Basics',
      'subject': 'Reasoning',
      'desc': 'Key topics and tricks for logical reasoning.',
    },
    {
      'title': 'Puzzle Practice Notes',
      'subject': 'Reasoning',
      'desc': 'Practice sets for puzzles and seating arrangements.',
    },
    {
      'title': 'History Summary',
      'subject': 'General Awareness',
      'desc': 'Important events in ancient Indian history.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredNotes = allNotes
        .where((note) => note['subject'] == subjects[selectedSubjectIndex])
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          const SizedBox(height: 14),
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
                    margin: const EdgeInsets.only(right: 12, left: 12),
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
          const SizedBox(height: 12),
          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(child: Text("No notes found for this subject."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final note = filteredNotes[index];
                final isAccessible = widget.isUserEnrolled || index == 0;

                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (isAccessible) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteviewerScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enroll to access this note."),
                            ),
                          );
                        }
                      },
                      child: Card(
                        color:Colors.white,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.note_alt, size: 40, color: Colors.deepPurple),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            note['title']!,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            note['desc']!,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.download, color: Colors.blue),
                                  ],
                                ),
                              ),

                              // Blur overlay for locked notes
                              if (!isAccessible)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(0.2),
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
                    ),

                    /// Enroll Now badge for locked items
                    if (!isAccessible)
                      Positioned(
                        top: 30,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: const Text(
                            "Enroll Now",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
