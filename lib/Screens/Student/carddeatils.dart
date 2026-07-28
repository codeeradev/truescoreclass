import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:online_classes/Screens/Student/Bottombar.dart';
import 'package:online_classes/Screens/Student/percentage.dart';
import 'package:online_classes/Screens/Student/videos.dart';
import 'package:online_classes/Screens/Student/webview.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../servcies.dart';
import '../../videofull.dart';
import '../Youtubeplayer.dart';
import 'getnotes.dart';
import 'newques.dart'; // Your YouTube player (VideoPlayerScreen)

class CourseDetailScreen2 extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const CourseDetailScreen2({super.key, required this.courseData});

  @override
  State<CourseDetailScreen2> createState() => _CourseDetailScreen2State();
}

class _CourseDetailScreen2State extends State<CourseDetailScreen2>
    with TickerProviderStateMixin {
  String environment = "SANDBOX";
  String merchantId = "MERCHNATID";
  String flowId = "test";

  bool enableLogs = true;

  String appSchema = "test";
  String orderid = '';
  String tokenid = '';

  late Map<String, dynamic> payload = {
    "orderId": orderid.toString(),
    "merchantId": "MERCHNATID",
    "token": tokenid.toString(),
    "paymentMode": {"type": "PAY_PAGE"}
  };

  late final String request = jsonEncode(payload);

  Future<Map<String, dynamic>> getPhonePeAccessToken({
    required String clientId,
    required String clientSecret,
  }) async {
    final uri = Uri.https(
      'api-preprod.phonepe.com',
      '/apis/pg-sandbox/v1/oauth/token',
    );

    final request = http.Request('POST', uri);

    request.headers.addAll({
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    });

    /// 🔴 IMPORTANT: bodyFields (NOT body)
    request.bodyFields = {
      'client_version': '1',
      'grant_type': 'client_credentials',
      'client_id': clientId,
      'client_secret': clientSecret,
    };

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception(
        'Failed to get PhonePe token (${response.statusCode}): $responseBody',
      );
    }
  }

  createPhonePeOrder({
    required String authToken,
    required String merchantOrderId,
    required int amount, // in paise
  }) async {
    final url = Uri.parse(
      'https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/sdk/order',
    );

    final body = {
      "merchantOrderId": merchantOrderId,
      "amount": amount,
      "expireAfter": 1200,
      "metaInfo": {
        "udf1": "additional-information-1",
        "udf2": "additional-information-2",
        "udf3": "additional-information-3",
        "udf4": "additional-information-4",
        "udf5": "additional-information-5",
        "udf6": "additional-information-6",
        "udf7": "additional-information-7",
        "udf8": "additional-information-8",
        "udf9": "additional-information-9",
        "udf10": "additional-information-10",
        "udf11": "additional-information-11",
        "udf12": "additional-information-12",
        "udf13": "additional-information-13",
        "udf14": "additional-information-14",
        "udf15": "additional-information-15",
      },
      "paymentFlow": {"type": "PG_CHECKOUT"}
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": authToken, // 👈 IMPORTANT
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() {
        orderid = data["orderId"];
        tokenid = data["token"];
      });
      print(orderid);
      startTransaction();
    } else {
      throw Exception(
        "PhonePe order failed (${response.statusCode}): ${response.body}",
      );
    }
  }

  void initSdk() {
    PhonePePaymentSdk.init(environment, merchantId, flowId, enableLogs)
        .then((isInitialized) => {print("initialized : $isInitialized")})
        .catchError((onError) {
      print("onError : $onError");
      return <dynamic>{};
    });
  }

  void startTransaction() {
    PhonePePaymentSdk.startTransaction(request, appSchema).then((response) {
      if (response != null) {
        String status = response['status'].toString();
        String error = response['error'].toString();
        if (status == 'SUCCESS') {
          print("success");
        } else {
          print("failed");
        }
      } else {
        print("Flow incomplete");
      }
    });
  }

  bool isLoading = true;
  bool isPurchased = false;
  bool isTrialOver = false;
  bool isTrial = false;
  String trialDays = '';
  String isTrialAvailable = '0';
  Map<String, dynamic>? apiCourseData;

  List<dynamic> videoLectures = [];
  List<dynamic> allQuestions = [];

  Widget testoraBannerCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Videos(
                      id: widget.courseData["id"].toString(),
                    )));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB), // deep blue
              Color(0xFF3B82F6), // light blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            /// 🔵 Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: _decorCircle(120, Colors.white.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: _decorCircle(100, Colors.white.withOpacity(0.08)),
            ),

            /// CONTENT
            Row(
              children: [
                /// ICON CONTAINER
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.question_answer,
                    size: 30,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 16),

                /// TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Exams",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                /// RIGHT DECOR ICON
                const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // For questions tabs
  late TabController _tabController;
  List<String> availableTabs = [];

  Map<String, List<dynamic>> questionsByType = {
    "MCQ": [],
    "Current Affairs": [],
    "PYQ": [],
  };

  double prices = 0;
  String Id = '';
  late Razorpay _razorpay;
  final couponController = TextEditingController();

  bool couponApplied = false;

  double originalAmount = 0;
  String? couponId;
  double discountPercent = 0;
  double discountAmount = 0;
  double finalAmount = 0;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchNotes();
    checkPurchaseStatus();
  }

  Future<void> checkPurchaseStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final String courseId = widget.courseData["id"]?.toString() ?? "";
    print(token);
    print('courseId----$courseId');

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-batche-details"),
        body: {
          "apiToken": token.toString(),
          "courseId": courseId,
        },
      );
      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }
      final data = jsonDecode(response.body);
      log("--statusCode-${response.statusCode}---Purchase check API response: $data");
      if (data["status"].toString() == "true") {
        setState(() {
          isPurchased = data["data"]["isPurchased"];
          isTrialOver = data["data"]["isTrialOver"];
          isTrial = data["data"]["isTrial"];
          trialDays = data["data"]['course']["trial_days"].toString();
          isTrialAvailable =
              data["data"]['course']["is_trial_available"].toString();
          apiCourseData = data["data"]["course"];
          videoLectures = data["data"]["videoLectures"] ?? [];
          allQuestions = data["data"]["questions"] ?? [];

          // Group questions by type
          questionsByType = {"MCQ": [], "Current Affairs": [], "PYQ": []};
          availableTabs.clear();

          for (var q in allQuestions) {
            String type = q["question_type"]?.toString() ?? "1";
            String tabName;
            List<dynamic> targetList;

            if (type == "1") {
              tabName = "MCQ";
              targetList = questionsByType["MCQ"]!;
            } else if (type == "2") {
              tabName = "Current Affairs";
              targetList = questionsByType["Current Affairs"]!;
            } else if (type == "3") {
              tabName = "PYQ";
              targetList = questionsByType["PYQ"]!;
            } else {
              continue;
            }

            targetList.add(q);
            if (!availableTabs.contains(tabName)) availableTabs.add(tabName);
          }

          // Sort tabs
          availableTabs.sort((a, b) {
            List<String> order = ["MCQ", "Current Affairs", "PYQ"];
            return order.indexOf(a).compareTo(order.indexOf(b));
          });

          _tabController =
              TabController(length: availableTabs.length, vsync: this);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error checking purchase: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isLoadingCoupon = false;

  Future applyCouponApi() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final String courseId = widget.courseData["id"]?.toString() ?? "";
    setState(() {
      isLoadingCoupon = true;
    });
    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/apply-coupon"),
        body: {
          "apiToken": token.toString(),
          "batch_id": courseId,
          "coupon_code": couponController.text.trim(),
        },
      );
      log("applyCoupon-statusCode--${response.statusCode}");
      log("applyCouponAp-body--${response.body}");
      if (response.body.trim().isEmpty) {
        throw Exception("Empty response");
      }

      final data = jsonDecode(response.body);

      if (data["status"].toString() == "1" ||
          data["status"].toString() == "true") {
        final result = data["data"];
        Fluttertoast.showToast(
            msg: data["msg"],
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            textColor: Colors.green);
        return result;
      } else {
        Fluttertoast.showToast(
            msg: data["msg"],
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP,
            textColor: Colors.red);
        return null;
      }
    } catch (e) {
      debugPrint(e.toString());
      return null;
    } finally {
      if (mounted) {
        setState(() {
          isLoadingCoupon = false;
        });
      }
    }
  }

  @override
  void dispose() {
    SecureScreen.disable();
    if (availableTabs.isNotEmpty) _tabController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  String orderids = '';
  String mecrhant = '';

  Future<void> addPhonePay(
      {required BuildContext context,
      required String batchId,
      required bool isTrial}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print(token);
    print(batchId);
    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/payment/initiate"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "apiToken": token.toString(),
          "batch_id": batchId.toString(),
          "purchase_type": isTrial ? '1' : '2',
          if (couponId != null) "coupon_id": couponId.toString(),
        },
      );
      dynamic data;

      String body = response.body.trim();

      // Handle invalid response containing multiple JSON objects
      if (body.contains("}{")) {
        final firstPart = body.substring(0, body.indexOf("}{") + 1);
        data = jsonDecode(firstPart);
      } else {
        data = jsonDecode(body);
      }
      print('addPhonePay---$data');
      print('statusCode---${response.statusCode}');

      if (response.statusCode == 200 && data['status'] == 1) {
        if (!isTrial) {
          final redirectUrl = data['data']['redirect_url'];
          final transactionId = data['data']['transaction_id'];
          final orderId = data['data']['order_id'];
          final type = data['data']['gateway'];
          final key = data['data']['key'];
          final amt = data['data']['amount'];
          setState(() {
            orderids = orderId.toString();
            mecrhant = transactionId.toString();
          });

          double d = double.parse(amt.toString());
          startPayment(d, orderId.toString(), key.toString());

          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => PhonePeWebViewScreen(
          //       redirectUrl: redirectUrl,
          //       transactionId: transactionId,
          //       orderId: orderId,
          //       apiToken: token!,
          //       gateway: type.toString(),
          //     ),
          //   ),
          // ).then((s){
          //   checkPurchaseStatus();
          //
          //
          // });
        } else {
          if (data['trial_assingd'] == false) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(data['message']), backgroundColor: Colors.red),
            );
          } else {
            checkPurchaseStatus();

            showDialog(
              context: context,
              barrierDismissible: false, // Prevent closing by tapping outside
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 30,
                    ),
                    SizedBox(width: 8),
                    Text("Success"),
                  ],
                ),
                content: Text(
                  data['message'] ??
                      'Free course payment recorded successfully.',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Something went wrong'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('error---$e');
    }
  }

  Widget htmlTextViewer(String htmlData) {
    return Html(
      data: htmlData.isEmpty ? "<p>No content</p>" : htmlData,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(14),
          color: Colors.black87,
          lineHeight: LineHeight.number(1.5),
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
        ),
        "b": Style(fontWeight: FontWeight.bold),
        "strong": Style(fontWeight: FontWeight.bold),
        "h1": Style(fontSize: FontSize(22)),
        "h2": Style(fontSize: FontSize(20)),
        "h3": Style(fontSize: FontSize(18)),
        "ul": Style(margin: Margins.only(left: 16)),
        "ol": Style(margin: Margins.only(left: 16)),
        "a": Style(
          color: Colors.blue,
          textDecoration: TextDecoration.underline,
        ),
      },
    );
  }

  Future Assignbatch(
      String mode, String batchid, String price, String trans) async {
    print('s');

    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final response = await http.post(
      Uri.parse("https://truescoreedu.com/api/assign-batch"),
      body: {
        "apiToken": token.toString(),
        "batch_id": batchid,
        "pay_mode": mode,
        "price": price,
        "transid": trans,
      },
    );

    if (response.statusCode == 200) {
      print('yes');
      final data = jsonDecode(response.body);
      print(data);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const CoursePurchasedDialog(),
      );

      checkPurchaseStatus();
    }
  }

  bool isLoading2 = true;
  List<dynamic> notes = [];
  String? errorMessage;

  Future<void> fetchNotes() async {
    setState(() {
      isLoading2 = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        errorMessage = "Please login again";
        isLoading2 = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-notes"),
        body: {
          "apiToken": token,
          "course_id": widget.courseData["id"].toString()
        },
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 1) {
          setState(() {
            notes = json['notes'] ?? [];
            isLoading2 = false;
          });
        } else {
          setState(() {
            errorMessage = json['message'] ?? "No notes found";
            isLoading2 = false;
          });
        }
      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load notes. Check your connection.";
        isLoading2 = false;
      });
    }
  }

  void startPayment(double total, String orderid, String Key) {
    var options = {
      'key': Key,
      'amount': total * 100,
      'order_id': orderid.toString(),
      'name': 'Truescore Student Courses',
      'description': 'Buy Courses',
      'prefill': {'contact': '9123456789', 'email': 'example@domain.com'},
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // Future<void> _verifyPayment(
  //     String
  //     signature
  //     )
  // async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //   final response = await http.post(
  //     Uri.parse("https://truescoreedu.com/api/payment/verify"),
  //     headers: {
  //       "Accept": "application/json",
  //       "Content-Type": "application/x-www-form-urlencoded",
  //     },
  //     body: {
  //       "merchantOrderId": mecrhant,
  //       "orderid": orderids,
  //       "apiToken": token.toString(),
  //       "gateway":"RAZORPAY",
  //       "signature":signature.toString(),
  //       "paymentStatus":"paid",
  //
  //
  //     },
  //   );
  //   print('datais${response.body}');
  //   checkPurchaseStatus();
  //
  //  // Navigator.pop(context);
  //   // close loader
  //
  //
  //   final data = jsonDecode(response.body);
  //   print("_verifyPayment--$data");
  //   //showPaymentResultPopup(context, data);
  //
  //   // showDialog(
  //   //   context: context,
  //   //   builder: (_) => AlertDialog(
  //   //     title: Text(data['status'] == 1
  //   //         ? "Payment Successful"
  //   //         : "Payment Failed"),
  //   //     content: Text(data['message'] ?? ""),
  //   //     actions: [
  //   //       TextButton(
  //   //         onPressed: () {
  //   //           Navigator.pop(context);
  //   //           Navigator.pop(context); // back to previous screen
  //   //         },
  //   //         child: const Text("OK"),
  //   //       ),
  //   //     ],
  //   //   ),
  //   // );
  // }

  Future<void> _verifyPayment(String signature) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse("https://truescoreedu.com/api/payment/verify"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "merchantOrderId": mecrhant,
        "orderid": orderids,
        "apiToken": token.toString(),
        "gateway": "RAZORPAY",
        "signature": signature,
        "paymentStatus": "paid",
      },
    );

    final data = jsonDecode(response.body);

    print("_verifyPayment---$data");

    if (!mounted) return;

    if (response.statusCode == 200 &&
        (data["status"] == 1 ||
            data["status"] == true ||
            data["status"] == "success")) {
      checkPurchaseStatus();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 70),
              SizedBox(height: 15),
              Text(
                "Payment Successful",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Thank you! Your payment has been verified.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 4));

      if (!mounted) return;

      Navigator.pop(context);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ModernBottomNav()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"] ?? "Payment verification failed"),
        ),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment success: ${response.paymentId}");
    print("Order ID: ${response.orderId}");
    print("Signature: ${response.signature}");
    _verifyPayment(response.signature.toString());
    // await Assignbatch('offline', Id, prices.toString(), response.paymentId.toString());
    //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Videos()));
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    // );
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

  Widget buildQuestionCard(dynamic question) {
    final String ques = question["question"] ?? "No question";
    final List<dynamic> options = question["options"] ?? [];
    final String rightAnswer = question["right_answer"] ?? "";
    final int correctIndex = "ABCD".indexOf(rightAnswer);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ques,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...List.generate(options.length, (index) {
              final String optionLetter = String.fromCharCode(65 + index);
              final bool isCorrect = index == correctIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          optionLetter,
                          style: TextStyle(
                            color: isCorrect ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[index] ?? "",
                        style: TextStyle(
                          fontSize: 15,
                          color: isCorrect ? Colors.green[800] : Colors.black87,
                          fontWeight:
                              isCorrect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(Icons.check, color: Colors.green, size: 22),
                  ],
                ),
              );
            }),
            const Divider(height: 30),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Correct Answer: $rightAnswer",
                style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 42, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _parseFeatures(dynamic value) {
    if (value == null) return [];

    // Case 1: Already a List
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    // Case 2: String like ["things","abc"]
    if (value is String) {
      final v = value.trim();

      if (v.startsWith('[') && v.endsWith(']')) {
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }

      // Case 3: Normal string
      return [v];
    }

    return [];
  }

  Widget courseDescription(String description) {
    String formattedDescription = description.replaceAll("\n", "<br>");

    return Html(
      data: formattedDescription.isEmpty
          ? "<p>No description available for this course.</p>"
          : formattedDescription,
      style: {
        "body": Style(
          fontSize: FontSize(15),
          lineHeight: const LineHeight(1.5),
          color: Colors.black87,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          textAlign: TextAlign.justify, // 🔥 KEY FIX
        ),
        "p": Style(
          margin: Margins.only(bottom: 10),
          textAlign: TextAlign.justify, // 🔥 IMPORTANT
        ),
        "span": Style(
          textAlign: TextAlign.justify,
        ),
        "strong": Style(fontWeight: FontWeight.bold),
        "b": Style(fontWeight: FontWeight.bold),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue,
          title: const Text("Course Details",
              style: TextStyle(color: Colors.white)),
        ),
        body:
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    final bool canClaimTrial =
        !isTrialOver && !isPurchased && isTrialAvailable == '1' && !isTrial;

    final bool trialClaimed = isTrial;
    final String id = widget.courseData["id"] ?? "";
    final String batchName =
        widget.courseData["batch_name"] ?? "Untitled Course";
    final String category = widget.courseData["cat_name"] ?? "";
    final String subCategory = widget.courseData["sub_cat_name"] ?? "";
    final String description = (widget.courseData["description"] ?? "")
        .toString()
        .trim()
        .replaceAll("null", "");
    final String imageUrl =
        (widget.courseData["batch_image"] ?? "").toString().trim();
    final String rawPrice =
        (widget.courseData["batch_price"] ?? "").toString().trim();
    final String rawOfferPrice =
        (widget.courseData["batch_offer_price"] ?? "").toString().trim();
    final String offerPrice = rawOfferPrice.isEmpty ? rawPrice : rawOfferPrice;
    final double parsedOfferPrice =
        double.tryParse(rawOfferPrice.isEmpty ? rawPrice : rawOfferPrice) ??
            0.0;
    final bool hasOffer = rawOfferPrice.isNotEmpty &&
        parsedOfferPrice < (double.tryParse(rawPrice) ?? 0);
    final String startDate = widget.courseData["start_date"] ?? "Not specified";
    final String endDate = widget.courseData["end_date"] ?? "Not specified";
    final String rawStartTime =
        (widget.courseData["start_time"] ?? "").toString();
    final String rawEndTime = (widget.courseData["end_time"] ?? "").toString();
    final String startTime =
        rawStartTime.length >= 8 ? rawStartTime.substring(0, 5) : "";
    final String endTime =
        rawEndTime.length >= 8 ? rawEndTime.substring(0, 5) : "";
    final String payMode = widget.courseData["pay_mode"] ?? "Online";
    List<dynamic> benefits = widget.courseData["course_benifits"] ?? [];
    print("isPurchased----$isTrialOver $isPurchased $isTrialAvailable}");
    print("courseData----${widget.courseData}");
    print("courseData----${apiCourseData}");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text("Course Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        // actions: [InkWell(onTap: (){
        //   initSdk();
        //   createPhonePeOrder(authToken: 'O-Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHBpcmVzT24iOjE3NzAxMTMzOTUzNTksIm1lcmNoYW50SWQiOiJNMjNRQ1UzTjU0Q0pGIn0.Rp7_fFbvQ3lpd0ES4RgGfd58wtkT2BHC7vlcDR55v-I', merchantOrderId: 'TEST123', amount: 100);
        //
        //   //initSdk();
        //
        // },child: Icon(Icons.eighteen_mp)),
        //   InkWell(onTap: (){
        //     initSdk();
        //     //startTransaction();
        //   },child: Icon(Icons.eighteen_mp)),
        //   InkWell(onTap: (){
        //     //startTransaction();
        //   },child: Icon(Icons.eighteen_mp))],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(
                            "https://truescoreedu.com/uploads/batch_image/$imageUrl"),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.menu_book_rounded,
                      size: 80, color: Colors.blue)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batchName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      "$category ${subCategory.isNotEmpty ? '• $subCategory' : ''}",
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (rawPrice.isEmpty)
                        const Text("Free Course",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green))
                      else if (hasOffer) ...[
                        Text("₹$rawPrice",
                            style: const TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 12),
                        Text("₹$offerPrice",
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ] else
                        Text("₹$rawPrice",
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                      const Spacer(),
                      Chip(
                          backgroundColor: Colors.blue.shade50,
                          label: Text(payMode,
                              style: const TextStyle(color: Colors.blue))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  //htmlTextViewer(description),
                  courseDescription(description),

                  // Html(
                  //   data: description.isEmpty
                  //       ? "<p>No description available for this course.</p>"
                  //       : description,
                  //   style: {
                  //     "body": Style(
                  //       fontSize: FontSize(15),
                  //       lineHeight: const LineHeight(1.5),
                  //       color: Colors.black87,
                  //       margin: Margins.zero,
                  //       padding: HtmlPaddings.zero,
                  //     ),
                  //     "b": Style(fontWeight: FontWeight.bold),
                  //     "strong": Style(fontWeight: FontWeight.bold),
                  //     "p": Style(margin: Margins.only(bottom: 10)),
                  //     "li": Style(margin: Margins.only(bottom: 6)),
                  //   },
                  // ),
                  const SizedBox(height: 20),
                  const Text("BENEFITS",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  benefits.isEmpty
                      ? SizedBox()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: benefits.length,
                          itemBuilder: (context, i) {
                            final spec = benefits[i];

                            // ── safe features getter ──
                            final features = () {
                              final val = spec['batch_fecherd'];
                              if (val is List) return val.cast<dynamic>();
                              if (val is String) {
                                try {
                                  final decoded = json.decode(val);
                                  if (decoded is List)
                                    return decoded.cast<dynamic>();
                                } catch (_) {}
                              }
                              return <dynamic>[];
                            }();

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spec['batch_specification_heading']
                                            ?.toString() ??
                                        '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...features.asMap().entries.map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12, bottom: 6),
                                          child: Row(
                                            children: [
                                              Text(
                                                "${e.key + 1}.",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child:
                                                      Text(e.value.toString())),
                                            ],
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),

                  _buildDetailRow(
                      Icons.calendar_today, "Start Date", startDate),
                  _buildDetailRow(Icons.calendar_month, "End Date", endDate),
                  // if (startTime.isNotEmpty && endTime.isNotEmpty)
                  //   _buildDetailRow(Icons.access_time, "Time", "$startTime - $endTime"),
                  // _buildDetailRow(Icons.groups, "Enrolled Students", "10000+ students"),
                  const SizedBox(height: 40),
                  if (canClaimTrial || trialClaimed) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: canClaimTrial
                            ? () async {
                                addPhonePay(
                                  context: context,
                                  batchId: id,
                                  isTrial: true,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              trialClaimed ? Colors.grey : Colors.blue.shade600,
                          disabledBackgroundColor: Colors.grey,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              trialClaimed
                                  ? Icons.check_circle
                                  : Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trialClaimed
                                      ? "Trial Already Claimed"
                                      : "Start Free Trial",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  trialClaimed
                                      ? "You have already claimed your trial."
                                      : "$trialDays Days Access",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (!isPurchased)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          couponApplied = false;
                          couponId = null;
                          couponController.clear();
                          discountPercent = 0;
                          discountAmount = 0;
                          finalAmount = 0;
                          isLoadingCoupon = false;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return Container(
                                    padding: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 20,
                                      bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom +
                                          20,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(25),
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          /// Drag Handle
                                          Container(
                                            width: 50,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: const CircleAvatar(
                                              backgroundColor: Colors.blue,
                                              child: Icon(Icons.school,
                                                  color: Colors.white),
                                            ),
                                            title: Text(
                                              batchName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),

                                          _buildDetailRow(Icons.calendar_today,
                                              "Start Date", startDate),
                                          _buildDetailRow(Icons.calendar_month,
                                              "End Date", endDate),

                                          const SizedBox(height: 15),

                                          TextField(
                                            controller: couponController,
                                            enabled: !couponApplied,
                                            decoration: InputDecoration(
                                              hintText: "Enter Coupon Code",
                                              prefixIcon:
                                                  const Icon(Icons.discount),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: couponApplied
                                                    ? Colors.red
                                                    : Colors.green,
                                              ),
                                              onPressed: () async {
                                                if (couponApplied) {
                                                  setState(() {
                                                    couponApplied = false;
                                                    couponId = null;
                                                    couponController.clear();
                                                    discountPercent = 0;
                                                    discountAmount = 0;
                                                    finalAmount = 0;
                                                    isLoadingCoupon = false;
                                                  });
                                                  return;
                                                }

                                                if (couponController.text
                                                    .trim()
                                                    .isEmpty) {
                                                  Fluttertoast.showToast(
                                                    msg: "Enter coupon code",
                                                    toastLength:
                                                        Toast.LENGTH_SHORT,
                                                    gravity: ToastGravity.TOP,
                                                  );

                                                  return;
                                                }

                                                final value =
                                                    await applyCouponApi();

                                                if (value != null) {
                                                  setState(() {
                                                    couponApplied = true;
                                                    couponId =
                                                        value["coupon_id"]
                                                            .toString();
                                                    originalAmount = double.parse(
                                                        value["original_amount"]
                                                            .toString());
                                                    discountPercent =
                                                        double.parse(value[
                                                                "discount_percent"]
                                                            .toString());
                                                    discountAmount = double.parse(
                                                        value["discount_amount"]
                                                            .toString());
                                                    finalAmount = double.parse(
                                                        value["final_amount"]
                                                            .toString());
                                                  });
                                                }
                                              },
                                              child: isLoadingCoupon
                                                  ? Center(
                                                      child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ))
                                                  : Text(
                                                      couponApplied
                                                          ? "Remove Coupon"
                                                          : "Apply Coupon",
                                                      style: const TextStyle(
                                                          color: Colors.white),
                                                    ),
                                            ),
                                          ),

                                          const SizedBox(height: 15),

                                          Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                children: [
                                                  _priceRow(
                                                    "Amount",
                                                    "₹$offerPrice",
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _priceRow(
                                                    "Discount",
                                                    "- ₹${discountAmount.toStringAsFixed(0)}",
                                                    color: Colors.green,
                                                  ),
                                                  const Divider(),
                                                  _priceRow(
                                                    "Payable Amount",
                                                    "₹${finalAmount == 0 ? offerPrice : finalAmount}",
                                                    isBold: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          SizedBox(
                                            width: double.infinity,
                                            height: 52,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);

                                                addPhonePay(
                                                  context: context,
                                                  batchId: id,
                                                  isTrial: false,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.shopping_cart,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                "Buy Now • ₹${finalAmount == 0 ? offerPrice : finalAmount}",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        child: Text(
                          "Buy Now",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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

  Widget _priceRow(
    String title,
    String value, {
    Color color = Colors.black,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 17 : 15,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text("$label:",
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class CoursePurchasedDialog extends StatelessWidget {
  const CoursePurchasedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎉 SUCCESS ICON
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade700,
                  ],
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            // 🎊 TITLE
            const Text(
              "Congratulations!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            // 📝 MESSAGE
            const Text(
              "Your course has been successfully purchased.\nYou can now start learning!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            // 🚀 GO TO COURSE BUTTON
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to course/videos screen
                },
                child: const Text(
                  "Go to Course",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ❌ CLOSE
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestingPaymentDialog extends StatefulWidget {
  const TestingPaymentDialog({super.key});

  @override
  State<TestingPaymentDialog> createState() => _TestingPaymentDialogState();
}

class _TestingPaymentDialogState extends State<TestingPaymentDialog> {
  @override
  void initState() {
    super.initState();

    // Auto close after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ SUCCESS ICON
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade700,
                  ],
                ),
              ),
              child: const Icon(
                Icons.check,
                size: 42,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // 🎉 TITLE
            const Text(
              "Payment Successful",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // 📝 MESSAGE
            const Text(
              "Testing payment of your course is done.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 12),

            // ⏳ LOADING DOT
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Done"))
          ],
        ),
      ),
    );
  }
}

class SimpleTextList extends StatelessWidget {
  final List<dynamic> list;

  const SimpleTextList({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        final String heading =
            item['batch_specification_heading']?.toString() ?? "";

        final List features =
            item['batch_fecherd'] is List ? item['batch_fecherd'] : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Heading
            Text(
              heading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            /// 👇 THIS IS THE IMPORTANT PART
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features
                  .map<Widget>(
                    (f) => Text(
                      "- ${f.toString()}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
