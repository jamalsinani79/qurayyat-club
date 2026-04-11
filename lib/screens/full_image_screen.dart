import 'package:flutter/material.dart';

class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // ✅ يجعل السهم على اليمين
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عرض الصورة'),
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
