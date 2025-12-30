// lib/Screens/CourseDetailScreen.dart (or your file name)

import 'package:flutter/material.dart';
import 'package:online_classes/Screens/Student/videos.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CourseDetailScreen2 extends StatefulWidget {
  final Map<String, dynamic> courseData; // Changed to Map<String, dynamic> for safety

  const CourseDetailScreen2({super.key, required this.courseData});

  @override
  State<CourseDetailScreen2> createState() => _CourseDetailScreen2State();
}

class _CourseDetailScreen2State extends State<CourseDetailScreen2> {
  Future Assignbatch(String mode,String batchid,String price) async {
    SharedPreferences preferences =await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    print(token);
    final response = await http.post(
      Uri.parse("https://testora.codeeratech.in/api/assign-batch"),
      body: {
        "apiToken": token.toString(),
        "batch_id": batchid.toString(),
        "pay_mode":mode.toString(),
        "price":price
      },
    );

    final data = jsonDecode(response.body);
    print(data);
    // setState(() {
    //   apiData = data["data"];
    //   loading = false;
    // });
  }


  late Razorpay _razorpay;
  void startPayment(double total,) {
    var options = {
      'key': 'rzp_test_RTEcMq4cjicldH',
      'amount': total*100,
      'name': 'Testora Student Courses',
      'description': 'Buy Courses',
      //'order_id': orders,
      'prefill': {
        'contact': '9123456789',
        'email': 'example@domain.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Videos()));
   // addtips('tip');



    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    );
  }

  Future<void> _handlePaymentError(PaymentFailureResponse response) async {



    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );

  }

  Future<void> _handleExternalWallet(ExternalWalletResponse response) async {


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  Widget build(BuildContext context) {
    print(widget.courseData);
    final String id=widget.courseData["id"] ?? "";
    // Safely extract data with fallbacks
    final String batchName = widget.courseData["batch_name"] ?? "Untitled Course";
    final String category = widget.courseData["cat_name"] ?? "";
    final String subCategory = widget.courseData["sub_cat_name"] ?? "";
    final String description = (widget.courseData["description"] ?? "")
        .toString()
        .trim()
        .replaceAll("null", "");

    final String imageUrl = (widget.courseData["batch_image"] ?? "").toString().trim();

    // Prices - always treat as String, handle empty cases
    final String rawPrice = (widget.courseData["batch_price"] ?? "").toString().trim();
    final String rawOfferPrice = (widget.courseData["batch_offer_price"] ?? "").toString().trim();

    final String price = rawPrice.isEmpty ? "Free" : "₹$rawPrice";
    final String offerPrice = rawOfferPrice.isEmpty ? rawPrice : rawOfferPrice;

    // Parse for comparison only (offer logic)
    final double parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    final double parsedOfferPrice = double.tryParse(rawOfferPrice) ?? parsedPrice;

    final bool hasOffer = rawOfferPrice.isNotEmpty && parsedOfferPrice < parsedPrice && parsedOfferPrice > 0;

    final String startDate = widget.courseData["start_date"] ?? "Not specified";
    final String endDate = widget.courseData["end_date"] ?? "Not specified";

    // Time handling with safety checks
    final String rawStartTime = (widget.courseData["start_time"] ?? "").toString();
    final String rawEndTime = (widget.courseData["end_time"] ?? "").toString();

    final String startTime = rawStartTime.length >= 8 ? rawStartTime.substring(0, 5) : "";
    final String endTime = rawEndTime.length >= 8 ? rawEndTime.substring(0, 5) : "";

    final String payMode = widget.courseData["pay_mode"] ?? "Online";

    // Students count
    final String rawStudents = (widget.courseData["no_of_student"] ?? "0").toString();
    final String noOfStudents = rawStudents == "0" ? "No" : rawStudents;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text(
          "Course Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage("https://testora.codeeratech.in/uploads/batch_image/${imageUrl}"),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: Colors.blue,
              )
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batchName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$category ${subCategory.isNotEmpty ? '• $subCategory' : ''}",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // Price Section - now handles empty prices gracefully
                  Row(
                    children: [
                      if (rawPrice.isEmpty)
                        const Text(
                          "Free Course",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )
                      else if (hasOffer) ...[
                        Text(
                          "₹$rawPrice",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "₹$offerPrice",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ] else
                        Text(
                          "₹$rawPrice",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),

                      const Spacer(),
                      Chip(
                        backgroundColor: Colors.blue.shade50,
                        label: Text(
                          payMode,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty ? "No description available for this course." : description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow(Icons.calendar_today, "Start Date", startDate),
                  _buildDetailRow(Icons.calendar_month, "End Date", endDate),
                  if (startTime.isNotEmpty && endTime.isNotEmpty)
                    _buildDetailRow(Icons.access_time, "Time", "$startTime - $endTime"),
                  _buildDetailRow(Icons.groups, "Enrolled Students", "10000+ students"),

                  const SizedBox(height: 40),

                  SizedBox(

                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton(

                      onPressed:  () async {

                        if(rawPrice.isEmpty){

                         await Assignbatch('offline', id.toString(),"00");

                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Videos()));


                        }else{

                          double? d = double.tryParse(rawOfferPrice.toString());
                          startPayment(d!);
                          await Assignbatch('offline', id.toString(),d.toString());


                        }

                       // Navigator.push(context, MaterialPageRoute(builder: (context)=>Videos()));
                       //  ScaffoldMessenger.of(context).showSnackBar(
                       //    const SnackBar(content: Text("Enrollment done !")),
                       //  );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        rawPrice.isEmpty ? "Join Free" : "Buy Now",
                        style: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}