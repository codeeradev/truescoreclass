import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:online_classes/Screens/Auth/asktype.dart';
import 'package:online_classes/Screens/Auth/signinScreen.dart';

class RegistrationSuccessCard extends StatelessWidget {
  final String message;
  final String enrollmentId;
  final String password;

  const RegistrationSuccessCard({
    super.key,
    required this.message,
    required this.enrollmentId,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ✅ SUCCESS HEADER
          Row(
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Registration Successful",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            "Carefully Save these for login",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          /// 🔐 ENROLLMENT ID
          _infoRow(
            context,
            label: "Enrollment ID",
            value: enrollmentId,
          ),

          const SizedBox(height: 12),

          /// 🔑 PASSWORD
          _infoRow(
            context,
            label: "Password",
            value: password,
            isSensitive: false,
          ),
          const SizedBox(height: 42),
          InkWell(onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>SigninScreen()));
          },
            child: Container(height: 55,width: double.maxFinite,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),color: Colors.blue),
            child: Center(
              child: Text("Finish",style: TextStyle(color: Colors.white),),

            ),),
          )

        ],
      ),
    );
  }

  /// 🔹 Row with Copy Button
  Widget _infoRow(
      BuildContext context, {
        required String label,
        required String value,
        bool isSensitive = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSensitive ? "••••••••" : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          /// 📋 COPY BUTTON
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.blue),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$label copied to clipboard"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
