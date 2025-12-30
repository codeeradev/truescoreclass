import 'package:flutter/material.dart';
import 'package:online_classes/ThemeConstent/themeData.dart';

class CommunnityScreen extends StatefulWidget {
  const CommunnityScreen({super.key});

  @override
  State<CommunnityScreen> createState() => _CommunnityScreenState();
}

class _CommunnityScreenState extends State<CommunnityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false, // Removes the back button
        title: Text("Community Screen",style: TextStyle(color: Colors.black),),),
      body: Container(
        child: ListView.builder(itemBuilder: (context,index){
          return Container(

            margin: EdgeInsets.symmetric(
              vertical: 10,horizontal: 10
            ),
            height: 200,width: double.maxFinite,
            child: TweetCard(profileImageUrl: 'http://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg', userName: "sdfds", tweetText: 'fdsfsdfdsffdsfdfdsfsd'),
          );
        },itemCount: 2,)
      ),
    );
  }
}


class TweetCard extends StatelessWidget {
  final String profileImageUrl;
  final String userName;
  final String tweetText;

  const TweetCard({
    Key? key,
    required this.profileImageUrl,
    required this.userName,
    required this.tweetText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(

      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Image + Name
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
              SizedBox(width: 12),
              Text(
                userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 22),

          // Center: Text
          Text(
            tweetText,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 16),

          // Bottom: Like & Dislike buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  // Like button pressed
                },
                icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.blue),
              ),
              IconButton(
                onPressed: () {
                  // Dislike button pressed
                },
                icon: Icon(Icons.thumb_down_alt_outlined, color: Colors.red),
              ),
            ],
          )
        ],
      ),
    );
  }
}
