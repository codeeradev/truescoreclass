import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateProfileScreen extends StatefulWidget {
 // final String? currentName;
 // final File? currentImage;

  // const UpdateProfileScreen({
  //   super.key,
  //   this.currentName,
  //   this.currentImage,
  // });

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(); // Optional

  File? profileImage;
  bool isLoading = false;
  String image='';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // if (widget.currentImage != null) {
    //   profileImage = widget.currentImage;
    // }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text =  prefs.getString('studentname') ?? '';
      phoneController.text = prefs.getString('number') ?? '';
      emailController.text = prefs.getString('email') ?? '';
      image = prefs.getString('profileimage') ?? '';

    });
    print('s');
    print(prefs.getString('studentname'));
    print(image);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    //if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        setState(() => isLoading = false);
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://testora.codeeratech.in/api/update-student-profile'),
      );

      // Add text fields
      request.fields.addAll({
        'apiToken': token,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'contact': phoneController.text.trim(),
      });

      // Add password only if filled
      if (passwordController.text.trim().isNotEmpty) {
        request.fields['password'] = passwordController.text.trim();
      }

      // Add image if selected
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', profileImage!.path),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsons = jsonDecode(responseData);
      final json = jsons['data'];


      if (response.statusCode == 200 && jsons['status'] == 1) {
        print('yes');
        print(responseData);
        // Save name locally
        await prefs.setString('studentname', json["name"].toString());
        await prefs.setString('email', json["email"].toString());
        await prefs.setString('number', json["contact_no"].toString());
        //await prefs.setString('profile_image', profileImage!.path);




        // Optionally save image path if you want to show it immediately
        if (profileImage != null) {
          await prefs.setString('profileimage',json["image"].toString());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json['msg'] ?? 'Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Return true to refresh ProfileScreen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json['msg'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Update Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      image.isNotEmpty ? NetworkImage("https://testora.codeeratech.in/uploads/students/${image}"): null,
                      child: image.isEmpty == null
                          ? const Icon(Icons.person_rounded, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Tap to change photo",
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              const Text(
                "Edit your personal details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),

              // Name
              _inputField(
                controller: nameController,
                label: "Full Name",
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: (v) => v!.trim().isEmpty ? "Please enter your name" : null,
              ),

              // Phone
              _inputField(
                controller: phoneController,
                label: "Mobile Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) =>
                v!.length != 10 ? "Enter a valid 10-digit mobile number" : null,
              ),

              // Email
              _inputField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)
                    ? "Enter a valid email"
                    : null,
              ),

              // Optional Password
              // _inputField(
              //   controller: passwordController,
              //   label: "New Password (Optional)",
              //   icon: Icons.lock_outline,
              //   keyboardType: TextInputType.visiblePassword,
              //   isPassword: true,
              //   validator: null, // Optional field
              // ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          counterText: "",
          prefixIcon: Icon(icon, color: Colors.blue),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}