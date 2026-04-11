import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart';

import '../services/loan_out_service.dart';

class AddLoanOutPlayerScreen extends StatefulWidget {
  const AddLoanOutPlayerScreen({super.key});

  @override
  State<AddLoanOutPlayerScreen> createState() => _AddLoanOutPlayerScreenState();
}

class _AddLoanOutPlayerScreenState extends State<AddLoanOutPlayerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController cardIdController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  File? sportImage;
  File? frontImage;
  File? letterImage;

 Future<void> showTopMessage(String message, {bool isError = false}) async {
  await Flushbar(
    message: message,
    duration: const Duration(seconds: 2),
    backgroundColor: isError ? Colors.red : Colors.green,
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(8),
    flushbarPosition: FlushbarPosition.TOP,
  ).show(context);
}


  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> _pickImage(Function(File) onSelected) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      onSelected(File(picked.path));
    }
  }

  Widget _imagePickerTile(String label, File? imageFile, VoidCallback onTap, {String? imagePathFromServer}) {
  final String? imageUrl = imagePathFromServer != null
      ? 'https://teams.quriyatclub.net/$imagePathFromServer'
      : null;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: imageFile != null ? Colors.green[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: imageFile != null ? Colors.green : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                imageFile != null || imageUrl != null ? "تم اختيار صورة" : "صورة",
                style: const TextStyle(fontSize: 14),
              ),
              Icon(
                Icons.cloud_upload_outlined,
                color: imageFile != null ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ),

      // صورة من الملف المحلي
      if (imageFile != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              imageFile,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),

      // صورة من الإنترنت (إذا لم تكن الصورة المحلية موجودة)
      if (imageFile == null && imageUrl != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),

      const SizedBox(height: 16),
    ],
  );
}


@override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'إضافة لاعب معار خارجيًا',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomFormField(label: 'الرقم المدني', controller: cardIdController),
              CustomFormField(label: 'الاسم', controller: nameController),
              CustomFormField(
                label: 'تاريخ الميلاد',
                controller: birthDateController,
                isDate: true,
                onTap: () => _pickDate(birthDateController),
              ),
              CustomFormField(
                label: 'تاريخ البداية',
                controller: startDateController,
                isDate: true,
                onTap: () => _pickDate(startDateController),
              ),
              CustomFormField(
                label: 'تاريخ النهاية',
                controller: endDateController,
                isDate: true,
                onTap: () => _pickDate(endDateController),
              ),
              _imagePickerTile('الصورة الرياضية', sportImage, () {
               _pickImage((file) => setState(() => sportImage = file));
               }),
              _imagePickerTile('صورة البطاقة الأمامية', frontImage, () {
               _pickImage((file) => setState(() => frontImage = file));
               }),
              _imagePickerTile('رسالة الإعارة', letterImage, () {
                _pickImage((file) => setState(() => letterImage = file));
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (sportImage == null || frontImage == null || letterImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى اختيار كل الصور المطلوبة')),
                        );
                        return;
                      }

                      // تحويل dd/MM/yyyy إلى yyyy-MM-dd
                      String formatDate(String dateStr) {
                        final parts = dateStr.split('/');
                        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
                      }

                      try {
                        final success = await LoanOutService.addLoanOutPlayer(
                          cardId: cardIdController.text.trim(),
                          name: nameController.text.trim(),
                          birthDate: formatDate(birthDateController.text),
                          startDate: formatDate(startDateController.text),
                          endDate: formatDate(endDateController.text),
                          sportImage: sportImage!,
                          frontImage: frontImage!,
                          letterImage: letterImage!,
                        );

                        if (success) {
                          await showTopMessage('✅ تم حفظ الطلب بنجاح .. بانتظار الارسال');
                          Navigator.pop(context, true);                          
                        } else {
                          showTopMessage('❌ فشل في إرسال الطلب', isError: true);
                        }
                      } catch (e) {
                        print('❌ خطأ أثناء الإرسال: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('حدث خطأ أثناء الإرسال')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
// ويدجيت مخصص لحقل الإدخال مع دعم التواريخ والتحكم بالارتفاع
class CustomFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDate;
  final VoidCallback? onTap;
  final double height;

  const CustomFormField({
    super.key,
    required this.label,
    required this.controller,
    this.isDate = false,
    this.onTap,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: isDate ? onTap : null,
            child: AbsorbPointer(
              absorbing: isDate,
              child: SizedBox(
                height: height,
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
