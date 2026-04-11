import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/club_message_detail_screen.dart';

class ClubMessageDetailScreen extends StatelessWidget {
  final Map message;
  final bool isIncoming;

  const ClubMessageDetailScreen({
    super.key,
    required this.message,
    required this.isIncoming,
  });

  @override
  Widget build(BuildContext context) {
    final subject = message['subject'] ?? 'بدون عنوان';
    final body = message['body'] ?? '';
    final fileUrl = message['file'];
    final messageId = message['message_number'] ?? 'غير متوفر';
    final target = message['target'] ?? 'غير محدد';
    final dateTime = message['created_at']?.toString().split('T').first ?? '';
    final teamName = isIncoming
        ? (message['send']?['name'] ?? 'غير معروف')
        : (message['send']?['name'] ?? 'نادي قريات');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل رسالة النادي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isIncoming ? Colors.green.shade400 : Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.mark_email_read, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Center(
                        child: Text(
                          isIncoming ? 'رسالة واردة من: $teamName' : 'رسالة صادرة إلى: $teamName',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Text('🧾 رقم الرسالة: $messageId',
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('📅 التاريخ: $dateTime',
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('👤 الفاضل: $target                                     المحترم',
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              Text(
                'الموضوع: $subject',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Html(
                  data: body,
                  style: {
                    "body": Style(
                      fontSize: FontSize(16),
                      lineHeight: LineHeight(1.6),
                      direction: TextDirection.rtl,
                    ),
                  },
                ),
              ),

              const SizedBox(height: 30),
              if (fileUrl != null) ...[
                const Text('📎 المرفق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final fullUrl = 'https://teams.quriyatclub.net$fileUrl';
                    final uri = Uri.parse(fullUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذر فتح المرفق')),
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.insert_drive_file, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'اضغط أدناه لتنزيل المرفق',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
