import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'CardSave.dart'; // For date formatting

class SelfRegistrationScreen1 extends StatefulWidget {


  @override
  State<SelfRegistrationScreen1> createState() => _SelfRegistrationScreen1State();
}

class _SelfRegistrationScreen1State extends State<SelfRegistrationScreen1>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String registerAs = "Teacher";

  // New: DOB & Subjects
  DateTime? selectedDob;
  List<dynamic> subjects = [];
  List<dynamic> selectedSubjects = []; // Holds selected subject objects
  bool isLoadingSubjects = false;

  File? profilePhoto;
  File? addressFront;
  File? addressBack;
  final picker = ImagePicker();

  // Controllers
  final nameCtr = TextEditingController();
  final fatherCtr = TextEditingController();
  final houseCtr = TextEditingController();
  final streetCtr = TextEditingController();
  final pinCtr = TextEditingController();
  final mobileCtr = TextEditingController();
  final emailCtr = TextEditingController();
  final passwordCtr = TextEditingController();
  List roles = [];          // full list
  String? selectedRoleId;   // stores id for API
  String? selectedRoleName; // for dropdown UI


  // Geo Data
  List<dynamic> states = [];
  List<dynamic> districts = [];
  List<dynamic> cities = [];
  dynamic selectedState;
  dynamic selectedDistrict;
  dynamic selectedCity;

  bool isLoadingStates = true;
  bool isSubmitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Future<void> pickImage(Function(File) onSelect) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      onSelect(File(picked.path));
      setState(() {});
    }
  }
  String stu="";


  @override
  void initState() {
    super.initState();
    getlist();
    fetchStates();
    fetchSubjects(); // Load subjects
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  void showSuccessPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(blurRadius: 12, color: Colors.black26, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 55),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Fetch States (unchanged)
  Future<void> fetchStates() async {
    try {
      final response = await http.get(Uri.parse('https://testora.codeeratech.in/api/geo-full'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> stateList = jsonResponse['states'] ?? [];
        setState(() {
          states = stateList;
          isLoadingStates = false;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load states', isError: true);
    }
  }

  // NEW: Fetch Subjects
  Future<void> fetchSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      final response = await http.get(Uri.parse('https://testora.codeeratech.in/api/get-subjects'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          subjects = json['data'] ?? [];
          isLoadingSubjects = false;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to load subjects', isError: true);
    } finally {
      setState(() => isLoadingSubjects = false);
    }
  }

  // DOB Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  getlist() async {
    final response = await http.get(
      Uri.parse('https://testora.codeeratech.in/api/get-roles'),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    );

    final data = jsonDecode(response.body);

    if (data['status'] == 1) {
      setState(() {
        roles = data['data']; // <-- save full list
      });
    }
  }

  // Updated Submit Form with DOB & Subjects
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // if (registerAs == "Teacher" && selectedSubjects.isEmpty) {
    //   _showSnackBar("Please select at least one subject", isError: true);
    //   return;
    // }

    if (selectedDob == null) {
      _showSnackBar("Please select Date of Birth", isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');

    try {
      // ============================
      // Building x-www-form-urlencoded body manually
      // ============================
      String body = "";

      body += "registerAs=4&";
      body += "name=${Uri.encodeQueryComponent(nameCtr.text.trim())}&";
      body += "father_name=${Uri.encodeQueryComponent(fatherCtr.text.trim())}&";
      body += "state=${selectedState['id']}&";
      body += "district=${selectedDistrict['id']}&";
      body += "city=${selectedCity['id']}&";
      body += "phone=${Uri.encodeQueryComponent(mobileCtr.text.trim())}&";
      body += "address=${Uri.encodeQueryComponent(houseCtr.text.trim())}&";

      body += "email=${Uri.encodeQueryComponent(emailCtr.text.trim())}&";
      body += "password=${Uri.encodeQueryComponent(passwordCtr.text)}&";
      body += "apiToken=${stu}&";
      body += "dob=${Uri.encodeQueryComponent(DateFormat('d-M-yyyy').format(selectedDob!))}";

      // if (widget.scan==true) {
      //   body += "apiToken=${widget.userid}&";
      // }else{
      //   body += "apiToken=$token&";
      //
      //
      // }

      // ============================
      // Append subjects EXACTLY as subject[]=4&subject[]=2
      // ============================
      if (registerAs == "Teacher") {
        for (var s in selectedSubjects) {
          body += "&subject[]=${s['id'].toString()}";
        }
      }

      print("📤 FINAL BODY SENT → $body");

      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/register-user'),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      print("📨 RESPONSE: ${response.body}");
      print(response.statusCode);
      var jsonData = jsonDecode(response.body);



      if (response.statusCode == 200) {
        print('true');

        final jsonData = jsonDecode(response.body);

        // ✅ optional: check API status also
        if (jsonData['status'] == 1) {

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: RegistrationSuccessCard(
                message: jsonData['msg'], // ✅ FIXED KEY
                enrollmentId: jsonData['enrollment_id'].toString(),
                password: jsonData['password'].toString(),
              ),
            ),
          );

        } else {
          _showSnackBar(
            jsonData['msg'] ?? "Registration failed",
            isError: true,
          );
        }
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar(
          error['msg'] ?? "Registration failed",
          isError: true,
        );
      }

    } catch (e) {
      _showSnackBar("Network error: $e", isError: true);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      profilePhoto = addressFront = addressBack = null;
      selectedState = selectedDistrict = selectedCity = null;
      selectedDob = null;
      selectedSubjects.clear();
      districts.clear();
      cities.clear();
    });
    nameCtr.clear();
    fatherCtr.clear();
    mobileCtr.clear();
    emailCtr.clear();
    passwordCtr.clear();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = registerAs == "Teacher";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Register New User", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration:  BoxDecoration(
           color: Colors.blue.shade200
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
         color: Colors.white
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header Card (unchanged)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.person_add_alt_1, size: 60, color: Colors.black),
                        SizedBox(height: 12),
                        Text("Register as New Student", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                        //Text("Fill in the details to onboard a new member", style: TextStyle(fontSize: 15, color: Colors.black)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade200,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // _buildGlassDropdown1(
                          //   value: selectedRoleId, // stores ID only
                          //   items: roles,          // directly pass API list [{"id":"3","role_name":"Teacher"}]
                          //   label: "Register As",
                          //   onChanged: (val) {
                          //     setState(() {
                          //       selectedRoleId = val; // 👈 saves id properly
                          //     });
                          //
                          //     print("Selected Role ID: $selectedRoleId");
                          //   },
                          // ),


                          const SizedBox(height: 20),

                          // DOB Picker
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "Date of Birth",
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 2)),
                                prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                              ),
                              child: Text(
                                selectedDob == null
                                    ? "Select DOB"
                                    : DateFormat('dd-MM-yyyy').format(selectedDob!),
                                style: TextStyle(color: selectedDob == null ? Colors.white54 : Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Multi-Select Subjects (Only for Teacher)
                          if (selectedRoleId=="3") ...[
                            isLoadingSubjects
                                ? const LinearProgressIndicator(backgroundColor: Colors.white24)
                                :
                            DropdownButtonFormField<dynamic>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: "Select Subjects (Hold to select multiple)",
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 2)),
                              ),
                              dropdownColor: Colors.black87,
                              value: null,
                              items: subjects.map((sub) {
                                bool isSelected = selectedSubjects.any((s) => s['id'] == sub['id']);
                                return DropdownMenuItem(
                                  value: sub,
                                  child: StatefulBuilder(
                                    builder: (context, setStateItem) {
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedSubjects.removeWhere((s) => s['id'] == sub['id']);
                                            } else {
                                              selectedSubjects.add(sub);
                                            }
                                          });
                                          setStateItem(() {});
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                              color: isSelected ? Colors.green : Colors.white70,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(sub['subject_name'], style: const TextStyle(color: Colors.white)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                              onChanged: (_) {}, // Required but we handle manually
                              hint: Text(
                                selectedSubjects.isEmpty
                                    ? "Choose subjects"
                                    : "${selectedSubjects.length} subject(s) selected",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          isLoadingStates
                              ? const LinearProgressIndicator(backgroundColor: Colors.white24)
                              : _buildGlassDropdown(
                            value: selectedState,
                            items: states,
                            itemBuilder: (s) => s['name'],
                            onChanged: (state) => setState(() {
                              selectedState = state;
                              selectedDistrict = null;
                              selectedCity = null;
                              districts = state['districts'] ?? [];
                              cities = [];
                            }),
                            label: "Select State",
                          ),
                          const SizedBox(height: 15),
                          _buildGlassDropdown(
                            value: selectedDistrict,
                            items: districts,
                            itemBuilder: (d) => d['name'],
                            onChanged: districts.isEmpty ? null : (district) => setState(() {
                              selectedDistrict = district;
                              selectedCity = null;
                              cities = district['cities'] ?? [];
                            }),
                            label: "Select District",
                          ),
                          const SizedBox(height: 15),
                          _buildGlassDropdown(
                            value: selectedCity,
                            items: cities,
                            itemBuilder: (c) => c['name'],
                            onChanged: cities.isEmpty ? null : (city) => setState(() => selectedCity = city),
                            label: "Select City / Tehsil",
                          ),
                          const SizedBox(height: 25),

                          // Rest of your fields (unchanged)
                          _buildTextField(nameCtr, "Full Name", Icons.person),
                          _buildTextField(fatherCtr, "Father/Husband Name", Icons.family_restroom),
                          _buildTextField(houseCtr, "House No.", Icons.home),
                          _buildTextField(streetCtr, "Street / Village / City", Icons.location_on),
                          _buildTextField(pinCtr, "Pin Code", Icons.pin, keyboardType: TextInputType.number),
                          const SizedBox(height: 25),
                          const Text("Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 15),



                          _buildTextField(mobileCtr, "Mobile Number", Icons.phone, keyboardType: TextInputType.phone),
                          _buildTextField(emailCtr, "Email Address", Icons.email, keyboardType: TextInputType.emailAddress),
                          _buildTextField(passwordCtr, "Password", Icons.lock, obscure: true),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF667eea),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 10,
                              ),
                              child: isSubmitting
                                  ? const CircularProgressIndicator(color: Color(0xFF667eea))
                                  : const Text("Register Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        validator: (v) => v!.trim().isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildGlassDropdown({
    dynamic value,
    required List items,
    required String label,
    String Function(dynamic)? itemBuilder,
    void Function(dynamic)? onChanged,
  }) {
    return DropdownButtonFormField<dynamic>(
      value: value,
      dropdownColor: Colors.black.withOpacity(0.6),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 2)),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(itemBuilder?.call(item) ?? item.toString()));
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Required" : null,
    );
  }

  Widget _buildGlassDropdown1({
    dynamic value,
    required List items, // expects list of maps from API
    required String label,
    void Function(dynamic)? onChanged,
  }) {
    return DropdownButtonFormField(
      value: value,
      dropdownColor: Colors.black.withOpacity(0.65),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),

      // 👇 Now items are map: {id: '3', role_name: 'Teacher'}
      items: items.map((role) {
        return DropdownMenuItem(
          value: role['id'], // user selects ID internally
          child: Text(role['role_name'], style: const TextStyle(color: Colors.white)),
        );
      }).toList(),

      onChanged: onChanged,
      validator: (v) => v == null ? "Required" : null,
    );
  }


  Widget _buildPhotoPicker(String label, File? file, Function(File) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => pickImage(onPick),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: file == null
                ? const Center(child: Icon(Icons.add_a_photo, color: Colors.white70, size: 36))
                : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(file, fit: BoxFit.cover)),
          ),
        ),
      ],
    );
  }


}