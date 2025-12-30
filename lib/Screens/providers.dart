import 'package:flutter/material.dart';
import 'package:online_classes/Providerclass.dart';
import 'package:provider/provider.dart';

import '../Providerclass.dart';

class sumi extends StatelessWidget {
  const sumi({super.key});



  @override
  Widget build(BuildContext context) {
    final providess = Provider.of<provides>(context);

    return Scaffold(

      body: Container(
        child: Center(child: Column(
          children: [
            SizedBox(height: 50,),
            Consumer<provides>(builder: (context,provides,child){
              return Text(provides.b.toString());
            }),

            SizedBox(height: 10,),
            ElevatedButton(onPressed: (){
              providess.increase();
            }, child: Text('inc')),
            SizedBox(height: 10,),
            ElevatedButton(onPressed: (){

              providess.decrease();
            }, child: Text('dec')),
          ],
        )),
      ),
    );
  }
}
