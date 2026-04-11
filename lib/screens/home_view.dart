import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:quriyat_club/services/auth_service.dart';
import 'package:quriyat_club/screens/notifications_screen.dart';
import '../widgets/app_drawer.dart';
import 'package:quriyat_club/screens/register_player_screen.dart';
import 'package:quriyat_club/screens/transfer_requests_screen.dart';
import 'package:quriyat_club/screens/borrow_requests_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String teamName = '...';
  String logoUrl = '';
  int playersCount = 0;
  int transferCount = 0;
  int loanCount = 0;
  int messageCount = 0;
  int unreadNotificationCount = 0;
  bool isLoading = true;
  String lastUpdate = '';

  int affiliatedPlayers = 0;
  int unjoinedPlayers = 0;
  int loanedPlayers = 0;
  int stoppedPlayers = 0;

  // ✅ حالات الفتح والإغلاق
  bool isRegisterOpen = false;
  bool isLoanOpen = false;
  bool isTransferOpen = false;
  bool isInternalLoanOpen = false;
  bool isRenewed = true;
  bool isExpired = false;
  bool isRenewalLoaded = false;

  @override
  void initState() {
    super.initState();
    //_getFcmToken();
    fetchTeamData();
    fetchUnreadNotificationCount();
    fetchPlayerStatusCounts();
    fetchRequestStatuses(); // ✅ جلب حالة الطلبات
    fetchRenewalStatus();
  }

  Future<void> fetchRenewalStatus() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/team/renewal-status-v2'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (!mounted) return;

        // ✅ أولاً: تحديث الواجهة
        setState(() {
          isRenewed = data['is_renewed'] ?? false;
          isExpired = data['is_expired'] ?? false;
          isRenewalLoaded = true;
        });

        // ✅ ثانياً: حفظ القيم
        await prefs.setBool('is_renewed', data['is_renewed']);
        await prefs.setBool('is_expired', data['is_expired']);

        print('🔥 isRenewed: ${data['is_renewed']} | isExpired: ${data['is_expired']}');
        print('🔥 renewal_status: ${data['renewal_status']}');
      }
    } else {
      print('⚠️ فشل في جلب renewalStatus: ${response.body}');
    }
  } catch (e) {
    print('💥 خطأ في renewalStatus: $e');
  }
}

  Future<void> fetchRequestStatuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('https://teams.quriyatclub.net/api/v1/club/request-statuses'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == true) {
            final info = data['info'];
            if (!mounted) return;
            setState(() {
              isRegisterOpen = info['create_player_status'] == 'on';
              isLoanOpen = info['loan_status'] == 'on';
              isTransferOpen = info['transfer_status'] == 'on';
              isInternalLoanOpen = info['internal_transfer_status'] == 'on';
              isRenewalLoaded = true;
            });
          }
        }
      }
    } catch (e) {
      print('💥 خطأ أثناء جلب حالة الطلبات: $e');
    }
  }

  void _getFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('📱 FCM Token الحقيقي: $token');
        final prefs = await SharedPreferences.getInstance();
        final authToken = prefs.getString('auth_token');
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl}/save-fcm-token'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
          body: {'fcm_token': token},
        );

        if (response.statusCode == 200) {
          print('✅ تم حفظ FCM token بنجاح في السيرفر');
        } else {
          print('⚠️ فشل في حفظ FCM token: ${response.body}');
        }
      }
    } catch (e) {
      print('💥 خطأ أثناء إرسال FCM token: $e');
    }
  }

  Future<void> fetchTeamData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/team'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        final info = data['info'];
        setState(() {
          teamName = info['name'] ?? 'غير معروف';
          logoUrl = 'https://teams.quriyatclub.net${info['logo'] ?? ''}';
          playersCount = info['active_players_count'] ?? 0;
          transferCount = info['transfer_players_count'] ?? 0;
          loanCount = info['loan_players_count'] ?? 0;
          messageCount = info['messages_count'] ?? 0;
          lastUpdate = info['last_update'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('💥 خطأ أثناء جلب بيانات الفريق: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final readIds = prefs.getStringList('read_notifications') ?? [];

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List notifications = data['info']['data'];
        final serverUnread = notifications
            .where((n) => n['status'] == 0)
            .map((n) => n['id'].toString())
            .toList();
        final realUnread =
            serverUnread.where((id) => !readIds.contains(id)).length;

        if (!mounted) return;
        setState(() {
          unreadNotificationCount = realUnread;
        });
      }
    } catch (e) {
      print('💥 خطأ أثناء جلب عدد الإشعارات: $e');
    }
  }

  Future<void> fetchPlayerStatusCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/players/count-statuses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final info = data['info'];
        if (!mounted) return;
        setState(() {
          affiliatedPlayers = info['منتسب'] ?? 0;
          loanedPlayers = info['معار'] ?? 0;
          stoppedPlayers = info['موقوف'] ?? 0;
          unjoinedPlayers = info['غير منتسب'] ?? 0;
        });
      }
    } catch (e) {
      print('💥 خطأ أثناء جلب عدد حالات اللاعبين: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffcfcfc),
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: const Text('الرئيسية', style: TextStyle(color: Colors.black)),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ).then((_) {
                  fetchUnreadNotificationCount();
                });
              },
            ),
            if (unreadNotificationCount > 0)
              Positioned(
                right: 4,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 10, minHeight: 15),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '$unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('فريق $teamName',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            const SizedBox(height: 2),
                            const Text('نادي قريات',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundImage: logoUrl.isNotEmpty
                            ? NetworkImage(logoUrl)
                            : const AssetImage('assets/images/logo.png')
                                as ImageProvider,
                        radius: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xfff7f8fa),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoCard(
                            title: 'مراسلات',
                            icon: Icons.mail_outline,
                            count: messageCount),
                        _InfoCard(
                            title: 'طلبات نقل',
                            icon: Icons.sync_alt,
                            count: transferCount),
                        _InfoCard(
                            title: 'طلبات استعارة',
                            icon: Icons.compare_arrows,
                            count: loanCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  PlayerStatsBox(
                    affiliated: affiliatedPlayers,
                    unjoined: unjoinedPlayers,
                    loaned: loanedPlayers,
                    stopped: stoppedPlayers,
                  ),
                  const SizedBox(height: 12),
                  const Text('الخدمات السريعة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      textDirection: TextDirection.rtl),
                  const SizedBox(height: 8),
                  if (!isRenewalLoaded)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickActionButton(
                        icon: Icons.person_add,
                        label: 'تسجيل لاعب',
                        color: Colors.green,
                        isEnabled: isRegisterOpen && isRenewed,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPlayerScreen()),
                        ),
                      ),
                      _QuickActionButton(
                        icon: Icons.sync_alt,
                        label: 'طلب نقل',
                        color: Colors.orange,
                        isEnabled: isTransferOpen && isRenewed,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TransferRequestsScreen()),
                        ),
                      ),
                      _QuickActionButton(
                        icon: Icons.compare_arrows,
                        label: 'طلب استعارة',
                        color: Colors.blue,
                        isEnabled: isLoanOpen && isRenewed,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BorrowRequestsScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  const _InfoCard(
      {required this.title, required this.icon, required this.count});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(height: 8),
        Text('$count',
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class PlayerStatsBox extends StatelessWidget {
  final int affiliated;
  final int unjoined;
  final int loaned;
  final int stopped;
  const PlayerStatsBox(
      {super.key,
      required this.affiliated,
      required this.unjoined,
      required this.loaned,
      required this.stopped});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('عدد اللاعبين',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatItem('المنتسبين', affiliated)),
                Expanded(child: _buildStatItem('غير المنتسبين', unjoined)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatItem('المعارين', loaned)),
                Expanded(child: _buildStatItem('الموقوفين', stopped)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text('$count',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange)),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabled ? color : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: [
              if (isEnabled)
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEnabled ? icon : Icons.lock_outline,
                color: isEnabled ? color : Colors.grey,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEnabled ? color : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (!isEnabled)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    '(مغلق)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
