import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class LoanOutPlayerCard extends StatelessWidget {
  final Map<String, dynamic> player;

  const LoanOutPlayerCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final String name = player['name']?.toString() ?? 'بدون اسم';
    final String cardId = player['card_id']?.toString() ?? '---';
    final String birthDateRaw = player['birthdate']?.toString() ?? '';
    final String imageUrl = 'https://teams.quriyatclub.net/${player['sport_image']}';
    final String status = player['status']?.toString() ?? 'draft';

    // تنسيق التواريخ
    String formattedBirthDate = _formatDate(birthDateRaw);

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
                      // الصورة على اليسار
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
                      const SizedBox(width: 8),
                      // الاسم على اليمين
                      Expanded(
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  // عنواين الحقول
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('الرقم المدني', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('تاريخ الميلاد', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('حالة الطلب', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                  _dataContainer(cardId),
                  _dataContainer(formattedBirthDate),
                  _statusBadge(status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final parsed = DateTime.parse(raw);
      return intl.DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return raw;
    }
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

  Widget _statusBadge(String status) {
    final text = _getStatusText(status);
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'send_to_club':
        return 'مرسل للنادي';
      case 'club_approve':
        return 'وافق النادي';
      case 'done':
        return 'جارية';
      case 'expired':
        return 'منتهي';
      default:
        return 'غير معروف';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'send_to_club':
        return Colors.orange;
      case 'club_approve':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }


}
