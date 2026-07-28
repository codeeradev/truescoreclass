import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/Screens/Student/chapter_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SubjectProgressScreen extends StatefulWidget {
  final String batchId;

  const SubjectProgressScreen({super.key, required this.batchId});

  @override
  State<SubjectProgressScreen> createState() => _SubjectProgressScreenState();
}

class _SubjectProgressScreenState extends State<SubjectProgressScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? batchInfo;
  List<dynamic> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchBatchProgress();
  }

  Future<void> fetchBatchProgress() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("token--$token");
    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-progress"),
        body: {
          "apiToken": token,
          "batch_id": widget.batchId,
          "subject_id": "",
        },
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        log("fetchBatchProgress STATUS: ${response.statusCode}");
        log("fetchBatchProgress BODY: ${response.body}");
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
          batchInfo = data["batch_info"];
          subjects = data["subjects"] ?? [];
        });
      } else {
        setState(() {
          errorMessage = data["msg"]?.toString() ?? "Failed to load progress.";
        });
      }
    } on TimeoutException {
      setState(() => errorMessage = "Request timed out. Please try again.");
    } catch (e) {
      if (kDebugMode) log("fetchBatchProgress error--$e");
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
          batchInfo?["batch_name"]?.toString() ?? "Batch Progress",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: fetchBatchProgress,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (batchInfo != null) _buildBatchHeader(),
                      const SizedBox(height: 22),
                      if (subjects.isNotEmpty)
                        const Text(
                          "Subjects",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (subjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Center(child: Text("No subjects available")),
                        )
                      else
                        ...subjects.map((s) => _subjectCard(s)).toList(),
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
              onPressed: fetchBatchProgress,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchHeader() {
    final double percent =
        double.tryParse(batchInfo!["progress_percentage"].toString()) ?? 0.0;
    final int attempted =
        int.tryParse(batchInfo!["attempted_questions"].toString()) ?? 0;
    final int total =
        int.tryParse(batchInfo!["total_questions"].toString()) ?? 0;
    final int totalSubjects =
        int.tryParse(batchInfo!["total_subjects"].toString()) ?? 0;
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
              _miniStat("$totalSubjects", "Subjects"),
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

  Widget _subjectCard(Map<String, dynamic> subject) {
    final String subjectId = subject["subject_id"]?.toString() ?? "";
    final String name = subject["subject_name"]?.toString() ?? "Subject";
    final double percent =
        double.tryParse(subject["progress_percentage"].toString()) ?? 0.0;
    final int attempted =
        int.tryParse(subject["attempted_questions"].toString()) ?? 0;
    final int total = int.tryParse(subject["total_questions"].toString()) ?? 0;
    final int chapters =
        int.tryParse(subject["total_chapters"].toString()) ?? 0;
    final color = _colorForPercent(percent);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChapterProgressScreen(
              batchId: widget.batchId,
              subjectId: subjectId,
              subjectName: name,
            ),
          ),
        );
      },
      child: Container(
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
                  child: Icon(Icons.menu_book_rounded, color: color, size: 22),
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
                        "$chapters chapters",
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
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400, size: 22),
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
      ),
    );
  }
}
