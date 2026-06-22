import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  static const String _localStorageKey = "local_teacher_meetings";
  bool isLoading = true;
  String errorMessage = '';
  List meetings = [];

  // static const List<String> _meetingEndpoints = [
  //   "https://truescoreedu.com/api/get-student-meetings",
  //   "https://truescoreedu.com/api/active-meetings",
  //   "https://truescoreedu.com/api/get-live-class",
  // ];

  @override
  void initState() {
    super.initState();
    fetchMeetings();
  }

  Future<void> fetchMeetings() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // dynamic rawData;
      // int successCode = 0;

      // for (final endpoint in _meetingEndpoints) {
      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/get-live-class'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": token},
      );
      print("response--${response.statusCode}---${response.body}");
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // rawData = decoded["data"];
        // successCode = 200;
        if (decoded['status'].toString() == '1') {
          setState(() {
            meetings = decoded['data'];
          });
        }
      }
      // }

      // final localMeetings = await _loadLocalMeetings(prefs);

      // if (successCode != 200) {
      //   setState(() {
      //     meetings = localMeetings;
      //     isLoading = false;
      //     errorMessage = localMeetings.isEmpty ? "Failed to load meetings" : '';
      //   });
      //   return;
      // }
      //
      // List<dynamic> rawList = [];
      // if (rawData is List) {
      //   rawList = rawData;
      // } else if (rawData is Map && rawData["meetings"] is List) {
      //   rawList = rawData["meetings"] as List<dynamic>;
      // }
      //
      // final parsed =
      //     rawList
      //         .map<Map<String, String>>((item) {
      //           final data = item is Map ? item : <String, dynamic>{};
      //
      //           final title =
      //               (data["title"] ??
      //                       data["meeting_title"] ??
      //                       data["name"] ??
      //                       "Live Meeting")
      //                   .toString();
      //           final when =
      //               (data["date_time"] ??
      //                       data["scheduled_at"] ??
      //                       data["start_time"] ??
      //                       data["date"] ??
      //                       "")
      //                   .toString();
      //           final rawLink =
      //               (data["meeting_link"] ??
      //                       data["meet_link"] ??
      //                       data["link"] ??
      //                       data["url"] ??
      //                       "")
      //                   .toString();
      //
      //           final normalizedLink = _normalizeUrl(rawLink);
      //           return {"title": title, "time": when, "link": normalizedLink};
      //         })
      //         .where((e) => (e["link"] ?? "").isNotEmpty)
      //         .toList();
      //
      // final combined = [...parsed];
      // for (final m in localMeetings) {
      //   final link = m["link"] ?? "";
      //   if (link.isEmpty) continue;
      //   if (!combined.any((item) => (item["link"] ?? "") == link)) {
      //     combined.add(m);
      //   }
      // }

      // setState(() {
      //   meetings = combined;
      //   isLoading = false;
      // });
    } catch (_) {
      setState(() {
        isLoading = false;
        errorMessage = "Unable to load meetings right now";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Future<List<Map<String, String>>> _loadLocalMeetings(
  //   SharedPreferences prefs,
  // )
  // async {
  //   final raw = prefs.getString(_localStorageKey);
  //   if (raw == null || raw.isEmpty) return [];
  //   try {
  //     final decoded = jsonDecode(raw);
  //     if (decoded is! List) return [];
  //     return decoded
  //         .map<Map<String, String>>((item) {
  //           final data = item is Map ? item : <String, dynamic>{};
  //           final title = (data["title"] ?? "Live Meeting").toString();
  //           final when =
  //               (data["date_time_label"] ?? data["date_time"] ?? "").toString();
  //           final link = _normalizeUrl((data["meeting_link"] ?? "").toString());
  //           return {"title": title, "time": when, "link": link};
  //         })
  //         .where((e) => (e["link"] ?? "").isNotEmpty)
  //         .toList();
  //   } catch (_) {
  //     return [];
  //   }
  // }

  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return "";
    if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
      return trimmed;
    }
    return "https://$trimmed";
  }

  Future<void> _joinMeeting(String rawUrl) async {
    final link = _normalizeUrl(rawUrl);
    final uri = Uri.tryParse(link);

    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid meeting link")));
      return;
    }

    final openedInApp = await launchUrl(
      uri,
      mode: LaunchMode.externalNonBrowserApplication,
    );

    if (openedInApp) return;

    final openedInBrowser = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!openedInBrowser && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open meeting link")),
      );
    }
  }
  Color getStatusColor(String status) {
    switch (status) {
      case "upcoming":
        return Colors.blue;
      case "ongoing":
        return Colors.orange;
      case "completed":
        return Colors.green;
      default:
        return Colors.black54;
    }
  }
  @override
  Widget build(BuildContext context) {
    print("object--$meetings");
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Live Class"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: fetchMeetings,
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                )
                : meetings.isEmpty
                ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.video_call_outlined,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No meetings available",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final item = meetings[index];

                    final title = item["title"] ?? "Meeting";
                    final link = item["meeting_link"] ?? "";
                    final batch = item["batch"]?["name"] ?? "";
                    final subject = item["subject"]?["name"] ?? "";
                    final chapter = item["chapter"]?["name"] ?? "";
                    final date = item["date"] ?? "";
                    final startTime = item["start_time"] ?? "";
                    final endTime = item["end_time"] ?? "";
                    final status =
                        (item["class_status"] ?? "").toString().toLowerCase();
                    return Card(
                      color: getStatusColor(status).withValues(alpha: 0.15),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: getStatusColor(status),
                          width: 1.2,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              status,
                            ).withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.video_camera_front_rounded,
                            color: Colors.blue,
                          ),
                        ),

                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),

                            if (batch.isNotEmpty) Text("Batch: $batch"),

                            if (subject.isNotEmpty) Text("Subject: $subject"),
                            if (chapter.isNotEmpty) Text("Chapter: $chapter"),
                            if (date.isNotEmpty) Text("Date: $date"),
                            if (startTime.isNotEmpty && endTime.isNotEmpty)
                              Text("Time: $startTime - $endTime"),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    link,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: link),
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Meeting link copied"),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),

                        onTap: () => _joinMeeting(link),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
