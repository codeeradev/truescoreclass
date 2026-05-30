import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherMeetingsScreen extends StatefulWidget {
  const TeacherMeetingsScreen({super.key});

  @override
  State<TeacherMeetingsScreen> createState() => _TeacherMeetingsScreenState();
}

class _TeacherMeetingsScreenState extends State<TeacherMeetingsScreen> {
  static const String _storageKey = "local_teacher_meetings";

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  DateTime? _selectedDateTime;

  List<Map<String, dynamic>> _meetings = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      if (!mounted) return;
      setState(() => _meetings = []);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final list =
            decoded
                .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map),
                )
                .toList();
        if (!mounted) return;
        setState(() => _meetings = list);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _meetings = []);
    }
  }

  Future<void> _saveMeetings(List<Map<String, dynamic>> meetings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(meetings));
  }

  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return "";
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      return trimmed;
    }
    return "https://$trimmed";
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final amPm = value.hour >= 12 ? "PM" : "AM";
    return "${value.day}/${value.month}/${value.year} $hour:$minute $amPm";
  }

  Future<void> _addMeeting() async {
    final title = _titleController.text.trim();
    final link = _normalizeUrl(_linkController.text);
    final dateTime = _selectedDateTime;

    if (title.isEmpty || link.isEmpty || dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill title, meeting link and date/time"),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final item = <String, dynamic>{
      "id": DateTime.now().microsecondsSinceEpoch.toString(),
      "title": title,
      "meeting_link": link,
      "date_time": dateTime.toIso8601String(),
      "date_time_label": _formatDateTime(dateTime),
      "created_at": DateTime.now().toIso8601String(),
    };

    final updated = [item, ..._meetings];
    await _saveMeetings(updated);

    if (!mounted) return;
    setState(() {
      _meetings = updated;
      _saving = false;
      _titleController.clear();
      _linkController.clear();
      _selectedDateTime = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Meeting saved")));
  }

  Future<void> _deleteMeeting(String id) async {
    final updated = _meetings.where((e) => e["id"]?.toString() != id).toList();
    await _saveMeetings(updated);
    if (!mounted) return;
    setState(() => _meetings = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Meetings"),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add Meeting",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Meeting Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _linkController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: "Meeting Link",
                      hintText: "https://meet.google.com/...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade500),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDateTime == null
                                ? "Select Date & Time"
                                : _formatDateTime(_selectedDateTime!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _addMeeting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_saving ? "Saving..." : "Save Meeting"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Saved Meetings",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_meetings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "No meetings added yet",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            )
          else
            ..._meetings.map((item) {
              final id = item["id"]?.toString() ?? "";
              final title = item["title"]?.toString() ?? "Meeting";
              final time = item["date_time_label"]?.toString() ?? "";
              final link = item["meeting_link"]?.toString() ?? "";

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8EAF6),
                    child: Icon(Icons.video_call_rounded, color: Colors.indigo),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    time.isEmpty ? link : "$time\n$link",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: id.isEmpty ? null : () => _deleteMeeting(id),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
