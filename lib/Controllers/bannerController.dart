// import 'dart:convert';
//
// import 'package:get/get.dart';
// import 'package:http/http.dart' as https;
//
// import '../Models/bannerBodel.dart';
//
// class BannerControlle extends GetxController {
//   var bannerList = Rxn<List<bannerModel>>();
//
//   String _bashUrl = "https://digiacademy.onrender.com/digi/courses";
//
//   getBanner() async {
//      print('starrt');
//     final response = await https.get(Uri.parse(_bashUrl));
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       // print("i am here ${response.body}");
//       var data = jsonDecode(response.body);
//        print("body ${data}");
//       bannerList.value = bannerModel.fromJson(data);
//
//       print("body ${bannerList}");
//     } else {
//       print("statusCode ${response.statusCode}");
//     }
//   }
// }
