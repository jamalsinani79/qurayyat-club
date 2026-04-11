import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          'جميع الحقوق محفوظة © نادي قريات 2025',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
