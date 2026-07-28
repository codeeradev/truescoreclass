import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/Screens/Student/subject_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseProgressScreen extends StatefulWidget {
  const CourseProgressScreen({super.key});

  @override
  State<CourseProgressScreen> createState() => _CourseProgressScreenState();
}

class _CourseProgressScreenState extends State<CourseProgressScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> batches = [];

  @override
  void initState() {
    super.initState();
    fetchProgress();
  }

  Future<void> fetchProgress() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-progress"),
        body: {"apiToken": token},
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        log("fetchProgress STATUS: ${response.statusCode}");
        log("fetchProgress BODY: ${response.body}");
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

      final bool success = data["status"].toString() == "1" ||
          data["status"].toString() == "true";

      if (success) {
        setState(() {
          batches = data["data"] ?? [];
        });
      } else {
        setState(() {
          errorMessage = data["msg"]?.toString() ?? "Failed to load progress.";
        });
      }
    } on TimeoutException {
      setState(() => errorMessage = "Request timed out. Please try again.");
    } catch (e) {
      if (kDebugMode) log("fetchProgress error--$e");
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
        title: const Text(
          "Course Progress",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildError()
              : batches.isEmpty
                  ? const Center(child: Text("No batches found"))
                  : RefreshIndicator(
                      onRefresh: fetchProgress,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: batches.length,
                        itemBuilder: (context, index) {
                          final batch = batches[index];
                          return _batchCard(batch);
                        },
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
              onPressed: fetchProgress,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchCard(Map<String, dynamic> batch) {
    final String batchId = batch["batch_id"].toString();
    final String batchName = batch["batch_name"]?.toString() ?? "Batch";
    final double percent =
        double.tryParse(batch["progress_percentage"].toString()) ?? 0;
    final int attempted =
        int.tryParse(batch["attempted_questions"].toString()) ?? 0;
    final int total = int.tryParse(batch["total_questions"].toString()) ?? 0;
    final int totalSubjects =
        int.tryParse(batch["total_subjects"].toString()) ?? 0;
    final color = _colorForPercent(percent);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectProgressScreen(batchId: batchId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(
                      value: (percent / 100).clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                    ),
                  ),
                  Text(
                    "${percent.toStringAsFixed(2)}%",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batchName,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$attempted / $total questions attempted",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$totalSubjects subjects",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}


