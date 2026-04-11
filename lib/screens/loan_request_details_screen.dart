import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../services/team_service.dart';

class LoanRequestDetailsScreen extends StatefulWidget {
  final Map request;
  final bool isSent;

  const LoanRequestDetailsScreen({
    super.key,
    required this.request,
    required this.isSent,
  });

  @override
  State<LoanRequestDetailsScreen> createState() => _LoanRequestDetailsScreenState();
}

class _LoanRequestDetailsScreenState extends State<LoanRequestDetailsScreen>
    with WidgetsBindingObserver {
  bool decisionMade = false;
  bool? isApproved;
  bool secondConsent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshRequest();
    }
  }

  Future<void> refreshRequest() async {
    final newRequest =
        await TeamService.fetchLoanRequestDetails(widget.request['id'].toString());
    if (newRequest != null && mounted) {
      setState(() {
        widget.request.clear();
        widget.request.addAll(newRequest);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isSent = widget.isSent;
    final player = req['player'] ?? {};
    final basicTeam = req['basic']?['name'] ?? 'الفريق الأساسي';
    final senderTeam = req['sender']?['name'] ?? 'الفريق المرسل';
    final start = req['start'] ?? 'غير محدد';
    final end = req['end'] ?? 'غير محدد';
    final note = req['note'] ?? 'لا توجد ملاحظات';
    final requestDate = req['created_at_formatted'] ?? req['created_at'] ?? '---';
    final String status = req['status'] ?? '';

    final bool isSendToBasic = status == 'مرسل الى الفريق الاساسي';
    final bool isApprovedByBasic = status == 'وافق عليه الفريق الاساسي';
    final bool isClubApproved = status == 'وافق عليه النادي';
    final bool isDoneOrExpired = status == 'جارية' || status == 'منتهي';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل طلب الإعارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🟧 عنوان بيانات اللاعب
              sectionHeader('بيانات اللاعب'),
              const SizedBox(height: 8),
              buildInfo('اسم اللاعب', player['name']),
              buildInfo('الرقم المدني', player['card_id']),
              buildInfo('رقم القيد', player['register_number']),
              buildInfo('رقم الهاتف', player['phone']),
              const SizedBox(height: 24),

              // 🟧 عنوان بيانات الطلب
              sectionHeader('بيانات الطلب'),
              const SizedBox(height: 8),
              buildInfo('تاريخ الطلب', requestDate),
              buildInfo('تاريخ الإعارة', 'من $start إلى $end'),
              buildInfo('الفريق المرسل', senderTeam),
              buildInfo('الفريق الأساسي', basicTeam),
              buildInfo('ملاحظات', note),
              buildInfo('الحالة', status),

              const SizedBox(height: 24),
              const Text(
                'نود إفادتكم بأنه لا مانع لدينا من قبول اللاعب المذكور أعلاه للمشاركة في هذه المسابقة وفق الفترة المحددة أعلاه. '
                'وبعد انتهاء الفترة المذكورة يتم عودة اللاعب مباشرة إلى فريقه الأصلي دون قيد أو شرط وتعتبر الإعارة منتهية.',
                style: TextStyle(fontSize: 13),
              ),

              if (isApprovedByBasic)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'بناءً على طلب الفريق أعلاه، فإنه لا مانع لدينا من إعارة اللاعب وفق المدة المشار إليها أعلاه، '
                    'وأنه لا يخضع حاليًا لأي عقوبات رياضية أو توقيف صادر من النادي، كما أن البيانات الموضحة صحيحة وعليه أعطيت له هذه الشهادة.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),

              const SizedBox(height: 16),

              if (isSendToBasic && !isSent)
                CheckboxListTile(
                  value: secondConsent,
                  onChanged: decisionMade
                      ? null
                      : (val) => setState(() => secondConsent = val ?? false),
                  title: const Text(
                    'بناءً على طلب الفريق أعلاه، فإنه لا مانع لدينا من إعارة اللاعب وفق المدة المشار إليها أعلاه، '
                    'وأنه لا يخضع حاليًا لأي عقوبات رياضية أو توقيف صادر من النادي، كما أن البيانات الموضحة صحيحة وعليه أعطيت له هذه الشهادة',
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.orange,
                ),

              if (isSendToBasic && !isSent)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: decisionMade || !secondConsent
                            ? null
                            : () async {
                                final success = await TeamService.approveLoanRequest(req['id']);
                                if (success) {
                                  setState(() {
                                    decisionMade = true;
                                    isApproved = true;
                                  });
                                  Get.snackbar('تم القبول', 'تمت الموافقة على الطلب ✅',
                                      backgroundColor: Colors.green, colorText: Colors.white);
                                  await Future.delayed(const Duration(seconds: 1));
                                  Get.back(result: true);
                                } else {
                                  Get.snackbar('خطأ', 'تعذر إرسال الموافقة، حاول مرة أخرى',
                                      backgroundColor: Colors.red.shade700, colorText: Colors.white);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('الموافقة', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: decisionMade
                            ? null
                            : () async {
                                final success = await TeamService.rejectLoanRequest(req['id']);
                                if (success) {
                                  setState(() {
                                    decisionMade = true;
                                    isApproved = false;
                                  });
                                  Get.snackbar('تم الرفض', 'تم إرسال الرفض بنجاح ❌',
                                      backgroundColor: Colors.red, colorText: Colors.white);
                                  await Future.delayed(const Duration(seconds: 1));
                                  Get.back(result: true);
                                } else {
                                  Get.snackbar('خطأ', 'تعذر إرسال الرفض، حاول مرة أخرى',
                                      backgroundColor: Colors.red.shade700, colorText: Colors.white);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('رفض', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),

              if (isClubApproved && isSent && !isDoneOrExpired)
                ElevatedButton.icon(
                  onPressed: () async {
                    final requestId = req['id'];
                    if (requestId == null) {
                      Get.snackbar('خطأ', 'رقم الطلب غير متوفر');
                      return;
                    }

                    Get.snackbar('جاري التحميل', 'جاري إنشاء رابط الدفع...',
                        backgroundColor: Colors.blue, colorText: Colors.white);

                    final url = await TeamService.generateLoanPaymentUrl(requestId.toString());
                    if (url != null && await launcher.canLaunchUrl(Uri.parse(url))) {
                      await launcher.launchUrl(Uri.parse(url),
                          mode: launcher.LaunchMode.externalApplication);
                    } else {
                      Get.snackbar('خطأ', 'تعذر فتح رابط الدفع',
                          backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text(
                    'الدفع',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),

              if (isDoneOrExpired || (isClubApproved && !isSent))
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'هذا الطلب لا يتطلب أي إجراء حالياً، وهو معروض للعلم فقط.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfo(String label, dynamic value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text('$label: ${value ?? ''}', style: const TextStyle(fontSize: 14)),
    );
  }

  Widget sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
