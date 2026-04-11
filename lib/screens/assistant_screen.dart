import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../services/assistant_service.dart';
import 'add_team_member_screen.dart';
import 'view_assistant_screen.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  List<Map<String, dynamic>> staffMembers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AssistantService.fetchAssistants();
      if (result['status'] == true) {
        setState(() {
          staffMembers = List<Map<String, dynamic>>.from(result['info']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'فشل في تحميل البيانات';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الجهاز الفني'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : staffMembers.isEmpty
                      ? const Center(child: Text('لا يتوفر بيانات'))
                      : ListView.builder(
  itemCount: staffMembers.length,
  itemBuilder: (context, index) {
    final member = staffMembers[index];
    return GestureDetector(
      onTap: () {
        Get.to(() => ViewAssistantScreen(assistant: member))?.then((result) {
          if (result == true) {
            fetchData(); // ✅ هذا التحديث يعمل دائمًا
          }
        });
      },
      child: _buildAssistantCard(member),
    );
  },
),

        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Get.to(() => const AddTeamMemberScreen(),
                transition: Transition.cupertino);
            if (result == true) {
              fetchData();
            }
          },
          backgroundColor: Colors.red,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'إضافة عضو',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantCard(Map member) {
    final name = member['name'] ?? 'بدون اسم';
    final role = member['role'] ?? 'بدون صفة';
    final cardId = member['card_id']?.toString() ?? '---';
    final birthDateRaw = member['birthdate'] ?? '';
    final imageUrl = member['sport_image'] != null
        ? 'https://teams.quriyatclub.net/${member['sport_image']}'
        : null;

    String formattedBirthDate = birthDateRaw;
    try {
      final parsed = DateTime.parse(birthDateRaw);
      formattedBirthDate =
          intl.DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {}

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFA726),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 30), // لحجز مكان الشارة

                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),

                      ClipOval(
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person,
                                        size: 40, color: Colors.white),
                              )
                            : const Icon(Icons.person,
                                size: 40, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('الصفة',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text('تاريخ الميلاد',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text('الرقم المدني',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dataContainer(role),
                  _dataContainer(formattedBirthDate),
                  _dataContainer(cardId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataContainer(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
