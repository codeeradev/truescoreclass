// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../../servcies.dart';
//
// class UpdateProfileScreen extends StatefulWidget {
//  // final String? currentName;
//  // final File? currentImage;
//
//   // const UpdateProfileScreen({
//   //   super.key,
//   //   this.currentName,
//   //   this.currentImage,
//   // });
//
//   @override
//   State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
// }
//
// class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController(); // Optional
//
//   File? profileImage;
//   bool isLoading = false;
//   String image='';
//
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     SecureScreen.enable();
//
//     _loadUserData();
//     // if (widget.currentImage != null) {
//     //   profileImage = widget.currentImage;
//     // }
//
//   }
//
//   Future<void> _loadUserData() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       nameController.text =  prefs.getString('studentname') ?? '';
//       phoneController.text = prefs.getString('studentph') ?? '';
//       emailController.text = prefs.getString('studentmail') ?? '';
//       image = prefs.getString('studentimage') ?? '';
//
//     });
//     print('s');
//     print(prefs.getString('studentname'));
//     print(image);
//   }
//
//   Future<void> _pickImage() async {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );
//
//     if (pickedFile != null) {
//       setState(() {
//         profileImage = File(pickedFile.path);
//       });
//       print(profileImage!.path.toString());
//     }
//
//   }
//
//   Future<void> _saveProfile() async {
//     //if (!_formKey.currentState!.validate()) return;
//
//     setState(() => isLoading = true);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//
//       if (token == null || token.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Session expired. Please login again.')),
//         );
//         setState(() => isLoading = false);
//         return;
//       }
//
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('https://truescoreedu.com/api/update-student-profile'),
//       );
//
//       // Add text fields
//       request.fields.addAll({
//         'apiToken': token,
//         'name': nameController.text.trim(),
//         'email': emailController.text.trim(),
//         'contact': phoneController.text.trim(),
//       });
//
//       // Add password only if filled
//       // if (passwordController.text.trim().isNotEmpty) {
//       //   request.fields['password'] = passwordController.text.trim();
//       // }
//
//       // Add image if selected
//       if (profileImage != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath('image', profileImage!.path),
//         );
//       }
//
//       final response = await request.send();
//       final responseData = await response.stream.bytesToString();
//       final jsons = jsonDecode(responseData);
//       final json = jsons['data'];
//
//
//       if (response.statusCode == 200 && jsons['status'] == 1) {
//         print('yes');
//         print(responseData);
//         // Save name locally
//         await prefs.setString('studentname', json["name"].toString());
//         await prefs.setString('studentmail', json["email"].toString());
//         await prefs.setString('studentph', json["contact_no"].toString());
//         //await prefs.setString('profile_image', profileImage!.path);
//
//
//
//
//         // Optionally save image path if you want to show it immediately
//         if (profileImage != null) {
//           await prefs.setString('studentimage',json["image"].toString());
//         }
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(json['msg'] ?? 'Profile updated successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//
//         Navigator.pop(context, true); // Return true to refresh ProfileScreen
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(json['msg'] ?? 'Failed to update profile'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Network error. Please try again.')),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F7FF),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: const Text(
//           "Update Profile",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               // Profile Image Picker
//               GestureDetector(
//                 onTap: _pickImage,
//                 child: Stack(
//                   alignment: Alignment.bottomRight,
//                   children: [
//                     profileImage != null?
//                 CircleAvatar(
//                 radius: 60,
//                   backgroundColor: Colors.grey.shade200,
//                   backgroundImage: profileImage != null
//                       ? FileImage(profileImage!)
//                       : null,
//                   child: profileImage == null
//                       ? const Icon(
//                     Icons.person_rounded,
//                     size: 60,
//                     color: Colors.grey,
//                   )
//                       : null,
//                 ): CircleAvatar(
//                       radius: 60,
//                       backgroundColor: Colors.grey.shade200,
//                       backgroundImage:
//                       image.isNotEmpty ? NetworkImage("https://truescoreedu.com/uploads/students/${image}"): null,
//                       child: image.isEmpty == null
//                           ? const Icon(Icons.person_rounded, size: 60, color: Colors.grey)
//                           : null,
//                     ),
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: const BoxDecoration(
//                         color: Colors.blue,
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//               const Text(
//                 "Tap to change photo",
//                 style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Edit your personal details",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 30),
//
//               // Name
//               _inputField(
//                 controller: nameController,
//                 label: "Full Name",
//                 icon: Icons.person_outline_rounded,
//                 keyboardType: TextInputType.name,
//                 validator: (v) => v!.trim().isEmpty ? "Please enter your name" : null,
//               ),
//
//               // Phone
//               _inputField(
//                 controller: phoneController,
//                 label: "Mobile Number",
//                 icon: Icons.phone_outlined,
//                 keyboardType: TextInputType.phone,
//                 maxLength: 10,
//                 validator: (v) =>
//                 v!.length != 10 ? "Enter a valid 10-digit mobile number" : null,
//               ),
//
//               // Email
//               _inputField(
//                 controller: emailController,
//                 label: "Email Address",
//                 icon: Icons.email_outlined,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (v) =>
//                 !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v!)
//                     ? "Enter a valid email"
//                     : null,
//               ),
//
//               // Optional Password
//               // _inputField(
//               //   controller: passwordController,
//               //   label: "New Password (Optional)",
//               //   icon: Icons.lock_outline,
//               //   keyboardType: TextInputType.visiblePassword,
//               //   isPassword: true,
//               //   validator: null, // Optional field
//               // ),
//
//               const SizedBox(height: 40),
//
//               // Save Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : _saveProfile,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 6,
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                     "Save Changes",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _inputField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     int? maxLength,
//     bool isPassword = false,
//     String? Function(String?)? validator,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLength: maxLength,
//         obscureText: isPassword,
//         validator: validator,
//         decoration: InputDecoration(
//           counterText: "",
//           prefixIcon: Icon(icon, color: Colors.blue),
//           labelText: label,
//           labelStyle: const TextStyle(color: Colors.blue),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(18),
//             borderSide: BorderSide.none,
//           ),
//           filled: true,
//           fillColor: Colors.white,
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     SecureScreen.disable();
//
//     nameController.dispose();
//     phoneController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
// }

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../servcies.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fatherCtr = TextEditingController();
  final TextEditingController houseCtr = TextEditingController();
  final TextEditingController streetCtr = TextEditingController();
  final TextEditingController pinCtr = TextEditingController();

  File? profileImage;
  bool isLoading = false;
  bool isLoadingStates = false;
  String image = '';
  DateTime? selectedDob;
  String? selectedGender;

  List<dynamic> states = [];
  List<dynamic> districts = [];
  List<dynamic> cities = [];
  dynamic selectedState;
  dynamic selectedDistrict;
  dynamic selectedCity;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _loadUserData();
    fetchStates();
  }

  @override
  void dispose() {
    SecureScreen.disable();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    fatherCtr.dispose();
    houseCtr.dispose();
    streetCtr.dispose();
    pinCtr.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final dobString = prefs.getString('studentdob');

    setState(() {
      nameController.text = prefs.getString('studentname') ?? '';
      phoneController.text = prefs.getString('studentph') ?? '';
      emailController.text = prefs.getString('studentmail') ?? '';
      fatherCtr.text = prefs.getString('studentfather') ?? '';
      houseCtr.text = prefs.getString('studenthouse') ?? '';
      streetCtr.text = prefs.getString('studentstreet') ?? '';
      pinCtr.text = prefs.getString('studentpin') ?? '';
      image = prefs.getString('studentimage') ?? '';
      selectedGender = prefs.getString('studentgender');
      selectedDob = (dobString != null && dobString.isNotEmpty)
          ? DateTime.tryParse(dobString)
          : null;
      _savedStateName = prefs.getString('studentstate');
      _savedDistrictName = prefs.getString('studentdistrict');
      _savedCityName = prefs.getString('studentcity');
    });
  }

  String? _savedStateName;
  String? _savedDistrictName;
  String? _savedCityName;

  Future<void> fetchStates() async {
    setState(() => isLoadingStates = true);
    try {
      final response = await http.get(
        Uri.parse('https://truescoreedu.com/api/geo-full'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> stateList = jsonResponse['states'] ?? [];
        setState(() {
          states = stateList;
          isLoadingStates = false;
          if (_savedStateName != null) {
            selectedState = states.firstWhere(
              (s) => s['name'] == _savedStateName,
              orElse: () => null,
            );
            if (selectedState != null) {
              districts = selectedState['districts'] ?? [];
              if (_savedDistrictName != null) {
                selectedDistrict = districts.firstWhere(
                  (d) => d['name'] == _savedDistrictName,
                  orElse: () => null,
                );
                if (selectedDistrict != null) {
                  cities = selectedDistrict['cities'] ?? [];
                  if (_savedCityName != null) {
                    selectedCity = cities.firstWhere(
                      (c) => c['name'] == _savedCityName,
                      orElse: () => null,
                    );
                  }
                }
              }
            }
          }
        });
      } else {
        setState(() => isLoadingStates = false);
        _showSnackBar('Failed to load states', isError: true);
      }
    } catch (e) {
      setState(() => isLoadingStates = false);
      _showSnackBar('Failed to load states', isError: true);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => profileImage = File(pickedFile.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDob = picked);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      // _showSnackBar('Please fix the errors in the form', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showSnackBar('Session expired. Please login again.', isError: true);
        setState(() => isLoading = false);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://truescoreedu.com/api/update-student-profile'),
      );

      request.fields.addAll({
        'apiToken': token,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'contact': phoneController.text.trim(),
        'father_name': fatherCtr.text.trim(),
        'gender': selectedGender ?? '',
        'dob': selectedDob != null
            ? DateFormat('yyyy-MM-dd').format(selectedDob!)
            : '',
        'house_no': houseCtr.text.trim(),
        'street': streetCtr.text.trim(),
        'pincode': pinCtr.text.trim(),
        'state': selectedState != null ? selectedState['name'].toString() : '',
        'district':
            selectedDistrict != null ? selectedDistrict['name'].toString() : '',
        'city': selectedCity != null ? selectedCity['name'].toString() : '',
      });

      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', profileImage!.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResp = jsonDecode(responseBody);
      final data = jsonResp['data'];
log('data---$data');
      if (response.statusCode == 200 && jsonResp['status'] == 1) {
        await prefs.setString('studentname', data['name']?.toString() ?? '');
        await prefs.setString('studentmail', data['email']?.toString() ?? '');
        await prefs.setString(
            'studentph', data['contact_no']?.toString() ?? '');
        await prefs.setString('studentfather', fatherCtr.text.trim());
        await prefs.setString('studentgender', selectedGender ?? '');
        await prefs.setString(
          'studentdob',
          selectedDob != null ? selectedDob!.toIso8601String() : '',
        );
        await prefs.setString('studenthouse', houseCtr.text.trim());
        await prefs.setString('studentstreet', streetCtr.text.trim());
        await prefs.setString('studentpin', pinCtr.text.trim());
        await prefs.setString(
          'studentstate',
          selectedState != null ? selectedState['name'].toString() : '',
        );
        await prefs.setString(
          'studentdistrict',
          selectedDistrict != null ? selectedDistrict['name'].toString() : '',
        );
        await prefs.setString(
          'studentcity',
          selectedCity != null ? selectedCity['name'].toString() : '',
        );

        if (profileImage != null) {
          await prefs.setString(
              'studentimage', data['image']?.toString() ?? '');
        }

        _showSnackBar(jsonResp['msg'] ?? 'Profile updated successfully!');
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar(jsonResp['msg'] ?? 'Failed to update profile',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!) as ImageProvider
                          : (image.isNotEmpty
                              ? NetworkImage(
                                  "https://truescoreedu.com/uploads/students/$image")
                              : null),
                      child: (profileImage == null && image.isEmpty)
                          ? const Icon(Icons.person_rounded,
                              size: 60, color: Colors.grey)
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Tap to change photo",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Edit your personal details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              _inputField(
                controller: nameController,
                label: "Full Name",
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter your name"
                    : null,
              ),
              _inputField(
                controller: phoneController,
                label: "Mobile Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (v) => (v == null || v.length != 10)
                    ? "Enter a valid 10-digit mobile number"
                    : null,
              ),
              _inputField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null ||
                        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v))
                    ? "Enter a valid email"
                    : null,
              ),
              _inputField(
                controller: fatherCtr,
                label: "Father/Husband Name",
                icon: Icons.family_restroom,
                keyboardType: TextInputType.name,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter father/husband name"
                    : null,
              ),
              _buildDropdown<String>(
                value: selectedGender,
                items: const ["Male", "Female"],
                itemBuilder: (g) => g,
                label: "Gender",
                onChanged: (val) => setState(() => selectedGender = val),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: Text(
                    selectedDob == null
                        ? "Select DOB"
                        : DateFormat('dd-MM-yyyy').format(selectedDob!),
                    style: TextStyle(
                      color:
                          selectedDob == null ? Colors.black38 : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _inputField(
                controller: houseCtr,
                label: "House No.",
                icon: Icons.home_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter house no."
                    : null,
              ),
              _inputField(
                controller: streetCtr,
                label: "Street / Village / City",
                icon: Icons.location_on_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Please enter street/village"
                    : null,
              ),
              _inputField(
                controller: pinCtr,
                label: "Pin Code",
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) => (v == null || v.length != 6)
                    ? "Enter a valid 6-digit pin code"
                    : null,
              ),
              isLoadingStates
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                          backgroundColor: Colors.white24),
                    )
                  : _buildDropdown(
                      value: selectedState,
                      items: states,
                      itemBuilder: (s) => s['name'].toString(),
                      label: "Select State",
                      onChanged: (state) => setState(() {
                        selectedState = state;
                        selectedDistrict = null;
                        selectedCity = null;
                        districts = state['districts'] ?? [];
                        cities = [];
                      }),
                    ),
              const SizedBox(height: 18),
              _buildDropdown(
                value: selectedDistrict,
                items: districts,
                itemBuilder: (d) => d['name'].toString(),
                label: "Select District",
                onChanged: districts.isEmpty
                    ? null
                    : (district) => setState(() {
                          selectedDistrict = district;
                          selectedCity = null;
                          cities = district['cities'] ?? [];
                        }),
              ),
              const SizedBox(height: 18),
              _buildDropdown(
                value: selectedCity,
                items: cities,
                itemBuilder: (c) => c['name'].toString(),
                label: "Select City / Tehsil",
                onChanged: cities.isEmpty
                    ? null
                    : (city) => setState(() => selectedCity = city),
              ),
              const SizedBox(height: 30),
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

  Widget _buildDropdown<T>({
    required T? value,
    required List items,
    required String label,
    required String Function(dynamic) itemBuilder,
    required void Function(dynamic)? onChanged,
  }) {
    return Container(
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
      child: DropdownButtonFormField<dynamic>(
        value: value,
        isExpanded: true,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map<DropdownMenuItem<dynamic>>((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(itemBuilder(item)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Required" : null,
      ),
    );
  }
}
