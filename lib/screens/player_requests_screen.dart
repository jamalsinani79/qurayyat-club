import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quriyat_club/services/team_service.dart';
import 'package:quriyat_club/widgets/player_card.dart';

class PlayerRequestsScreen extends StatefulWidget {
  const PlayerRequestsScreen({super.key});

  @override
  State<PlayerRequestsScreen> createState() => _PlayerRequestsScreenState();
}

class _PlayerRequestsScreenState extends State<PlayerRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> tabs = [
    {'title': 'مسودة', 'status': 'draft'},
    {'title': 'مرسل للنادي', 'status': 'send_to_club'},
    {'title': 'الموافق عليها', 'status': 'club_approve'},
    {'title': 'مدفوعه', 'status': 'paid'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.orange,
          title: const Text(
            'طلبات تسجيل اللاعبين',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                indicatorColor: Colors.orange,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                labelPadding: EdgeInsets.zero,
                tabs: tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final title = entry.value['title']!;
                  return Tab(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: index == 0 ? 8 : 16),
                      child: Text(title),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: tabs.map((tab) {
            final status = tab['status']!;
            return FutureBuilder(
              future: TeamService.fetchPlayerRequests(status),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !(snapshot.data?['status'] ?? false)) {
                  return const Center(child: Text('فشل في تحميل البيانات'));
                }

                final players = snapshot.data!['info'] as List;

                // ✅ فلترة اللاعبين حسب حالة الطلب
                final filteredPlayers = players.where((p) {
                  final approveStatus = p['approve_status']?.toString() ?? '';
                  return approveStatus == status;
                }).toList();

                if (filteredPlayers.isEmpty) {
                  return const Center(child: Text('لا توجد بيانات حالياً'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    return GestureDetector(
                      onTap: () {
                        Get.toNamed('/player-details', arguments: player);
                      },
                      child: PlayerCard(player: player),
                    );
                  },
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
