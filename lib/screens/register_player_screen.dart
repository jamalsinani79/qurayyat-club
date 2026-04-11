
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPlayerScreen extends StatefulWidget {
  const RegisterPlayerScreen({super.key});

  @override
  State<RegisterPlayerScreen> createState() => _RegisterPlayerScreenState();
}

class _RegisterPlayerScreenState extends State<RegisterPlayerScreen> {
  final TextEditingController cardIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isUnder16 = false;
  bool isSubmitting = false;
  bool playerApproval = false;
  bool teamApproval = false;

  XFile? playerImage;
  XFile? frontCardImage;
  XFile? backCardImage;
  XFile? birthDoc;
  XFile? fatherCheckDoc;
  XFile? fatherIdCard;

  final ImagePicker picker = ImagePicker();

  Future<void> pickImage(Function(XFile file) onSelected) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) onSelected(picked);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> submitPlayer() async {
    if (!playerApproval || !teamApproval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى الموافقة على التصريحات')),
      );
      return;
    }

    if (playerImage == null || frontCardImage == null || backCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحميل جميع الصور المطلوبة')),
      );
      return;
    }

    if (isUnder16 && (birthDoc == null || fatherCheckDoc == null || fatherIdCard == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى رفع مستندات ولي الأمر')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    final token = await getToken();
    final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/player/store');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['card_id'] = cardIdController.text;
    request.fields['name'] = nameController.text;
    request.fields['birth_date'] = birthDateController.text;
    request.fields['location'] = locationController.text;
    request.fields['phone'] = phoneController.text;
    request.fields['player_accept'] = '1';
    request.fields['team_accept'] = '1';

    request.files.add(await fileToMultipart(playerImage!, 'player_img'));
    request.files.add(await fileToMultipart(frontCardImage!, 'card_identy_front'));
    request.files.add(await fileToMultipart(backCardImage!, 'card_identy_back'));

    if (isUnder16) {
      request.files.add(await fileToMultipart(birthDoc!, 'birth_doc'));
      request.files.add(await fileToMultipart(fatherCheckDoc!, 'father_check_doc'));
      request.files.add(await fileToMultipart(fatherIdCard!, 'father_identy_card'));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    setState(() => isSubmitting = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل اللاعب بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التسجيل: ${response.reasonPhrase}')),
      );
    }
  }

  Future<http.MultipartFile> fileToMultipart(XFile file, String fieldName) async {
    final bytes = await file.readAsBytes();
    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: p.basename(file.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل اللاعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLabelledField('الرقم المدني', cardIdController),
            _buildLabelledField('الاسم', nameController),
            _buildLabelledField(
              'تاريخ الميلاد',
              birthDateController,
              readOnly: true,
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2010),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                  locale: const Locale('ar'),
                );
                if (pickedDate != null) {
                  birthDateController.text = pickedDate.toLocal().toString().split(' ')[0];
                  final age = DateTime.now().difference(pickedDate).inDays ~/ 365;
                  setState(() => isUnder16 = age < 16);
                }
              },
            ),
            _buildLabelledField('مكان الإقامة', locationController),
            _buildLabelledField('رقم الهاتف', phoneController),
            _buildUploadBox('صورة اللاعب', playerImage, (img) => setState(() => playerImage = img)),
            _buildUploadBox('صورة البطاقة الشخصية الوجه الأمامي', frontCardImage, (img) => setState(() => frontCardImage = img)),
            _buildUploadBox('صورة البطاقة الشخصية الوجه الخلفي', backCardImage, (img) => setState(() => backCardImage = img)),
            if (isUnder16) ...[
              const Divider(),
              const Text('مستندات ولي الأمر', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildUploadBox('شهادة الميلاد', birthDoc, (img) => setState(() => birthDoc = img)),
              _buildUploadBox('إقرار ولي الأمر', fatherCheckDoc, (img) => setState(() => fatherCheckDoc = img)),
              _buildUploadBox('هوية ولي الأمر', fatherIdCard, (img) => setState(() => fatherIdCard = img)),
            ],

            // الموافقة - اللاعب
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('موافقة اللاعب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text('أوافق أنا اللاعب المسجل أعلاه أن البيانات الواردة صحيحة، وإني غير مسجل في أي فريق آخر.', style: TextStyle(fontSize: 13)),
                    CheckboxListTile(
                      value: playerApproval,
                      onChanged: (val) => setState(() => playerApproval = val!),
                      title: const Text('أوافق', style: TextStyle(fontSize: 14)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            // الموافقة - أمين السر
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('موافقة أمين السر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text('أوافق أنا أمين سر الفريق على انضمام اللاعب المذكور أعلاه وأن كافة البيانات صحيحة، ويتحمل الفريق المسؤولية الكاملة إذا ثبت خلاف ذلك.', style: TextStyle(fontSize: 13)),
                    CheckboxListTile(
                      value: teamApproval,
                      onChanged: (val) => setState(() => teamApproval = val!),
                      title: const Text('أوافق', style: TextStyle(fontSize: 14)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('تسجيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelledField(String label, TextEditingController controller, {
    Function(String)? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUploadBox(String title, XFile? file, Function(XFile) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => pickImage(onPicked),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(file != null ? '✅ تم التحميل' : 'تحميل', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
