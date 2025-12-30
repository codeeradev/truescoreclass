import 'package:flutter/material.dart';
import 'package:online_classes/ThemeConstent/themeData.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes the back button
        backgroundColor: Colors.white,
        title: Text("Dashboard", style: TextStyle(color: Colors.black),),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white,),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            shrinkWrap: true, // Important to make it work inside SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Prevent conflict with parent scroll
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2 / 2.5, // 👈 Reduce this value to increase card height
            ),
            itemCount: 10, // Change this based on your data
            itemBuilder: (context, index) {
              return Material(
                elevation: 10, // You can adjust this value for more or less elevation
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black45, // Optional: for a more subtle shadow
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primeryColor,
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage('assets/images/img_1.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Card ${index + 1}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              );

            },
          ),
        ),
      ),

    );
  }
}
