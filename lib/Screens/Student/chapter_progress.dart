import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChapterProgressScreen extends StatefulWidget {
  final String batchId;
  final String subjectId;
  final String? subjectName;

  const ChapterProgressScreen({
    super.key,
    required this.batchId,
    required this.subjectId,
    this.subjectName,
  });

  @override
  State<ChapterProgressScreen> createState() => _ChapterProgressScreenState();
}

class _ChapterProgressScreenState extends State<ChapterProgressScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? subjectInfo;
  List<dynamic> chapters = [];

  @override
  void initState() {
    super.initState();
    fetchChapterProgress();
  }

  Future<void> fetchChapterProgress() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-progress"),
        body: {
          "apiToken": token,
          "batch_id": widget.batchId,
          "subject_id": widget.subjectId,
        },
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        log("fetchChapterProgress STATUS: ${response.statusCode}");
        log("fetchChapterProgress BODY: ${response.body}");
      }

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }

      if (response.body.trim().startsWith('<')) {
        throw Exception("Server returned HTML instead of JSON");
      }

      final data = jsonDecode(response.body);
      if (!mounted) return;

      final bool success = data["status"].toString() == "1" ||
          data["status"].toString() == "true";

      if (success) {
        setState(() {
          subjectInfo = data["subject_info"];
          chapters = data["chapters"] ?? [];
        });
      } else {
        setState(() {
          errorMessage = data["msg"]?.toString() ?? "Failed to load progress.";
        });
      }
    } on TimeoutException {
      setState(() => errorMessage = "Request timed out. Please try again.");
    } catch (e) {
      if (kDebugMode) log("fetchChapterProgress error--$e");
      if (!mounted) return;
      setState(() => errorMessage = "Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Color _colorForPercent(double percent) {
    if (percent >= 75) return Colors.green;
    if (percent >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          subjectInfo?["subject_name"]?.toString() ??
              widget.subjectName ??
              "Chapter Progress",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : RefreshIndicator(
        onRefresh: fetchChapterProgress,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (subjectInfo != null) _buildSubjectHeader(),
            const SizedBox(height: 22),
            if (chapters.isNotEmpty)
              const Text(
                "Chapters",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 12),
            if (chapters.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: Text("No chapters available")),
              )
            else
              ...chapters.map((c) => _chapterCard(c)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? "Something went wrong.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchChapterProgress,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectHeader() {
    final double percent =
        double.tryParse(subjectInfo!["progress_percentage"].toString()) ??
            0.0;
    final int attempted =
        int.tryParse(subjectInfo!["attempted_questions"].toString()) ?? 0;
    final int total =
        int.tryParse(subjectInfo!["total_questions"].toString()) ?? 0;
    final int totalChapters =
        int.tryParse(subjectInfo!["total_chapters"].toString()) ?? 0;
    final color = _colorForPercent(percent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    strokeWidth: 11,
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${percent.toStringAsFixed(2)}%",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Text(
                      "Overall",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat("$attempted", "Attempted"),
              _miniDivider(),
              _miniStat("$total", "Total Qs"),
              _miniDivider(),
              _miniStat("$totalChapters", "Chapters"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _miniDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }

  Widget _chapterCard(Map<String, dynamic> chapter) {
    final String name = chapter["chapter_name"]?.toString() ?? "Chapter";
    final double percent =
        double.tryParse(chapter["progress_percentage"].toString()) ?? 0.0;
    final int attempted =
        int.tryParse(chapter["attempted_questions"].toString()) ?? 0;
    final int total =
        int.tryParse(chapter["total_questions"].toString()) ?? 0;
    final color = _colorForPercent(percent);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.bookmark_border_rounded,
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$total questions",
                      style: const TextStyle(
                          fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Text(
                "${percent.toStringAsFixed(2)}%",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$attempted / $total questions attempted",
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}