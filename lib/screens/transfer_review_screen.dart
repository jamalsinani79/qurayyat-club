import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:another_flushbar/flushbar.dart';

import 'full_image_screen.dart';
import '../services/team_service.dart';

class TransferReviewScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const TransferReviewScreen({super.key, required this.request});

  @override
  State<TransferReviewScreen> createState() => _TransferReviewScreenState();
}

class _TransferReviewScreenState extends State<TransferReviewScreen> {
  bool approved = false;

  void showTopMessage(String message, Color color) {
    Future.delayed(const Duration(milliseconds: 300), () {
      Flushbar(
        message: message,
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(8),
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    });
  }

  void acceptRequest() {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.question,
    animType: AnimType.rightSlide,
    title: 'تأكيد القبول',
    desc: 'هل أنت متأكد من قبول هذا الطلب؟',
    btnCancelText: 'لا',
    btnOkText: 'نعم',
    btnCancelOnPress: () {},
    btnOkOnPress: () async {
      final id = widget.request['id'];
      final result = await TeamService.approveTransferRequest(id);
      if (!mounted) return;

      showTopMessage(result['message'], result['status'] ? Colors.green : Colors.red);
      if (result['status']) {
        Navigator.pop(context, true);
      }
    },
  ).show();
}


  void rejectRequest() {
  AwesomeDialog(
    context: context,
    dialogType: DialogType.warning,
    animType: AnimType.rightSlide,
    title: 'تأكيد الرفض',
    desc: 'هل أنت متأكد من رفض هذا الطلب؟',
    btnCancelText: 'لا',
    btnOkText: 'نعم',
    btnCancelOnPress: () {},
    btnOkOnPress: () async {
      final id = widget.request['id'];
      final result = await TeamService.rejectTransferRequest(id);
      setState(() {
        // لتأكيد أن هناك تغيير حصل قبل الإغلاق
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        showTopMessage(result['message'], result['status'] ? Colors.red : Colors.orange);
      });
    },
    onDismissCallback: (type) {
      if (type == DismissType.btnOk) {
        Navigator.pop(context, true);
      }
    },
  ).show();
}


  Future<void> saveImageToPhone(String url) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      showTopMessage('يرجى منح صلاحية التخزين', Colors.orange);
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      final Uint8List bytes = response.bodyBytes;

      final Directory? directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final String filePath =
          '${directory!.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      showTopMessage('✅ تم حفظ الصورة في ${directory.path}', Colors.green);
    } catch (e) {
      showTopMessage('❌ فشل حفظ الصورة', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final player = req['player'] ?? {};
    final teamSender = req['sender']?['name'] ?? '---';
    final teamReceiver = req['basic']?['name'] ?? '---';
    final attachment = req['player_approve_doc'] != null
        ? 'https://teams.quriyatclub.net${req['player_approve_doc']}'
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مراجعة طلب النقل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionTitle('بيانات اللاعب'),
              buildInfoRow('الرقم المدني', player['card_id']),
              buildInfoRow('رقم القيد', player['register_number']),
              buildInfoRow('مكان الإقامة', player['location']),
              buildInfoRow('رقم الهاتف', player['phone']),
              const SizedBox(height: 20),

              buildSectionTitle('بيانات الطلب'),
              buildInfoRow('رقم الطلب', req['id']),
              buildInfoRow('زمن الطلب', req['created_at']),
              buildInfoRow('الفريق الراغب', teamSender),
              buildInfoRow('الفريق الأساسي', teamReceiver),
              const SizedBox(height: 20),

              if (attachment != null && attachment.toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle('📎 المرفق'),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullImageScreen(imageUrl: attachment),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              attachment,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text('فشل تحميل الصورة'),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => saveImageToPhone(attachment),
                              icon: const Icon(Icons.download, color: Colors.white),
                              tooltip: 'تحميل المرفق',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.orange.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بناءً على طلب المذكور أعلاه، فإنه لا مانع لدينا من قبول طلبه، '
                      'وأنه لا يخضع حالياً لأي عقوبات أو توقيف صادر من الفريق أو النادي '
                      'وغير مطالب بأي التزامات إدارية أو مالية. كما أن البيانات الموضحة صحيحة، '
                      'وعليه أعطيت له هذه الشهادة.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: approved,
                      onChanged: (val) => setState(() => approved = val ?? false),
                      title: const Text('أوافق على ما ذكر أعلاه'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: approved ? acceptRequest : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('✔ قبول', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: rejectRequest,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('✘ رفض', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget buildInfoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value?.toString() ?? '--')),
        ],
      ),
    );
  }
}
