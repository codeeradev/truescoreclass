import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String url;

  const PdfViewerScreen({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    // Ensure the URL is not empty
    if (url.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            'No PDF available!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
      ),
      body: SfPdfViewer.network(
        url,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
      ),
    );
  }
}
