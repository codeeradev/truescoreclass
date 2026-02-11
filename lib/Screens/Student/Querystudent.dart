import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueryScreen extends StatefulWidget {
  const QueryScreen({super.key});

  @override
  State<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends State<QueryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool isSubmitting = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> submitQuery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login again')),
        );
        setState(() => isSubmitting = false);
        return;
      }

      final uri =
      Uri.parse('https://truescoreedu.com/api/add-help-query');

      /// 🔹 x-www-form-urlencoded POST
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'apiToken': token,
          'subject': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
        },
      );

      print("📨 STATUS CODE: ${response.statusCode}");
      print("📨 RESPONSE: ${response.body}");

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          (json['status'] == 1 || json['status'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json['msg'] ?? 'Query submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json['msg'] ?? 'Failed to submit query'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Raise a Query",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "We’re here to help!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Describe your issue clearly. Our support team will assist you soon.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),

              // Title Field (replaces subject dropdown)
              const Text(
                "Title",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "e.g., Login issue, Payment not reflecting, etc.",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title for your query';
                  }
                  if (value.trim().length < 5) {
                    return 'Title should be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description Field
              const Text(
                "Description",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 7,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Provide detailed information about your issue...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your issue';
                  }
                  if (value.trim().length < 15) {
                    return 'Description should be at least 15 characters';
                  }
                  return null;
                },
              ),
              // const SizedBox(height: 24),
              //
              // // Image Attachment
              // Row(
              //   children: [
              //     const Text(
              //       "Attach Screenshot (Optional)",
              //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              //     ),
              //     const Spacer(),
              //     IconButton(
              //       icon: const Icon(Icons.attach_file, size: 28),
              //       onPressed: _pickImage,
              //       color: Colors.blue,
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 8),
              // if (_selectedImage != null)
              //   Stack(
              //     children: [
              //       ClipRRect(
              //         borderRadius: BorderRadius.circular(16),
              //         child: Image.file(
              //           _selectedImage!,
              //           height: 220,
              //           width: double.infinity,
              //           fit: BoxFit.cover,
              //         ),
              //       ),
              //       Positioned(
              //         top: 8,
              //         right: 8,
              //         child: IconButton(
              //           icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              //           onPressed: () => setState(() => _selectedImage = null),
              //           style: IconButton.styleFrom(backgroundColor: Colors.white),
              //         ),
              //       ),
              //     ],
              //   )
              // else
              //   Container(
              //     height: 120,
              //     decoration: BoxDecoration(
              //       color: Colors.grey[200],
              //       borderRadius: BorderRadius.circular(16),
              //       border: Border.all(color: Colors.grey[300]!, ),
              //     ),
              //     child: const Center(
              //       child: Text(
              //         "Tap the attachment icon to add a screenshot",
              //         style: TextStyle(color: Colors.grey, fontSize: 15),
              //         textAlign: TextAlign.center,
              //       ),
              //     ),
              //   ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitQuery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Submit Query",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}