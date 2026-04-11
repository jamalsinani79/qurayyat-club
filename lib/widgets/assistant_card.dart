import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class AssistantCard extends StatelessWidget {
  final Map<String, dynamic> assistant;

  const AssistantCard({super.key, required this.assistant});

  @override
  Widget build(BuildContext context) {
    final String name = assistant['name'] ?? 'بدون اسم';
    final String cardId = assistant['card_id'] ?? '---';
    final String role = assistant['role'] ?? '---';
    final String birthDateRaw = assistant['birthdate'] ?? '';
    final String imageUrl = 'https://teams.quriyatclub.net/${assistant['sport_image']}';

    // تنسيق تاريخ الميلاد
    String formattedBirthDate = birthDateRaw;
    try {
      final parsed = DateTime.parse(birthDateRaw);
      formattedBirthDate = intl.DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {}

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        child: Column(
          children: [
            // القسم العلوي البرتقالي
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFA726),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // الاسم
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      // الصورة
                      ClipOval(
                        child: Image.network(
                          imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('الصفة', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('تاريخ الميلاد', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('الرقم المدني', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            // القسم السفلي الأبيض
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dataContainer(role),
                  _dataContainer(formattedBirthDate),
                  _dataContainer(cardId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataContainer(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }
} 