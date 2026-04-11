import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class PlayerCard extends StatelessWidget {
  final Map player;

  const PlayerCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = 'https://teams.quriyatclub.net/${player['player_img']}';
    final String status = player['join_status']?.toString() ?? ' غير معروف';
    final String name = player['name']?.toString() ?? '';
    final String cardId = player['card_id']?.toString() ?? '';
    final String birthDateRaw = player['birth_date']?.toString() ?? '';
    final String registrationNumber = player['register_number']?.toString() ?? 'غير معروف ';

    // لون الشارة حسب الحالة
    Color statusColor;
    switch (status) {
      case 'معار':
        statusColor = const Color(0xFF2196F3);
        break;
      case 'منتسب':
        statusColor = Colors.green;
        break;
      case 'موقف':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // تنسيق التاريخ
    String formattedBirthDate = birthDateRaw;
    try {
      final parsed = DateTime.parse(birthDateRaw);
      formattedBirthDate = intl.DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {}

    return Directionality(
  textDirection: TextDirection.ltr, // ✅ اتجاه البطاقة فقط
  child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        children: [
          // القسم العلوي البرتقالي
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // ✅ Row: صورة - اسم - شارة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // شارة الحالة (يسار)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // الاسم (وسط)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),

                    // الصورة (يمين)
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

                // عناوين الحقول
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('رقم القيد', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                _dataContainer(registrationNumber),
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
