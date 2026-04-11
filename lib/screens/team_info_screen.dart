import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_model.dart';
import '../services/team_service.dart';

class TeamInfoScreen extends StatefulWidget {
  const TeamInfoScreen({super.key});

  @override
  State<TeamInfoScreen> createState() => _TeamInfoScreenState();
}

class _TeamInfoScreenState extends State<TeamInfoScreen> {
  TeamModel? team;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeamInfo();
  }

  Future<void> loadTeamInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final result = await TeamService.fetchTeamInfo(token);
    setState(() {
      team = result;
      isLoading = false;
    });
  }

  Widget buildInfoCard(String title, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange), // ✅ أيقونة برتقالية
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    value.isNotEmpty ? value : '-',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('بيانات الفريق'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  buildInfoCard('اسم المستخدم', team?.userFullname ?? '', Icons.person),
                  buildInfoCard('البريد الإلكتروني', team?.email ?? '', Icons.email),
                  buildInfoCard('رقم الجوال', team?.phone ?? '', Icons.phone),
                  buildInfoCard('رمز رسائل الفريق', team?.messageCode ?? '', Icons.message),
                  buildInfoCard('وصف الفريق', team?.description ?? '', Icons.info),

                  const SizedBox(height: 50), // مسافة علوية قبل الشعار

                  if (team?.logo != null && team!.logo.isNotEmpty)
                    Center(
                      child: Image.network(
                        team!.logo,
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          '⚠️ فشل تحميل الشعار',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40), // مسافة سفلية بعد الشعار
                ],
              ),
            ),
    ),
  );
}
}