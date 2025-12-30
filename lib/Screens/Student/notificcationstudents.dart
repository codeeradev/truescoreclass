import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen1 extends StatefulWidget {
  const NotificationScreen1({super.key});

  @override
  State<NotificationScreen1> createState() => _NotificationScreen1State();
}

class _NotificationScreen1State extends State<NotificationScreen1> {
  bool isLoading = false;
  List<dynamic> notices = [];

  @override
  void initState() {
    super.initState();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    setState(() => isLoading = true);

    SharedPreferences pref = await SharedPreferences.getInstance();
    String apiToken = pref.getString("token") ?? "";

    try {
      final response = await http.post(
        Uri.parse("https://testora.codeeratech.in/api/active-notices"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"apiToken": apiToken},
      );

      print("NOTICE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == 1) {
          setState(() => notices = data["data"]);
        }
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Active Notices",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : notices.isEmpty
          ? const Center(
        child: Text(
          "No active notices",
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final n = notices[index];
          return _noticeCard(n);
        },
      ),
    );
  }

  //-------------- Notice Card --------------//
  Widget _noticeCard(dynamic n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Notice For
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  n["title"] ?? "",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              _pill(n["notice_for"]),
            ],
          ),

          const SizedBox(height: 10),

          // Description
          Text(
            n["description"] ?? "",
            style: const TextStyle(
              color: Colors.black87,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 15),

          // Date Row
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                n["date"] ?? "",
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //-------------- Notice For Pill --------------//
  Widget _pill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
