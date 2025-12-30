import 'dart:ui';

import 'package:flutter/material.dart';
import 'PdfViewerScreen.dart';

class PDFListScreen extends StatefulWidget {
  final bool isUserEnrolled;

  const PDFListScreen({super.key, required this.isUserEnrolled});

  @override
  State<PDFListScreen> createState() => _PDFListScreenState();
}

class _PDFListScreenState extends State<PDFListScreen> {
  final List<String> subjects = [
    'Quantitative Aptitude',
    'English',
    'Reasoning',
    'General Awareness',
  ];

  int selectedSubjectIndex = 0;

  final List<Map<String, String>> allPDFs = [
    {
      'title': 'Percentage Shortcuts',
      'subject': 'Quantitative Aptitude',
      'desc': 'Tricks and formulas for SSC CGL percentage questions.',
      'url': 'https://example.com/pdf1.pdf',
    },
    {
      'title': 'DI Practice Set',
      'subject': 'Quantitative Aptitude',
      'desc': 'Data Interpretation problems with solutions.',
      'url': 'https://example.com/pdf2.pdf',
    },
    {
      'title': 'Verb Agreement Rules',
      'subject': 'English',
      'desc': 'Important grammar rules and examples.',
      'url': 'https://example.com/pdf3.pdf',
    },
    {
      'title': 'Coding-Decoding Guide',
      'subject': 'Reasoning',
      'desc': 'Basic to advanced coding-decoding patterns.',
      'url': 'https://example.com/pdf4.pdf',
    },
    {
      'title': 'Puzzle Solving Methods',
      'subject': 'Reasoning',
      'desc': 'Seating arrangement and puzzle strategies.',
      'url': 'https://example.com/pdf5.pdf',
    },
    {
      'title': 'Ancient History Notes',
      'subject': 'General Awareness',
      'desc': 'Important dynasties and timelines.',
      'url': 'https://example.com/pdf6.pdf',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredPDFs = allPDFs
        .where((pdf) => pdf['subject'] == subjects[selectedSubjectIndex])
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
            child: filteredPDFs.isEmpty
                ? const Center(child: Text("No PDFs found for this subject."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPDFs.length,
              itemBuilder: (context, index) {
                final pdf = filteredPDFs[index];
                final isPlayable = widget.isUserEnrolled || index == 0;

                return Stack(
                  children: [
                    Card(
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
                                  const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pdf['title']!,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pdf['desc']!,
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

                            // Blur overlay
                            if (!isPlayable)
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

                    // "Enroll Now" badge
                    if (!isPlayable)
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
