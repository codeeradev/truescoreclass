import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../servcies.dart';

class GetNotesScreen extends StatefulWidget {
  final String batchid;
   GetNotesScreen({super.key,required this.batchid});

  @override
  State<GetNotesScreen> createState() => _GetNotesScreenState();


}

class _GetNotesScreenState extends State<GetNotesScreen> {

  bool isLoading = true;
  List<dynamic> notes = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();

    fetchNotes();
  }


  Future<void> fetchNotes() async {
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
        Uri.parse("https://truescoreedu.com/api/get-notes"),
        body: {
          "apiToken": token,
          "course_id":widget.batchid.toString()
        },
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 1) {
          setState(() {
            notes = json['notes'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = json['message'] ?? "No notes found";
            isLoading = false;
          });

        }

      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load notes. Check your connection.";
        isLoading = false;
      });
    }
  }

  void _openPdf(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfUrl: url, title: title),
      ),
    );
  }

  @override
  void dispose() {
    SecureScreen.disable();

    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "My Notes",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        )
            : errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchNotes,
                child: const Text("Retry"),
              ),
            ],
          ),
        )
            : notes.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_outlined, size: 100, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                "No notes available yet",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Text(
                "Your teacher will upload notes soon",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: fetchNotes,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final String title = note["title"] ?? "Untitled Note";
              final String fileUrl = note["file_url"] ?? "";
              final String date = note["added_at"] ?? "";
              final String subject = note["subject_name"] ?? "Unknown Subject";
              final String chapter = note["chapter_name"] ?? "";

              return Card(
                elevation: 6,
                shadowColor: Colors.blue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: fileUrl.isNotEmpty
                      ? () => _openPdf(fileUrl, title)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // PDF Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red.shade700,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (subject.isNotEmpty)
                                Text(
                                  subject,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (chapter.isNotEmpty)
                                Text(
                                  "Chapter: $chapter",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Arrow
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Unknown date";
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return "Today";
      if (diff.inDays == 1) return "Yesterday";
      if (diff.inDays < 7) return "${diff.inDays} days ago";
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr.split(" ").first;
    }
  }
}

// Separate screen for viewing PDF inside the app
class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load PDF: ${details.description}")),
          );
        },
        canShowScrollHead: true,
        canShowPaginationDialog: true,
      ),
    );
  }
}