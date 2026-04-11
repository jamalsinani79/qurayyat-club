import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:another_flushbar/flushbar.dart'; 
import '../services/team_message_service.dart';

class NewTeamMessageScreen extends StatefulWidget {
  const NewTeamMessageScreen({super.key});

  @override
  State<NewTeamMessageScreen> createState() => _NewTeamMessageScreenState();
}

class _NewTeamMessageScreenState extends State<NewTeamMessageScreen> {
  String? selectedTeam;
  String? selectedTarget;
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  File? attachedFile;
  bool isSending = false;
  bool isLoading = true;
  
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> receivers = [];
  
  final List<Map<String, dynamic>> targets = [
    {'id': 1, 'label': 'رئيس الفريق'},
    {'id': 2, 'label': 'أمين سر الفريق'},
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final fetchedTeams = await TeamMessageService.fetchAvailableTeams();
    
    setState(() {
      teams = fetchedTeams;
      
      isLoading = false;
    });
  }

  Future<void> pickFile() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() => attachedFile = File(result.path));
    }
  }

  Future<void> submitMessage() async {
  if (selectedTeam == null || selectedTarget == null || titleController.text.isEmpty || messageController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("يرجى تعبئة جميع الحقول")),
    );
    return;
  }

  setState(() => isSending = true);

  final response = await TeamMessageService.sendMessage(
    subject: titleController.text,
    body: messageController.text,
    team: selectedTeam!,
    target: int.parse(selectedTarget!),
    file: attachedFile,
  );

  setState(() => isSending = false);

  await Flushbar(
    title: response['status'] ? 'تم الإرسال بنجاح' : 'حدث خطأ',
    message: response['message'],
    duration: const Duration(seconds: 3),
    backgroundColor: response['status'] ? Colors.green : Colors.red,
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(12),
    flushbarPosition: FlushbarPosition.TOP,
    icon: Icon(
      response['status'] ? Icons.check_circle : Icons.error,
      color: Colors.white,
    ),
  ).show(context);

  if (response['status']) {
    Navigator.pop(context, true);
  }
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إرسال رسالة إلى فريق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('👥 اختر الفريق', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTeam,
                      hint: const Text('اختر الفريق'),
                      items: teams.map((team) {
                        return DropdownMenuItem(
                          value: team['id'].toString(),
                          child: Text(team['name'] ?? 'غير معروف'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedTeam = val),
                    ),
    
                    const SizedBox(height: 16),

                    const Text('📩 المرسل إليه', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTarget,
                      hint: const Text('اختر المرسل إليه'),
                      items: targets.map((role) {
                      return DropdownMenuItem(
                      value: role['id'].toString(),
                       child: Text(role['label'] ?? 'غير معروف'),
                        );
                          }).toList(),
                      onChanged: (val) => setState(() => selectedTarget = val),
                    ),
                    const SizedBox(height: 16),

                    const Text('📌 العنوان', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'اكتب عنوان الرسالة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('📎 ملف مرفق', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: pickFile,
                      child: Text(
                        attachedFile == null ? 'ارفع المرفق...' : '✅ تم اختيار الملف',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                    const SizedBox(height: 16),

                    const Text('📝 الرسالة', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: messageController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'اكتب نص الرسالة هنا...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: isSending ? null : submitMessage,
                      icon: const Icon(Icons.send, size: 20, color: Colors.white),
                      label: const Text('إرسال الرسالة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
