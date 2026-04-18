import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/loan_out_service.dart';
import 'dart:io';

class LoanOutDetailScreen extends StatefulWidget {
  final Map<String, dynamic> player;

  const LoanOutDetailScreen({super.key, required this.player});

  @override
  State<LoanOutDetailScreen> createState() => _LoanOutDetailScreenState();
}

class _LoanOutDetailScreenState extends State<LoanOutDetailScreen> with WidgetsBindingObserver {
  late Map<String, dynamic> player;
  bool linkSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    player = widget.player;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('📲 AppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      print('🔁 يتم الآن تحديث بيانات اللاعب...');
      _refreshPlayer();
    }
  }

  Future<void> _refreshPlayer() async {
    final updated = await LoanOutService.getLoanOutPlayer(player['id']);
    print('🧠 البيانات المسترجعة: $updated');
    if (updated != null) {
      setState(() {
        player = updated;
      });
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'مسودة';
      case 'send_to_club':
        return 'مرسل إلى النادي';
      case 'club_approve':
        return 'تمت الموافقة من النادي';
      case 'done':
        return 'جارية';
      case 'expired':
        return 'منتهي';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔎 حالة اللاعب داخل build: ${player['status']}');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('تفاصيل اللاعب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('بيانات اللاعب'),
              const SizedBox(height: 10),
              _infoRow('الاسم', player['name']),
              _infoRow('الرقم المدني', player['card_id']),
              _infoRow('تاريخ الميلاد', player['birthdate']),
              _infoRow('بداية الإعارة', player['start']),
              _infoRow('نهاية الإعارة', player['end']),
              _infoRow('الحالة', getStatusText(player['status'] ?? '')),

              const SizedBox(height: 24),
              _sectionHeader('المرفقات'),
              const SizedBox(height: 12),
              _imageView('الصورة الرياضية', player['sport_image']),
              _imageView('صورة البطاقة الأمامية', player['front_card_image']),
              _imageView('رسالة الإعارة', player['loan_letter']),
              const SizedBox(height: 30),
            ],
          ),
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🔹 زر إرسال الطلب
              if ((player['status'] ?? '') == 'draft')
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await LoanOutService.sendLoanOutToClub(player['id']);
                    if (success) {
                      await Flushbar(
                        message: '✅ تم إرسال الطلب إلى النادي بنجاح',
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green,
                        flushbarPosition: FlushbarPosition.TOP,
                        margin: const EdgeInsets.all(8),
                        borderRadius: BorderRadius.circular(8),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                      ).show(context);
                      Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('إرسال الطلب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                const SizedBox.shrink(),

              // 🔹 زر الدفع (معدل)
              if ((player['status'] ?? '') == 'club_approve')
                ElevatedButton.icon(
                  onPressed: linkSent
                      ? null
                      : () async {
                          if (Platform.isIOS) {
                            final success = await LoanOutService.sendPaymentLinkToEmail(player['id']);

                            if (success) {
                              setState(() {
                                linkSent = true;
                              });

                              Flushbar(
                                message: '📩 تم إرسال رابط الدفع إلى بريدك الإلكتروني',
                                duration: const Duration(seconds: 3),
                                backgroundColor: Colors.green,
                                flushbarPosition: FlushbarPosition.TOP,
                                margin: const EdgeInsets.all(8),
                                borderRadius: BorderRadius.circular(8),
                              ).show(context);
                            } else {
                              Flushbar(
                                message: '⚠️ حدث خطأ أثناء إرسال الرابط',
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.red,
                              ).show(context);
                            }
                          } else {
                            final url = await LoanOutService.generatePaymentUrl(player['id']);

                            if (url != null) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              ).then((_) async {
                                await _refreshPlayer();
                              });
                            } else {
                              Flushbar(
                                message: '⚠️ تعذر إنشاء رابط الدفع',
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.red,
                                flushbarPosition: FlushbarPosition.TOP,
                                margin: const EdgeInsets.all(8),
                                borderRadius: BorderRadius.circular(8),
                              ).show(context);
                            }
                          }
                        },
                  icon: Icon(
                    linkSent ? Icons.check : Icons.payment,
                  ),
                  label: Text(
                    linkSent
                        ? 'تم إرسال الرابط ✅'
                        : (Platform.isIOS ? 'إرسال رابط الدفع' : 'دفع رسوم الإعارة'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: linkSent ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

              if ((player['status'] ?? '') == 'draft')
                IconButton(
                  onPressed: () {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.warning,
                      animType: AnimType.bottomSlide,
                      title: 'تأكيد الحذف',
                      desc: 'هل أنت متأكد من حذف هذا الطلب؟',
                      btnCancelText: 'إلغاء',
                      btnCancelOnPress: () {},
                      btnOkText: 'حذف',
                      btnOkColor: Colors.red,
                      btnOkOnPress: () async {
                        final success = await LoanOutService.deleteLoanOutPlayer(player['id']);
                        if (success) {
                          await Flushbar(
                            message: '✅ تم حذف الطلب بنجاح',
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                            flushbarPosition: FlushbarPosition.TOP,
                            margin: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(8),
                          ).show(context);
                          Navigator.pop(context, true);
                        }
                      },
                    ).show();
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'حذف',
                )
              else
                const SizedBox.shrink(),
              ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value?.toString() ?? '-', style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _imageView(String label, String? imagePath) {
    final String fullUrl = 'https://teams.quriyatclub.net/$imagePath';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              fullUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
