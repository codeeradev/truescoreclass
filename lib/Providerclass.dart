import 'package:flutter/cupertino.dart';

class provides with ChangeNotifier{




  int b =0;


  increase(){
    b++;
    notifyListeners();
  }

  decrease(){
    b--;
    notifyListeners();
  }

}