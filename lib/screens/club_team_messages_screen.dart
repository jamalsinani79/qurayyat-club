import 'package:flutter/material.dart';
import '../services/team_message_service.dart';
import 'package:quriyat_club/screens/club_message_detail_screen.dart';
import 'package:quriyat_club/screens/new_club_message_screen.dart'; 


class ClubTeamMessagesScreen extends StatefulWidget {
  const ClubTeamMessagesScreen({super.key});

  @override
  State<ClubTeamMessagesScreen> createState() => _ClubTeamMessagesScreenState();
}

class _ClubTeamMessagesScreenState extends State<ClubTeamMessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  bool isLoading = false;

  List<dynamic> fromTeamToClub = [];
  List<dynamic> fromClubToTeam = [];

  int fromTeamPage = 1;
  int fromTeamLastPage = 1;

  int fromClubPage = 1;
  int fromClubLastPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) fetchMessages();
    });
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    setState(() => isLoading = true);
    final teamToClubData = await TeamMessageService.fetchClubMessages(incoming: false, query: searchQuery, page: fromTeamPage);
    final clubToTeamData = await TeamMessageService.fetchClubMessages(incoming: true, query: searchQuery, page: fromClubPage);
    setState(() {
      fromTeamToClub = teamToClubData['messages'];
      fromTeamLastPage = teamToClubData['lastPage'];
      fromTeamPage = teamToClubData['currentPage'];

      fromClubToTeam = clubToTeamData['messages'];
      fromClubLastPage = clubToTeamData['lastPage'];
      fromClubPage = clubToTeamData['currentPage'];
      isLoading = false;
    });
  }

  void _onSearch() async {
    final query = await showSearch(context: context, delegate: MessageSearchDelegate());
    if (query != null) {
      setState(() => searchQuery = query);
      fetchMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رسائل النادي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: _onSearch),
            if (searchQuery.isNotEmpty)
              IconButton(icon: const Icon(Icons.close), onPressed: () {
                setState(() => searchQuery = '');
                fetchMessages();
              }),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orange,
            tabs: const [Tab(text: 'الواردة'), Tab(text: 'الصادرة')],
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (searchQuery.isNotEmpty)
                    Container(
                      width: double.infinity,
                      color: Colors.yellow.shade100,
                      padding: const EdgeInsets.all(12),
                      child: Text('نتائج البحث عن: "$searchQuery"', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMessageList(fromClubToTeam, fromClubPage, fromClubLastPage, () {
                          if (fromClubPage > 1) {
                            fromClubPage--;
                            fetchMessages();
                          }
                        }, () {
                          if (fromClubPage < fromClubLastPage) {
                            fromClubPage++;
                            fetchMessages();
                          }
                        }),
                        _buildMessageList(fromTeamToClub, fromTeamPage, fromTeamLastPage, () {
                          if (fromTeamPage > 1) {
                            fromTeamPage--;
                            fetchMessages();
                          }
                        }, () {
                          if (fromTeamPage < fromTeamLastPage) {
                            fromTeamPage++;
                            fetchMessages();
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, bottom: 45.0),
            child: SizedBox(
              width: 160,
              height: 50,
              child: FloatingActionButton.extended(
                onPressed: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NewClubMessageScreen()),
  );
  if (result == true) {
    fetchMessages(); // ✅ إعادة تحميل الرسائل بعد الإرسال
  }
},
                backgroundColor: Colors.orange,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('رسالة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(List<dynamic> messages, int currentPage, int lastPage, VoidCallback onPrev, VoidCallback onNext) {
  if (messages.isEmpty) return const Center(child: Text('لا توجد رسائل حاليًا'));

  return Column(
    children: [
      Expanded(
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final subject = msg['subject'] ?? '';
            final senderType = msg['sender'] ?? '';
            final isRead = msg['status'].toString() == '1';
            final date = (msg['created_at'] ?? '').toString().substring(0, 10);
            final isIncoming = _tabController.index == 0;

            String otherParty = '---';
            if (senderType == 'team') {
              otherParty = msg['send']?['name'] ?? '---';
            } else if (senderType == 'club') {
              otherParty = msg['send']?['name'] ?? 'نادي قريات';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClubMessageDetailScreen(message: msg, isIncoming: isIncoming),
                    ),
                  ).then((_) => fetchMessages());
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                    border: Border.all(
                      color: isRead ? Colors.green.shade100 : Colors.orange.shade100,
                      width: 1.2,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mail_outline, color: isRead ? Colors.green : Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subject,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.group, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${isIncoming ? 'من' : 'إلى'}: $otherParty',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 4),
                              Text(date, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                            color: isRead ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRead ? 'مقروءة' : 'غير مقروءة',
                            style: TextStyle(color: isRead ? Colors.green : Colors.orange, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
            Text('صفحة $currentPage من $lastPage'),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
      ),
    ],
  );
}
}

class MessageSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'ابحث في الرسائل...';
  @override
  TextStyle get searchFieldStyle => const TextStyle(fontSize: 16, color: Colors.black);
  TextDirection get textDirection => TextDirection.rtl;
  @override
  Widget buildResults(BuildContext context) => Container();
  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('أدخل عبارة للبحث عن الرسائل...'));
    }
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text('ابحث عن "$query"'),
      onTap: () => close(context, query),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_forward),
        onPressed: () => close(context, ''),
      );
}
