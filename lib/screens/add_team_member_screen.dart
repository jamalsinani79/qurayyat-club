import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart';
import '../services/assistant_service.dart';
import '../screens/assistant_screen.dart'; 
class AddTeamMemberScreen extends StatefulWidget {
  const AddTeamMemberScreen({super.key});

  @override
  State<AddTeamMemberScreen> createState() => _AddTeamMemberScreenState();
}

class _AddTeamMemberScreenState extends State<AddTeamMemberScreen> {
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  String? selectedRole;
  bool isLoading = false;

  final List<String> roles = [
    'مدرب',
    'مساعد مدرب',
    'اخصائي علاج',
    'مدير الفريق',
    'اداري',
    'مدرب الحراس',
    'مسؤول مهمات',
    'إعلامي',
    'مسؤول الجماهير',
    'مدرب لياقة بدنية',
    'مدلك',
  ];

  final Map<String, String> roleMap = {
    'مدرب': '1',
    'مساعد مدرب': '2',
    'اخصائي علاج': '3',
    'مدير الفريق': '4',
    'اداري': '5',
    'مدرب الحراس': '6',
    'مسؤول مهمات': '7',
    'إعلامي': '8',
    'مسؤول الجماهير': '9',
    'مدرب لياقة بدنية': '10',
    'مدلك': '11',
  };

  File? sportImageFile;
  File? idCardImageFile;
  final picker = ImagePicker();

  Future<void> pickImage(bool isSportImage) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        if (isSportImage) {
          sportImageFile = File(pickedFile.path);
        } else {
          idCardImageFile = File(pickedFile.path);
        }
      });
    }
  }

  void submit() async {
    setState(() => isLoading = true);

    final nationalId = nationalIdController.text.trim();
    final name = nameController.text.trim();
    final birthDate = birthDateController.text.trim();
    final role = roleMap[selectedRole] ?? '';

    if (nationalId.isEmpty || name.isEmpty || birthDate.isEmpty || role.isEmpty) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }

    if (sportImageFile == null || idCardImageFile == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحميل كلتا الصورتين')),
      );
      return;
    }

    final result = await AssistantService.addAssistant(
      cardId: nationalId,
      name: name,
      birthDate: birthDate,
      role: role,
      startDate: '', // تم تجاهلهم
      endDate: '',
      sportImage: sportImageFile!,
      frontImage: idCardImageFile!,
    );

    setState(() => isLoading = false);

    if (result['status'] == true) {
      Flushbar(
        message: 'تمت الإضافة بنجاح ✅',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(10),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      ).show(context);
      await Future.delayed(const Duration(milliseconds: 800));
      Get.off(() => const AssistantScreen());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'فشل في الإضافة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة عضو جديد'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionHeader('بيانات العضو'),

              textFieldBox('الاسم', nameController, TextInputType.text),
              textFieldBox('الرقم المدني', nationalIdController, TextInputType.number),

              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    birthDateController.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
                child: AbsorbPointer(
                  child: textFieldBox('تاريخ الميلاد', birthDateController, TextInputType.datetime),
                ),
              ),

              const SizedBox(height: 12),
              dropDownBox(),

              const SizedBox(height: 20),
              sectionHeader('صور العضو'),

              fileUploadBox(
                label: sportImageFile == null ? 'تحميل صورة رياضية' : '✅ تم اختيار الصورة',
                icon: Icons.image,
                onTap: () => pickImage(true),
              ),

              const SizedBox(height: 8),
              fileUploadBox(
                label: idCardImageFile == null ? 'تحميل البطاقة الشخصية' : '✅ تم اختيار البطاقة',
                icon: Icons.credit_card,
                onTap: () => pickImage(false),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading ? null : submit,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('إرسال', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget textFieldBox(String label, TextEditingController controller, TextInputType type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget dropDownBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedRole,
          hint: const Text('اختر الصفة'),
          onChanged: (val) => setState(() => selectedRole = val),
          items: roles.map((r) {
            return DropdownMenuItem(
              value: r,
              child: Text(r),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget fileUploadBox({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
