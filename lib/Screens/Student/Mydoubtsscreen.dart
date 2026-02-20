// import 'dart:convert';
// import 'package:expandable_text/expandable_text.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import '../../servcies.dart';
//
// class GetDoubtsScreenstudent extends StatefulWidget {
//   const GetDoubtsScreenstudent({super.key});
//
//   @override
//   State<GetDoubtsScreenstudent> createState() => _GetDoubtsScreenstudentState();
//
//
// }
//
// class _GetDoubtsScreenstudentState extends State<GetDoubtsScreenstudent> {
//   bool isLoading = true;
//   List<dynamic> doubts = [];
//   String? errorMessage;
//
//
//   @override
//
//   void initState() {
//
//     super.initState();
//     SecureScreen.enable();
//
//     fetchDoubts();
//   }
//
//   Future<void> fetchDoubts() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//     // Change key if needed (e.g., 'authToken')
//     print(token);
//
//     if (token == null) {
//       setState(() {
//         errorMessage = "Please login again";
//         isLoading = false;
//       });
//       return;
//     }
//
//     try {
//       final response = await http.post(
//         Uri.parse("https://truescoreedu.com/api/get-doubts"),
//         body: {
//           "apiToken": token,
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);
//         print(json);
//
//         if (json['status'] == 1) {
//           setState(() {
//             doubts = json['data'] ?? [];
//             isLoading = false;
//           });
//         } else {
//           setState(() {
//             errorMessage = json['msg'] ?? "No doubts found";
//             isLoading = false;
//           });
//         }
//       } else {
//         throw Exception("Server error");
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = "Failed to load doubts. Check your connection.";
//         isLoading = false;
//       });
//     }
//   }
//   @override
//   void dispose() {
//     SecureScreen.disable();
//
//     // TODO: implement dispose
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           "My Doubts",
//           style: TextStyle(fontWeight: FontWeight.w600,color: Colors.white),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.blue.shade700,
//         elevation: 0,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.blue.shade50,
//               Colors.white,
//             ],
//           ),
//         ),
//         child: isLoading
//             ? const Center(
//           child: CircularProgressIndicator(color: Colors.blue),
//         )
//             : errorMessage != null
//             ? _errorState()
//             : doubts.isEmpty
//             ? _emptyState()
//             : RefreshIndicator(
//           onRefresh: fetchDoubts,
//           color: Colors.blue,
//           child: ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: doubts.length,
//             itemBuilder: (context, index) {
//               final doubt = doubts[index];
//               final String question =
//                   doubt["description"] ?? "No question";
//               final String answer =
//                   doubt["teacher_description"] ?? "";
//               final String file =
//                   doubt["file"] ?? "";
//
//               return _doubtCard(question, answer,file);
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   bool isPdf(String url) {
//     return url.toLowerCase().endsWith(".pdf");
//   }
//
//   bool isImage(String url) {
//     return url.toLowerCase().endsWith(".png") ||
//         url.toLowerCase().endsWith(".jpg") ||
//         url.toLowerCase().endsWith(".jpeg") ||
//         url.toLowerCase().endsWith(".webp");
//   }
//
//   Widget _doubtCard(String question, String answer,String file) {
//     final bool hasAnswer = answer.trim().isNotEmpty;
//     return Container(height: 240,
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.blue.withOpacity(0.08),
//             blurRadius: 10,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Left accent bar
//           Container(
//             width: 5,
//             height: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.blue.shade600,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(16),
//                 bottomLeft: Radius.circular(16),
//               ),
//             ),
//           ),
//
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Question chip
//                   Row(
//                     children: [
//                       Icon(Icons.help_outline,
//                           size: 18, color: Colors.blue.shade700),
//                       const SizedBox(width: 6),
//                       const Text(
//                         "Question",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.blue,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     question,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       height: 1.5,
//                       color: Colors.black87,
//                     ),
//                   ),
//
//                   if (answer.isNotEmpty) ...[
//                     const SizedBox(height: 14),
//                     const Divider(),
//                     const SizedBox(height: 6),
//
//                     // Answer chip
//                     Row(
//                       children: const [
//                         Icon(Icons.check_circle_outline,
//                             size: 18, color: Colors.green),
//                         SizedBox(width: 6),
//                         Text(
//                           "Tap on ans text to read full ans...",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: Colors.green,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 6),
//                     file != null && file.toString().isNotEmpty
//                         ? InkWell(
//                       onTap: () {
//                         if (isPdf(file)) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => PdfViewScreen(pdfUrl: file),
//                             ),
//                           );
//                         } else if (isImage(file)) {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => ImageViewScreen(imageUrl: file),
//                             ),
//                           );
//                         }
//                       },
//                       child: Row(
//                         children: [
//                           Icon(
//                             isPdf(file) ? Icons.picture_as_pdf : Icons.image,
//                             color: isPdf(file) ? Colors.red : Colors.blue,
//                           ),
//                           const SizedBox(width: 6),
//                           Expanded(
//                             child: isPdf(file) ?Text(
//                               "Open Pdf",
//                               style: const TextStyle(
//                                 color: Colors.blue,
//                                 //decoration: TextDecoration.underline,
//                               ),
//                             ):Text(
//                               "Open Image",
//                               style: const TextStyle(
//                                 color: Colors.blue,
//                                // decoration: TextDecoration.underline,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                         : const SizedBox(),
//
//
//                     const SizedBox(height: 6),
//     GestureDetector(
//     onTap:
//     //hasAnswer && answer.length > 5
//     //?
//         () => _showFullAnswerBottomSheet(context, answer),
//         //: null,
//     child: ExpandableText(
//     answer,
//     expandText: 'read more',
//     collapseText: 'show less',
//     maxLines: 2,
//     linkColor: Colors.blue.shade700,
//     ),
//     ),
//
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   void _showFullAnswerBottomSheet(BuildContext context, String answer) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.7,
//         minChildSize: 0.4,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (_, scrollController) => Container(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     "Teacher's Answer",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Expanded(
//                 child: SingleChildScrollView(
//                   controller: scrollController,
//                   child: Text(
//                     answer,
//                     style: const TextStyle(fontSize: 16, height: 1.5),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _errorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline,
//                 size: 80, color: Colors.grey.shade400),
//             const SizedBox(height: 16),
//             Text(
//               errorMessage!,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: fetchDoubts,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.shade700,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//               ),
//               child: const Text("Retry"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _emptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.question_answer_outlined,
//               size: 90, color: Colors.grey.shade300),
//           const SizedBox(height: 20),
//           const Text(
//             "No doubts yet",
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             "Your questions will appear here",
//             style: TextStyle(color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//
//
// }
// class ImageViewScreen extends StatelessWidget {
//   final String imageUrl;
//   const ImageViewScreen({super.key, required this.imageUrl});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Image")),
//       body: Center(
//         child: InteractiveViewer(
//           child: Image.network("https://truescoreedu.com/uploads/doubts_answer/${imageUrl}"),
//         ),
//       ),
//     );
//   }
// }
//
// class PdfViewScreen extends StatelessWidget {
//   final String pdfUrl;
//   const PdfViewScreen({super.key, required this.pdfUrl});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("PDF")),
//       body: SfPdfViewer.network("https://truescoreedu.com/uploads/doubts_answer/${pdfUrl}"),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../servcies.dart';

class GetDoubtsScreenstudent extends StatefulWidget {
  const GetDoubtsScreenstudent({super.key});

  @override
  State<GetDoubtsScreenstudent> createState() =>
      _GetDoubtsScreenstudentState();
}

class _GetDoubtsScreenstudentState extends State<GetDoubtsScreenstudent> {
  bool isLoading = true;
  List<dynamic> doubts = [];
  String? errorMessage;

  @override
  void initState() {
    SecureScreen.enable();

    super.initState();
    SecureScreen.enable();
    fetchDoubts();
    SecureScreen.enable();

  }

  Future<void> fetchDoubts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        errorMessage = "Please login again";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-doubts"),
        body: {"apiToken": token},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print(json);

        if (json['status'] == 1) {
          setState(() {
            doubts = json['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = json['msg'] ?? "No doubts found";
            isLoading = false;
          });
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      setState(() {
        errorMessage = "Failed to load doubts";
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          "My Doubts",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _errorState()
          : doubts.isEmpty
          ? _emptyState()
          : RefreshIndicator(
        onRefresh: fetchDoubts,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doubts.length,
          itemBuilder: (context, index) {
            final doubt = doubts[index];
            return _doubtCard(
              doubt["description"] ?? "",
              doubt["teacher_description"] ?? "",
              doubt["file"] ?? "",
              doubt["created_at"] ?? "",
            );
          },
        ),
      ),
    );
  }
  Widget buildMathText(
      String text, {
        double fontSize = 16,
        FontWeight fontWeight = FontWeight.normal,
      }) {
    bool isMath(String t) {
      return t.contains(r"\frac") ||
          t.contains("^") ||
          t.contains("_") ||
          t.contains(r"\sqrt") ||
          t.contains(r"\sum");
    }

    /// 🧮 MATH → HORIZONTAL SCROLL
    if (isMath(text)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal, // ⭐ KEY FIX
        child: Math.tex(
          text,
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      );
    }

    /// 🔤 NORMAL TEXT
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.5,
        fontWeight: fontWeight,
      ),
    );
  }



  // ================== CARD ==================

  Widget _doubtCard(String question, String answer, String file,String time) {
    final bool hasAnswer = answer.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Row(
                          children: [
                            Icon(Icons.help_outline,
                                size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            const Text(
                              "Question",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                             Text(
                              time.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 6),

                  buildMathText(
                    question,
                    fontSize: 15,
                  ),


                  if (hasAnswer) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 6),

                    Row(
                      children: const [
                        Icon(Icons.check_circle_outline,
                            size: 18, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          "Answer (Tap on Ans to read full)",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (file.isNotEmpty)
                      InkWell(
                        onTap: () {
                          if (isPdf(file)) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PdfViewScreen(pdfUrl: file),
                              ),
                            );
                          } else if (isImage(file)) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ImageViewScreen(imageUrl: file),
                              ),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              isPdf(file)
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              color: isPdf(file)
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isPdf(file) ? "Open PDF" : "Open Image",
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () => _showFullAnswerBottomSheet(context, answer),
                      child: buildMathText(
                        answer,
                        fontSize: 14,
                      ),
                    ),

                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== HELPERS ==================

  bool isPdf(String url) =>
      url.toLowerCase().endsWith(".pdf");

  bool isImage(String url) =>
      url.toLowerCase().endsWith(".png") ||
          url.toLowerCase().endsWith(".jpg") ||
          url.toLowerCase().endsWith(".jpeg") ||
          url.toLowerCase().endsWith(".webp");
  void _showFullAnswerBottomSheet(BuildContext context, String answer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.50,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [

                    /// 🔘 Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    /// 🔹 HEADER
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [

                          /// Title
                          const Expanded(
                            child: Text(
                              "Your Answer",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          /// ❌ Close Button
                          InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    /// 📄 ANSWER CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: SelectableText(
                          answer,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _errorState() => Center(
    child: Text(errorMessage ?? ""),
  );

  Widget _emptyState() => const Center(
    child: Text("No doubts yet"),
  );
}

// ================== IMAGE VIEW ==================

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;
  const ImageViewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image")),
      body: Center(
        child: Image.network(
          "https://truescoreedu.com/uploads/doubts_answer/$imageUrl",
        ),
      ),
    );
  }
}

// ================== PDF VIEW ==================

class PdfViewScreen extends StatelessWidget {
  final String pdfUrl;
  const PdfViewScreen({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PDF")),
      body: SfPdfViewer.network(
        "https://truescoreedu.com/uploads/doubts_answer/$pdfUrl",
      ),
    );
  }
}
