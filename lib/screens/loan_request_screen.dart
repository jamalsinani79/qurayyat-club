import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:get/get.dart';
import '../services/team_service.dart'; // تأكد من المسار الصحيح للخدمة

class LoanRequestScreen extends StatefulWidget {
  final Map player;

  const LoanRequestScreen({super.key, required this.player});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool termsAccepted = false;

  final intl.DateFormat formatter = intl.DateFormat('dd/MM/yyyy');

  Future<void> pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلب استعارة لاعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
  // 🟧 العنوان الأول: بيانات اللاعب
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.orange, Colors.deepOrange],
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'بيانات اللاعب',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
      textAlign: TextAlign.center,
    ),
  ),
  const SizedBox(height: 8),
  Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildInfoRow('اسم اللاعب', player['name']),
          buildInfoRow('الرقم المدني', player['card_id']),
          buildInfoRow('رقم القيد', player['register_number']),
          buildInfoRow('رقم الهاتف', player['phone']),
        ],
      ),
    ),
  ),
  const SizedBox(height: 24),

  // 🟧 العنوان الثاني: بيانات طلب الاستعارة
  Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.orange, Colors.deepOrange],
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'بيانات طلب الاستعارة',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
      textAlign: TextAlign.center,
    ),
  ),
  const SizedBox(height: 12),

  const Text('تاريخ البداية'),
  InkWell(
    onTap: () => pickDate(isStart: true),
    child: buildDateField(startDate),
  ),
  const SizedBox(height: 12),

  const Text('تاريخ النهاية'),
  InkWell(
    onTap: () => pickDate(isStart: false),
    child: buildDateField(endDate),
  ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: termsAccepted,
                      onChanged: (val) => setState(() => termsAccepted = val ?? false),
                      title: const Text('تأكيد الموافقة'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'نود إفادتكم بأنه لا مانع لدينا من قبول اللاعب المذكور أعلاه للمشاركة في هذه المسابقة وفق الفترة المحددة أعلاه. '
                      'وبعد انتهاء الفترة المذكورة يتم عودة اللاعب مباشرة إلى فريقه الأصلي دون قيد أو شرط وتعتبر الإعارة منتهية.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!termsAccepted || startDate == null || endDate == null) {
                      Get.snackbar(
                        'تنبيه',
                        'يرجى تعبئة كل الحقول والموافقة على الشروط',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                        margin: const EdgeInsets.all(12),
                        borderRadius: 8.0,
                      );
                      return;
                    }

                    final result = await TeamService.storeLoanRequest(
                      cardId: widget.player['card_id'].toString(),
                      startDate: intl.DateFormat('yyyy-MM-dd').format(startDate!),
                      endDate: intl.DateFormat('yyyy-MM-dd').format(endDate!),

                      note: 'طلب استعارة للمشاركة في البطولة المحددة',
                    );

                    if (result['status'] == true) {
                      Get.snackbar('تم الإرسال', 'تم إرسال الطلب بنجاح إلى الفريق الآخر',
                          backgroundColor: Colors.green, colorText: Colors.white);
                      Navigator.pop(context, true);
                    } else {
                      Get.snackbar('خطأ', result['message'] ?? 'فشل إرسال الطلب',
                          backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إرسال الطلب', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, dynamic value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text('$label: ${value ?? ''}', style: const TextStyle(fontSize: 14)),
    );
  }

  Widget buildDateField(DateTime? date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18),
          const SizedBox(width: 10),
          Text(date != null ? formatter.format(date) : 'يوم / شهر / سنة'),
        ],
      ),
    );
  }
}
