import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
  String orderid='';
  String tokenid='';




  late Map<String, dynamic> payload = {
    "orderId":orderid.toString(),
    "merchantId":"MERCHNATID",
    "token":tokenid.toString(),
    "paymentMode":{"type":"PAY_PAGE"}
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
      "paymentFlow": {
        "type": "PG_CHECKOUT"
      }
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": authToken, // 👈 IMPORTANT
      },
      body: jsonEncode(body),
    );
    print(response.body);


    if (response.statusCode == 200 || response.statusCode == 201) {
      final data= jsonDecode(response.body);
      setState(() {
        orderid=data["orderId"];
        tokenid=data["token"];
      });
      print(orderid);
      startTransaction();

    } else {
      throw Exception(
        "PhonePe order failed (${response.statusCode}): ${response.body}",
      );
    }
  }




  void initSdk(){

    PhonePePaymentSdk.init(environment, merchantId, flowId,
        enableLogs).then((isInitialized)=> {
      print("initialized : $isInitialized")
    }).catchError((onError){
      print("onError : $onError");
      return <dynamic>{};

    });


  }

  void startTransaction(){

    PhonePePaymentSdk.startTransaction(request, appSchema)
        .then((response) {
      if(response != null){
        String status = response['status'].toString();
        String error = response['error'].toString();
        if(status == 'SUCCESS'){
          print("success");

        }else{
          print("failed");

        }


      }else{
        print("Flow incomplete");
      }
    });



  }


  bool isLoading = true;
  bool isPurchased = false;
  Map<String, dynamic>? apiCourseData;

  List<dynamic> videoLectures = [];
  List<dynamic> allQuestions = [];

  Widget testoraBannerCard() {

    return InkWell(onTap: (){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>Videos(id: widget.courseData["id"].toString(),)));
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
        child:
        Stack(
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

  double prices=0;
  String Id = '';
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    print(widget.courseData);
    SecureScreen.enable();




    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    checkPurchaseStatus();
    fetchNotes();
  }

  Future<void> checkPurchaseStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    final String courseId = widget.courseData["id"]?.toString() ?? "";
    print(token);
    print(courseId);

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-batche-details"),
        body: {
          "apiToken": token.toString(),
          "courseId": courseId,
        },
      );

      final data = jsonDecode(response.body);
      print("Purchase check API response: $data");

      if (data["status"] == "true" && data["data"]["isPurchased"] == true) {
        setState(() {
          isPurchased = true;
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

          _tabController = TabController(length: availableTabs.length, vsync: this);
          isLoading = false;
        });
      } else {
        setState(() {
          isPurchased = false;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error checking purchase: $e");
      setState(() {
        isPurchased = false;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    SecureScreen.disable();

    if (availableTabs.isNotEmpty) _tabController.dispose();
    _razorpay.clear();
    super.dispose();
  }
  String orderids='';
  String mecrhant='';

  Future<void> addPhonePay(BuildContext context, String batchId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print(token);
    print(batchId);

    final response = await http.post(
      Uri.parse("https://truescoreedu.com/api/payment/initiate"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "apiToken": token.toString(),
        "batch_id": batchId.toString(),
      },
    );

    final data = jsonDecode(response.body);
    print(data);

    if (response.statusCode == 200 && data['status'] == 1) {
      print('ok');
      final redirectUrl = data['data']['redirect_url'];
      final transactionId = data['data']['transaction_id'];
      final orderId = data['data']['order_id'];
      final type = data['data']['gateway'];
      final key = data['data']['key'];
      final amt = data['data']['amount'];
      setState(() {
        orderids=orderId.toString();
        mecrhant=transactionId.toString();
      });

      double d = double.parse(amt);
      startPayment(d,orderId.toString(),key.toString());



      print(transactionId);
      print(orderId);


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
          margin:  Margins.only(bottom: 8),
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




  Future Assignbatch(String mode, String batchid, String price, String trans) async {
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

    if(response.statusCode==200){
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
          "course_id":widget.courseData["id"].toString()
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



  void startPayment(double total,String orderid,String Key) {
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

  Future<void> _verifyPayment(
      String
      signature
      ) async {
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
        "gateway":"RAZORPAY",
        "signature":signature.toString(),
        "paymentStatus":"paid",


      },
    );
    print('datais${response.body}');
    checkPurchaseStatus();

   // Navigator.pop(context);
    // close loader


    final data = jsonDecode(response.body);
    print(data)
    ;
    //showPaymentResultPopup(context, data);

    // showDialog(
    //   context: context,
    //   builder: (_) => AlertDialog(
    //     title: Text(data['status'] == 1
    //         ? "Payment Successful"
    //         : "Payment Failed"),
    //     content: Text(data['message'] ?? ""),
    //     actions: [
    //       TextButton(
    //         onPressed: () {
    //           Navigator.pop(context);
    //           Navigator.pop(context); // back to previous screen
    //         },
    //         child: const Text("OK"),
    //       ),
    //     ],
    //   ),
    // );
  }


  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment success: ${response.paymentId}");
    print("Order ID: ${response.orderId}");
    print("Signature: ${response.signature}");
    _verifyPayment(response.signature.toString());
   // await Assignbatch('offline', Id, prices.toString(), response.paymentId.toString());
    //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Videos()));
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
            Text(ques, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrect) const Icon(Icons.check, color: Colors.green, size: 22),
                  ],
                ),
              );
            }),
            const Divider(height: 30),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Correct Answer: $rightAnswer",
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
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
    return
      Expanded(
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
    return Html(
      data: description.isEmpty
          ? "<p>No description available for this course.</p>"
          : description,
      style: {
        "body": Style(
          fontSize: FontSize(15),
          lineHeight: const LineHeight(1.5),
          color: Colors.black87,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "p": Style(margin: Margins.only(bottom: 10)),
        "strong": Style(fontWeight: FontWeight.bold),
        "b": Style(fontWeight: FontWeight.bold),
      },
    );
  }




  @override
  Widget build(BuildContext context) {
   // print(apiCourseData!["course_benifits"]);
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("Course Details", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    // ==================== PURCHASED UI WITH VIDEOS + QUESTIONS ====================
    if (isPurchased && apiCourseData != null) {
      final String batchName = apiCourseData!["batch_name"] ?? "Untitled Course";
      final String category = apiCourseData!["cat_name"] ?? "";
      final String subCategory = apiCourseData!["sub_cat_name"] ?? "";
      final String description = (apiCourseData!["description"] ?? "").toString().replaceAll("null", "").trim();
      final String imageUrl = apiCourseData!["batch_image"] ?? "";
      List<dynamic> benefits=apiCourseData!["course_benifits"] ?? "";
      print("benefits$benefits");

      return
        Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.blue,
          title: const Text("Course Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () =>
                Navigator.pop(context),
          ),
          // actions: [
          //   InkWell(onTap: ()async{
          //   final tokenResponse = await getPhonePeAccessToken(
          //     clientId: "M23QCU3N54CJF_2511281615",
          //     clientSecret: "YjQ0YjkwOWEtNDllOC00Zjg5LWIyYjctMDMxYjliODk2ODk4",
          //   );
          //
          //   print(tokenResponse);
          //
          // },child: Icon(Icons.eighteen_mp))],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 30, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text("Congrats for this course!",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),

                  ],
                ),
              ),

              // Course Image
              // Container(
              //   width: double.infinity,
              //   height: 220,
              //   decoration: BoxDecoration(
              //     color: Colors.blue.shade50,
              //     image: imageUrl.isNotEmpty
              //         ? DecorationImage(
              //       image: NetworkImage("https://truescoreedu.com/uploads/batch_image/$imageUrl"),
              //       fit: BoxFit.cover,
              //     )
              //         : null,
              //   ),
              //   child: imageUrl.isEmpty ? const Icon(Icons.menu_book_rounded, size: 80, color: Colors.blue) : null,
              // ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batchName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("$category ${subCategory.isNotEmpty ? '• $subCategory' : ''}",
                        style: const TextStyle(fontSize: 16, color: Colors.black54)),
                    const SizedBox(height: 20),

                    // Purchased Success

                    const SizedBox(height: 30),
                    InkWell(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>CourseProgressScreen(batchId: widget.courseData["id"].toString(),)));
                      },
                      child: Container(decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),color: Colors.blueAccent
                      ),height: 50,child: Center(child: Text("Progress",style: TextStyle(color: Colors.white),))
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                    children: [
                      // _optionCard(
                      //   title: "MCQ",
                      //   icon: Icons.quiz_rounded,
                      //   color: const Color(0xFF4F46E5),
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (_) => QuestionTypeSelectionScreen(
                      //           questions: allQuestions,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),

                      videoLectures.length==0?SizedBox(): _optionCard(
                        title: "Videos",
                        icon: Icons.play_circle_fill_rounded,
                        color: const Color(0xFF16A34A),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>VideoListScreenfull(videoLectures: videoLectures,)));


                        },
                      ),
                     notes.isEmpty?SizedBox(): _optionCard(
                        title: "Notes",
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFFF97316),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>GetNotesScreen(batchid: widget.courseData["id"].toString(),)));

                        },
                      ),
                    ],
                  ),
                    const SizedBox(height: 30),
                    Container(
                      height: 400,
                      child:  QuestionTypeSelectionScreen(
                        questions: allQuestions, batchId: widget.courseData["id"].toString(),
                      ),
                    ),

                    testoraBannerCard(),
                    SizedBox(height: 20,),


                    // Description
                    // if (description.isNotEmpty) ...[
                    //  // const Text("About this Course", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    //   const SizedBox(height: 10),
                    //   Text(description, style: const TextStyle(fontSize: 15, height: 1.6)),
                    //   const SizedBox(height: 30),
                    // ],

                    // Video Lectures
                    // if (videoLectures.isNotEmpty) ...[
                    //   const Text("Video Lectures", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    //   const SizedBox(height: 12),
                    //   ListView.builder(
                    //     shrinkWrap: true,
                    //     physics: const NeverScrollableScrollPhysics(),
                    //     itemCount: videoLectures.length,
                    //     itemBuilder: (context, index) {
                    //       final video = videoLectures[index];
                    //       final String title = video["title"] ?? "Untitled";
                    //       final String url = video["url"] ?? "";
                    //
                    //       return Card(
                    //         margin: const EdgeInsets.symmetric(vertical: 8),
                    //         child: ListTile(
                    //           leading: Container(
                    //             width: 50,
                    //             height: 50,
                    //             decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                    //             child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 34),
                    //           ),
                    //           title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    //           subtitle: Text(video["subject"] ?? "", style: TextStyle(color: Colors.grey[600])),
                    //           trailing: const Icon(Icons.arrow_forward_ios),
                    //           onTap: url.isNotEmpty
                    //               ? () => Navigator.push(
                    //             context,
                    //             MaterialPageRoute(
                    //               builder: (_) => VideoPlayerScreen(videoTitle: title, youtubeUrl: url),
                    //             ),
                    //           )
                    //               : null,
                    //         ),
                    //       );
                    //     },
                    //   ),
                    //   const SizedBox(height: 30),
                    // ],
                    //
                    // // Practice Questions (at bottom)
                    // if (availableTabs.isNotEmpty) ...[
                    //   const Text("Practice Questions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    //   const SizedBox(height: 16),
                    //   TabBar(
                    //     controller: _tabController,
                    //     isScrollable: availableTabs.length > 2,
                    //     labelColor: Colors.blue,
                    //     unselectedLabelColor: Colors.grey,
                    //     indicatorColor: Colors.blue,
                    //     tabs: availableTabs.map((tab) => Tab(text: tab)).toList(),
                    //   ),
                    //   SizedBox(
                    //     height: 600,
                    //     child: TabBarView(
                    //       controller: _tabController,
                    //       children: availableTabs.map((tabName) {
                    //         final questions = questionsByType[tabName] ?? [];
                    //         return ListView.builder(
                    //           padding: const EdgeInsets.only(top: 16),
                    //           itemCount: questions.length,
                    //           itemBuilder: (context, index) => buildQuestionCard(questions[index]),
                    //         );
                    //       }).toList(),
                    //     ),
                    //   ),
                    // ] else ...[
                    //   const Center(
                    //     child: Text("No practice questions available yet.", style: TextStyle(color: Colors.grey)),
                    //   ),
                    // ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==================== NOT PURCHASED - ORIGINAL BUY UI ====================
    final String id = widget.courseData["id"] ?? "";
    final String batchName = widget.courseData["batch_name"] ?? "Untitled Course";
    final String category = widget.courseData["cat_name"] ?? "";
    final String subCategory = widget.courseData["sub_cat_name"] ?? "";
    final String description = (widget.courseData["description"] ?? "").toString().trim().replaceAll("null", "");
    final String imageUrl = (widget.courseData["batch_image"] ?? "").toString().trim();
    final String rawPrice = (widget.courseData["batch_price"] ?? "").toString().trim();
    final String rawOfferPrice = (widget.courseData["batch_offer_price"] ?? "").toString().trim();
    final String offerPrice = rawOfferPrice.isEmpty ? rawPrice : rawOfferPrice;
    final double parsedOfferPrice = double.tryParse(rawOfferPrice.isEmpty ? rawPrice : rawOfferPrice) ?? 0.0;
    final bool hasOffer = rawOfferPrice.isNotEmpty && parsedOfferPrice < (double.tryParse(rawPrice) ?? 0);
    final String startDate = widget.courseData["start_date"] ?? "Not specified";
    final String endDate = widget.courseData["end_date"] ?? "Not specified";
    final String rawStartTime = (widget.courseData["start_time"] ?? "").toString();
    final String rawEndTime = (widget.courseData["end_time"] ?? "").toString();
    final String startTime = rawStartTime.length >= 8 ? rawStartTime.substring(0, 5) : "";
    final String endTime = rawEndTime.length >= 8 ? rawEndTime.substring(0, 5) : "";
    final String payMode = widget.courseData["pay_mode"] ?? "Online";
    List<dynamic> benefits=widget.courseData["course_benifits"] ?? [];
   print("benefits$benefits");
   print("des$description");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: const Text("Course Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
                  image: NetworkImage("https://truescoreedu.com/uploads/batch_image/$imageUrl"),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: imageUrl.isEmpty ? const Icon(Icons.menu_book_rounded, size: 80, color: Colors.blue) : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(batchName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("$category ${subCategory.isNotEmpty ? '• $subCategory' : ''}",
                      style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (rawPrice.isEmpty)
                        const Text("Free Course", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green))
                      else if (hasOffer) ...[
                        Text("₹$rawPrice", style: const TextStyle(fontSize: 20, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 12),
                        Text("₹$offerPrice", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
                      ] else
                        Text("₹$rawPrice", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const Spacer(),
                      Chip(backgroundColor: Colors.blue.shade50, label: Text(payMode, style: const TextStyle(color: Colors.blue))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  const Text("BENEFITS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 benefits.isEmpty?SizedBox(): ListView.builder(
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
                            if (decoded is List) return decoded.cast<dynamic>();
                          } catch (_) {}
                        }
                        return <dynamic>[];
                      }();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spec['batch_specification_heading']?.toString() ?? '',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...features.asMap().entries.map((e) =>
                                Padding(
                                  padding: const EdgeInsets.only(left: 12, bottom: 6),
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
                                      Expanded(child: Text(e.value.toString())),
                                    ],
                                  ),
                                ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     for (var item in benefits) ...[
                  //       /// Heading
                  //       Text(
                  //         item['batch_specification_heading']?.toString() ?? '',
                  //         style: const TextStyle(
                  //           fontSize: 16,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //
                  //       const SizedBox(height: 4),
                  //
                  //
                  //       /// Features
                  //       ListView.builder(
                  //         shrinkWrap: true,
                  //         physics: const NeverScrollableScrollPhysics(),
                  //         itemCount: benefits.length,
                  //         itemBuilder: (context, i) {
                  //           final spec = benefits[i];
                  //
                  //           // ── safe features getter ──
                  //           final features = () {
                  //             final val = spec['batch_fecherd'];
                  //             if (val is List) return val.cast<dynamic>();
                  //             if (val is String) {
                  //               try {
                  //                 final decoded = json.decode(val);
                  //                 if (decoded is List) return decoded.cast<dynamic>();
                  //               } catch (_) {}
                  //             }
                  //             return <dynamic>[];
                  //           }();
                  //
                  //           return Padding(
                  //             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  //             child: Column(
                  //               crossAxisAlignment: CrossAxisAlignment.start,
                  //               children: [
                  //                 Text(
                  //                   spec['batch_specification_heading']?.toString() ?? '',
                  //                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  //                     fontWeight: FontWeight.w600,
                  //                   ),
                  //                 ),
                  //                 const SizedBox(height: 8),
                  //                 ...features.asMap().entries.map((e) =>
                  //                     Padding(
                  //                       padding: const EdgeInsets.only(left: 12, bottom: 6),
                  //                       child: Row(
                  //                         children: [
                  //                           Text(
                  //                             "${e.key + 1}.",
                  //                             style: const TextStyle(
                  //                               fontWeight: FontWeight.w500,
                  //                               color: Colors.blueGrey,
                  //                             ),
                  //                           ),
                  //                           const SizedBox(width: 8),
                  //                           Expanded(child: Text(e.value.toString())),
                  //                         ],
                  //                       ),
                  //                     ),
                  //                 ),
                  //               ],
                  //             ),
                  //           );
                  //         },
                  //       ),
                  //
                  //
                  //
                  //
                  //
                  //       const SizedBox(height: 16),
                  //     ]
                  //   ],
                  // ),

                  // Container(height: 200,
                  //   child: SimpleTextList(list: benefits)
                  //
                  // ),

                  _buildDetailRow(Icons.calendar_today, "Start Date", startDate),
                  _buildDetailRow(Icons.calendar_month, "End Date", endDate),
                  // if (startTime.isNotEmpty && endTime.isNotEmpty)
                  //   _buildDetailRow(Icons.access_time, "Time", "$startTime - $endTime"),
                 // _buildDetailRow(Icons.groups, "Enrolled Students", "10000+ students"),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        // double d = parsedOfferPrice;
                        //   setState(() {
                        //     prices = d;
                        //     Id = id.toString();
                        //   });

                       if (rawPrice.isEmpty) {
                         await Assignbatch('online', id, "00", "");
                          // Navigator.pushReplacement(
                          //   context,
                          //   MaterialPageRoute(builder: (_) => Videos(id: widget.courseData["id"].toString(),)),
                          // );
                        }else if(rawPrice.isNotEmpty){
                          double d = parsedOfferPrice;
                          setState(() {
                            prices = d;
                            Id = id.toString();
                          });
                          final int amount = (parsedOfferPrice * 100).toInt();

                          if (d <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invalid payment amount")),
                            );
                            return;
                          }
                          print("pp$d");
                          addPhonePay(context,id);
                          // showDialog(
                          //   context: context,
                          //   barrierDismissible: false,
                          //   builder: (_) => const TestingPaymentDialog(),
                          // );


                          //startPayment(d);
                          // initSdk();
                          // createPhonePeOrder(authToken: 'O-Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHBpcmVzT24iOjE3NzAxMTMzOTUzNTksIm1lcmNoYW50SWQiOiJNMjNRQ1UzTjU0Q0pGIn0.Rp7_fFbvQ3lpd0ES4RgGfd58wtkT2BHC7vlcDR55v-I', merchantOrderId: 'TEST123', amount: amount);
                          // await Assignbatch('online', id, d.toString(), "dkdsk");



                       } else {
                          print('nooo');

                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Text(
                        rawPrice.isEmpty ? "Join Free" : "Buy Now",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
        child:
        Column(
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
            ElevatedButton(onPressed: (){
              Navigator.pop(context);
            }, child: Text("Done"))


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

