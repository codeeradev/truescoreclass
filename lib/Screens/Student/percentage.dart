import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class CourseProgressScreen extends StatefulWidget {
  final String batchId;

  const CourseProgressScreen({super.key, required this.batchId});

  @override
  State<CourseProgressScreen> createState() => _CourseProgressScreenState();
}

class _CourseProgressScreenState extends State<CourseProgressScreen> {
  double mcq = 0;
  double ca = 0;
  double pyq = 0;
  Future<double> getCompletionPercentage({
    required String batchId,
    required String questionType,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final total =
        prefs.getInt("batch_${batchId}_total_$questionType") ?? 0;
    final progress =
        prefs.getInt("batch_${batchId}_progress_$questionType") ?? 0;

    if (total == 0) return 0;
    return (progress / total) * 100;
  }



  @override
  void initState() {
    super.initState();
    _loadProgress();
  }
  Future<void> _loadProgress() async {
    mcq = await getCompletionPercentage(batchId: widget.batchId, questionType: "1");
    ca = await getCompletionPercentage(batchId: widget.batchId, questionType: "2");
    pyq = await getCompletionPercentage(batchId: widget.batchId, questionType: "3");
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Course Progress")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _progressCard("MCQ", mcq, Colors.blue),
            _progressCard("Current Affairs", ca, Colors.orange),
            _progressCard("PYQ", pyq, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(String title, double percent, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          /// PROGRESS BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: color,
            ),
          ),
          const SizedBox(height: 8),

          /// PERCENT TEXT
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${percent.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
