import 'package:flutter/material.dart';

class NoteviewerScreen extends StatefulWidget {
  const NoteviewerScreen({super.key});

  @override
  State<NoteviewerScreen> createState() => _NoteviewerScreenState();
}

class _NoteviewerScreenState extends State<NoteviewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(title: Text("Note's"),),
    );
  }
}
