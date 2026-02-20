import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class PhonePeWebViewScreen extends StatefulWidget {
  final String redirectUrl;
  final String transactionId;
  final String orderId;
  final String apiToken;
  final String gateway;


  const PhonePeWebViewScreen({
    super.key,
    required this.redirectUrl,
    required this.transactionId,
    required this.orderId,
    required this.apiToken,
    required this.gateway
  });

  @override
  State<PhonePeWebViewScreen> createState() => _PhonePeWebViewScreenState();
}

class _PhonePeWebViewScreenState extends State<PhonePeWebViewScreen> {
  late final WebViewController _controller;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {

            print('yes');
            print(request.url);
            Uri uri = Uri.parse(request.url);


            if (request.url.contains(
                "https://truescoreedu.com/api/payment/callback")) {

              print('set');

              /// ✅ Parse Full URL

              /// ✅ Extract Razorpay Params
              String? paymentId =
              uri.queryParameters['razorpay_payment_id'];

              String? signature =
              uri.queryParameters['razorpay_signature'];

              String? paymentStatus =
              uri.queryParameters['razorpay_payment_link_status'];

              String? referenceId =
              uri.queryParameters['razorpay_payment_link_reference_id'];

              print("Payment ID => $paymentId");
              print("Signature => $signature");
              print("Status => $paymentStatus");
              print("Reference => $referenceId");

              /// 🔥 call your function and pass variables
              _handleCallback(
                paymentId.toString(),
                signature.toString(),
                paymentStatus.toString(),
                referenceId.toString(),
              );

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },

        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  Future<void> _handleCallback(String  paymentId,
      String
      signature,String
      paymentStatus,
      String
      referenceId,) async {
    if (_verifying) return;
    _verifying = true;

    Navigator.pop(context); // close webview
    _showBlockingLoader();

    await _verifyPayment(
        paymentId,

      signature,
      paymentStatus,

      referenceId,
    );
  }

  void _showBlockingLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _verifyPayment(String  paymentId,
      String
      signature,String
      paymentStatus,
      String
      referenceId,) async {
    final response = await http.post(
      Uri.parse("https://truescoreedu.com/api/payment/verify"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "merchantOrderId": widget.transactionId,
        "orderid": widget.orderId,
        "apiToken": widget.apiToken,
        "gateway":widget.gateway.toString(),
        "paymentid":paymentId.toString(),
        "signature":signature.toString(),
        "paymentStatus":paymentStatus.toString(),
        "referenceId":referenceId.toString()


      },
    );
    print('datais${response.body}');

    Navigator.pop(context);
    // close loader


    final data = jsonDecode(response.body);
    print(data)
;
    showPaymentResultPopup(context, data);

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
  void showPaymentResultPopup(BuildContext context, Map<String, dynamic> data) {
    final bool isSuccess = data['status'] == 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        // ⏱ Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // go back to previous screen
          }
        });

        return SafeArea(
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 450),
              tween: Tween(begin: 0.7, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔵 ICON
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSuccess
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                        ),
                        child: Icon(
                          isSuccess
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 70,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 🟢 TITLE
                      Text(
                        isSuccess
                            ? "Payment Successful"
                            : "Payment Failed",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 📄 MESSAGE
                      Text(
                        data['message'] ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ⏳ AUTO CLOSE TEXT
                      // Text(
                      //   "Closing automatically...",
                      //   style: TextStyle(
                      //     fontSize: 12,
                      //     color: Colors.grey.shade500,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text(widget.gateway.toString())),
      body: WebViewWidget(controller: _controller),
    );
  }
}
