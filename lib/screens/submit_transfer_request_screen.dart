import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/team_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmitTransferRequestScreen extends StatefulWidget {
  final Map<String, dynamic> player;
  final Map<String, dynamic>? request;
  final bool isReviewMode;

  const SubmitTransferRequestScreen({
    super.key,
    required this.player,
    this.request,
    this.isReviewMode = false,
  });

  @override
  State<SubmitTransferRequestScreen> createState() => _SubmitTransferRequestScreenState();
}

class _SubmitTransferRequestScreenState extends State<SubmitTransferRequestScreen> with WidgetsBindingObserver {
  File? playerDoc;
  File? fatherDoc;
  File? fatherId;
  bool isSubmitting = false;
  bool hasTransaction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    hasTransaction = widget.request?['transaction_id'] != null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshTransferRequest();
    }
  }

  void showTopMsg(String msg, {bool isError = false}) {
    final color = isError ? Colors.red : Colors.green;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get playerAge {
    final birthRaw = widget.player['birth_date'];
    final birthDate = DateTime.tryParse(birthRaw?.toString() ?? '');
    if (birthDate == null) return 100;
    final today = DateTime.now();
    return today.year - birthDate.year - (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day) ? 1 : 0);
  }

  Future<void> pickImage(Function(File) onPicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) onPicked(File(picked.path));
  }

  Future<void> submit() async {
    if (playerAge >= 16 && playerDoc == null) {
      return showMsg('يرجى رفع موافقة اللاعب');
    }
    if (playerAge < 16 && (fatherDoc == null || fatherId == null)) {
      return showMsg('يرجى رفع وثائق ولي الأمر');
    }

    setState(() => isSubmitting = true);
    final response = await TeamService.submitTransferRequest(
      cardId: widget.player['card_id'].toString(),
      playerDoc: playerDoc,
      fatherDoc: fatherDoc,
      fatherId: fatherId,
    );

    setState(() => isSubmitting = false);

    if (response['status'] == true) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'تم الإرسال',
        desc: 'تم إرسال طلب النقل بنجاح. سيتم مراجعته من قبل الفريق الأساسي.',
        btnOkText: 'حسناً',
        btnOkOnPress: () {
          Navigator.pop(context, true);
        },
      ).show();
    } else {
      showTopMsg(response['message'] ?? 'حدث خطأ أثناء إرسال الطلب', isError: true);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> launchPayment() async {
    final id = widget.request?['id'];
    if (id == null) return;

    try {
      final response = await TeamService.generateTransferPaymentUrl(id);
      final paymentUrl = response['url'];

      if (await canLaunchUrl(Uri.parse(paymentUrl))) {
        await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
      } else {
        showTopMsg('تعذر فتح صفحة الدفع', isError: true);
      }
    } catch (e) {
      showTopMsg('حدث خطأ أثناء تحميل رابط الدفع', isError: true);
    }
  }

  Future<void> refreshTransferRequest() async {
    final id = widget.request?['id'];
    if (id == null) return;

    final token = await TeamService.getToken();
    final url = Uri.parse('https://teams.quriyatclub.net/api/v1/player/transfer/show?id=$id');

    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        setState(() {
          widget.request?.clear();
          widget.request?.addAll(data['info']);
          hasTransaction = widget.request?['transaction_id'] != null;
        });
      } else {
        print('🟥 فشل تحديث الطلب: ${data['message']}');
      }
    } catch (e) {
      print('🟥 خطأ في تحديث الطلب: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYoung = playerAge < 16;
    final status = widget.request?['status'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تقديم طلب نقل'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Container(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text('بيانات اللاعب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 14),
              Table(
                columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  tableRow('الاسم', widget.player['name']),
                  tableRow('الرقم المدني', widget.player['card_id'].toString()),
                  tableRow('رقم القيد', widget.player['register_number']?.toString() ?? '-'),
                  tableRow('مكان الإقامة', widget.player['location'] ?? '-'),
                  tableRow('رقم الهاتف', widget.player['phone'] ?? '-'),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.isReviewMode && status == 'وافق عليه النادي') ...[
                const Text('📎 المرفقات:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (widget.request?['player_approve_doc'] != null)
                  previewAttachment('استمارة اللاعب', 'https://teams.quriyatclub.net${widget.request?['player_approve_doc']}'),
                if (widget.request?['father_approve_doc'] != null)
                  previewAttachment('موافقة ولي الأمر', 'https://teams.quriyatclub.net${widget.request?['father_approve_doc']}'),
                if (widget.request?['father_identy_doc'] != null)
                  previewAttachment('بطاقة ولي الأمر', 'https://teams.quriyatclub.net${widget.request?['father_identy_doc']}'),
                const SizedBox(height: 24),
              ],
              if (!widget.isReviewMode) ...[
                Container(
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text('بيانات الطلب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),
                if (isYoung) ...[
                  buildUploadBox('استمارة موافقة ولي الأمر', fatherDoc, () => pickImage((f) => setState(() => fatherDoc = f))),
                  const SizedBox(height: 12),
                  buildUploadBox('بطاقة ولي الأمر', fatherId, () => pickImage((f) => setState(() => fatherId = f))),
                ] else
                  buildUploadBox('استمارة موافقة اللاعب', playerDoc, () => pickImage((f) => setState(() => playerDoc = f))),
                const SizedBox(height: 24),
              ],
              if (widget.isReviewMode && status == 'وافق عليه النادي' && !hasTransaction)
                ElevatedButton(
                  onPressed: launchPayment,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('💳 الدفع الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              else if (!widget.isReviewMode)
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget previewAttachment(String title, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            child: Image.network(
              url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(8), child: Text('تعذر تحميل الصورة')),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUploadBox(String label, File? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: file == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.upload_file, size: 30, color: Colors.grey), Text(label, style: const TextStyle(color: Colors.grey))],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.check_circle, color: Colors.green, size: 30), Text('تم رفع $label', style: const TextStyle(fontWeight: FontWeight.bold))],
                ),
        ),
      ),
    );
  }

  TableRow tableRow(String label, dynamic value) {
    return TableRow(
      children: [
        Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text(value?.toString() ?? '-')),
      ],
    );
  }
}
