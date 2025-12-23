import 'package:flutter/material.dart';
import 'package:rich_edtior_library/Rich_Edtior/rich_edtior.dart';

class EditorDemoScreen extends StatelessWidget {
  const EditorDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Rich Editor Demo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 8),
          child: CustomRichEditor(), // ✅ YOUR EDITOR
        ),
      ),
    );
  }
}
