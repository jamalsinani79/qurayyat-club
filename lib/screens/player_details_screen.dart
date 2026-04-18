import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/team_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({super.key});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> with WidgetsBindingObserver {
  late Map<String, dynamic> player;
  bool isEditing = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController cardIdController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  File? newPlayerImg;
  File? newCardFront;
  File? newCardBack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ لمراقبة حالة التطبيق
    player = Get.arguments as Map<String, dynamic>;

    nameController.text = (player['name'] ?? '').toString();
    cardIdController.text = (player['card_id'] ?? '').toString();
    birthDateController.text = (player['birth_date'] ?? '').toString();
    locationController.text = (player['location'] ?? '').toString();
    phoneController.text = (player['phone'] ?? '').toString();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ إزالة المراقبة عند الانتهاء
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📲 التطبيق عاد من الخلفية، سيتم تحديث بيانات اللاعب');
      _loadPlayerData(); // ✅ تحديث البيانات عند العودة من الدفع
    }
  }

  Future<void> _loadPlayerData() async {
    final result = await TeamService.getPlayerByCardId(cardIdController.text);
    if (result['status']) {
      setState(() {
        player = result['info'];
        nameController.text = (player['name'] ?? '').toString();
        birthDateController.text = (player['birth_date'] ?? '').toString();
        locationController.text = (player['location'] ?? '').toString();
        phoneController.text = (player['phone'] ?? '').toString();
      });
    } else {
      print('❌ فشل في تحميل بيانات اللاعب: ${result['message']}');
    }
  }




  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text('طلب تسجيل لاعب', style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            ...[
              if (player['approve_status'] == 'draft')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildActionButton('إرسال للنادي', Colors.blue, Icons.send, onTap: () async {
                        final result = await TeamService.sendPlayerToClub(cardIdController.text);
                        if (result['status']) {
                          Get.snackbar('تم الإرسال', 'تم إرسال الطلب إلى النادي بنجاح');
                        } else {
                          Get.snackbar('خطأ', result['message'] ?? 'فشل في الإرسال');
                        }
                      }),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        isEditing ? 'إلغاء' : 'تعديل',
                        Colors.orange,
                        Icons.edit,
                        onTap: () {
                          setState(() {
                            isEditing = !isEditing;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton('حذف', Colors.red, Icons.delete, onTap: () {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.warning,
                          animType: AnimType.scale,
                          title: 'تأكيد الحذف',
                          desc: 'هل أنت متأكد أنك تريد حذف بيانات اللاعب "${nameController.text}"؟ سيتم حذف جميع مستنداته نهائيًا.',
                          btnCancelText: 'إلغاء',
                          btnCancelOnPress: () {},
                          btnOkText: 'نعم، حذف',
                          btnOkOnPress: () async {
                            final result = await TeamService.deletePlayer(cardIdController.text);
                            if (result['status']) {
                              Get.snackbar('تم الحذف', 'تم حذف اللاعب "${nameController.text}" بنجاح');
                              Navigator.pop(context);
                            } else {
                              Get.snackbar('خطأ', result['message'] ?? 'فشل في حذف اللاعب');
                            }
                          },
                        ).show();
                      }),
                    ],
                  ),
                ),
              if (player['approve_status'] == 'club_approve')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          Get.snackbar(
                            'جاري الإرسال',
                            'جاري إرسال رابط الدفع إلى البريد الإلكتروني...',
                          );

                          final success = await TeamService.sendPlayerPaymentLink(
                            player['card_id'].toString(),
                          );

                          if (success) {
                            Get.snackbar(
                              'تم بنجاح',
                              'تم إرسال رابط الدفع إلى البريد الإلكتروني ✅',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              'خطأ',
                              'تعذر إرسال الرابط ❌',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        } catch (e) {
                          print('🟥 Error: $e');
                          Get.snackbar('خطأ', 'حدث خطأ أثناء الإرسال');
                        }
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('إرسال رابط الدفع'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTextField('الرقم المدني', cardIdController),
                  _buildTextField('الاسم', nameController),
                  _buildTextField('تاريخ الميلاد', birthDateController),
                  _buildTextField('مكان القيد', locationController),
                  _buildTextField('رقم الهاتف', phoneController),
                  const SizedBox(height: 16),
                  _buildImageField('صورة اللاعب', player['player_img'], (file) => setState(() => newPlayerImg = file)),
                  _buildImageField('صورة البطاقة الأمامية', player['card_identy_front'], (file) => setState(() => newCardFront = file)),
                  _buildImageField('صورة البطاقة الخلفية', player['card_identy_back'], (file) => setState(() => newCardBack = file)),
                  const SizedBox(height: 16),
                  _buildSwitchTile('موافقة اللاعب', true),
                  _buildSwitchTile('موافقة أمين السر', true),
                  if (isEditing && player['approve_status'] == 'draft')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await TeamService.updatePlayer(
                            cardId: cardIdController.text,
                            name: nameController.text,
                            birthDate: birthDateController.text,
                            location: locationController.text,
                            phone: phoneController.text,
                            playerImg: newPlayerImg,
                            cardFront: newCardFront,
                            cardBack: newCardBack,
                          );

                          if (result['status']) {
                            Get.snackbar('تم الحفظ', 'تم تحديث بيانات اللاعب بنجاح');
                            setState(() => isEditing = false);
                          } else {
                            Get.snackbar('خطأ', result['message'] ?? 'فشل في التحديث');
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, {required VoidCallback onTap}) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: isEditing
            ? TextField(
                controller: controller,
                decoration: InputDecoration(labelText: label, border: InputBorder.none),
              )
            : ListTile(
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(controller.text),
              ),
      ),
    );
  }

  Widget _buildImageField(String label, String? imagePath, Function(File) onImageSelected) {
    final fullUrl = imagePath != null && imagePath.isNotEmpty
        ? 'https://teams.quriyatclub.net$imagePath'
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: fullUrl != null && !isEditing
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(fullUrl, width: 60, height: 60, fit: BoxFit.cover),
              )
            : (isEditing
                ? InkWell(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) onImageSelected(File(picked.path));
                    },
                    child: const Icon(Icons.upload_file, size: 40),
                  )
                : const Icon(Icons.image_not_supported)),
        subtitle: isEditing ? const Text('اضغط لاختيار صورة جديدة') : null,
      ),
    );
  }

  Widget _buildSwitchTile(String label, bool value) {
    return SwitchListTile(
      value: value,
      onChanged: (_) {},
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
