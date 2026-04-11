import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/assistant_service.dart';

class ViewAssistantScreen extends StatefulWidget {
  final Map<String, dynamic> assistant;
  const ViewAssistantScreen({super.key, required this.assistant});

  @override
  State<ViewAssistantScreen> createState() => _ViewAssistantScreenState();
}

class _ViewAssistantScreenState extends State<ViewAssistantScreen> {
  late TextEditingController nameController;
  late TextEditingController idController;
  late TextEditingController birthDateController;
  String? role;
  bool isEditMode = false;

  // ✅ خريطة تحويل الاسم العربي إلى الرقم المناسب
  final Map<String, String> _roleMap = {
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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.assistant['name']);
    idController = TextEditingController(text: widget.assistant['card_id'].toString());
    birthDateController = TextEditingController(text: widget.assistant['birthdate']);
    role = widget.assistant['role'];
  }

  void toggleEdit() => setState(() => isEditMode = !isEditMode);

  void deleteAssistant() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'تأكيد الحذف',
      desc: 'هل أنت متأكد أنك تريد حذف هذا العضو؟',
      btnCancelText: 'إلغاء',
      btnOkText: 'حذف',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final id = widget.assistant['id'];
        final result = await AssistantService.deleteAssistant(id);
        if (result['status'] == true) {
          Get.back();
          Get.snackbar('تم الحذف', 'تم حذف العضو بنجاح');
          Navigator.pop(context, true);
        } else {
          Get.snackbar('خطأ', result['message'] ?? 'فشل في الحذف');
        }
      },
    ).show();
  }

  void saveUpdates() async {
    final name = nameController.text.trim();
    final cardId = idController.text.trim();
    final birthDate = birthDateController.text.trim();
    final roleId = _roleMap[role ?? ''] ?? '';

    if (name.isEmpty || cardId.isEmpty || birthDate.isEmpty || roleId.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى تعبئة جميع الحقول');
      return;
    }

    final result = await AssistantService.updateAssistant(
      technicalId: widget.assistant['id'],
      cardId: cardId,
      name: name,
      birthDate: birthDate,
      role: roleId,
    );

    if (result['status'] == true) {
      Get.snackbar('تم الحفظ', 'تم تعديل بيانات العضو بنجاح');
      setState(() => isEditMode = false);
      Navigator.pop(context, true);
    } else {
      Get.snackbar('خطأ', result['message'] ?? 'فشل في حفظ التعديلات');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = widget.assistant['sport_image'] != null
        ? 'https://teams.quriyatclub.net/${widget.assistant['sport_image']}'
        : null;

    final String? cardUrl = widget.assistant['front_image'] != null
        ? 'https://teams.quriyatclub.net/${widget.assistant['front_image']}'
        : null;

    return Directionality(
  textDirection: TextDirection.rtl,
  child: Scaffold(
    appBar: AppBar(
      centerTitle: true, // ✅ يجعل العنوان في المنتصف
      title: const Text(
        'بيانات العضو',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black), // ✅ لون برتقالي
        onPressed: () {
          Navigator.pop(context, isEditMode ? true : false);
        },
      ),
      actions: [
        if (isEditMode)
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: saveUpdates,
          ),
        IconButton(
          icon: Icon(
            isEditMode ? Icons.cancel : Icons.edit,
            color: Colors.grey[800],
          ),
          onPressed: toggleEdit,
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.grey[800] ?? Colors.black,
          ),
          onPressed: deleteAssistant,
        ),
      ],
    ),



        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (imageUrl != null)
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(imageUrl),
                    onBackgroundImageError: (_, __) =>
                        const Icon(Icons.person, size: 50),
                  ),
                ),
              const SizedBox(height: 24),

              _sectionHeader('بيانات العضو'),

              buildTextField('الاسم', nameController, isEditMode),
              buildTextField('الرقم المدني', idController, isEditMode),
              buildTextField('تاريخ الميلاد', birthDateController, isEditMode),
              const SizedBox(height: 12),

              isEditMode
                  ? DropdownButtonFormField<String>(
                      value: role,
                      decoration: InputDecoration(
                        labelText: 'الصفة',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _roleMap.keys
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) => setState(() => role = val),
                    )
                  : buildTextField('الصفة', TextEditingController(text: role), false),

              const SizedBox(height: 24),

              _sectionHeader('المرفقات'),

              _buildImageBox('البطاقة الشخصية', cardUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildImageBox(String label, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 50, color: Colors.grey,),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
