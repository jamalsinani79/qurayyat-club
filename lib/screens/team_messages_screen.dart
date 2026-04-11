import 'package:flutter/material.dart';
import '../services/team_message_service.dart';
import '../screens/new_team_message_screen.dart';
import '../screens/team_message_detail_screen.dart';

class TeamMessagesScreen extends StatefulWidget {
  const TeamMessagesScreen({super.key});

  @override
  State<TeamMessagesScreen> createState() => _TeamMessagesScreenState();
}

class _TeamMessagesScreenState extends State<TeamMessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  bool isLoading = false;

  List<dynamic> incomingMessages = [];
  List<dynamic> outgoingMessages = [];

  int incomingPage = 1;
  int incomingLastPage = 1;

  int outgoingPage = 1;
  int outgoingLastPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        fetchMessages(); // إعادة تحميل عند التغيير
      }
    });

    fetchMessages(); // تحميل أولي
  }

  Future<void> fetchMessages() async {
    setState(() => isLoading = true);

    final incomingData = await TeamMessageService.fetchMessages(
      incoming: true,
      query: searchQuery,
      page: incomingPage,
    );

    final outgoingData = await TeamMessageService.fetchMessages(
      incoming: false,
      query: searchQuery,
      page: outgoingPage,
    );

    incomingMessages = incomingData['messages'];
    incomingLastPage = incomingData['lastPage'];
    incomingPage = incomingData['currentPage'];

    outgoingMessages = outgoingData['messages'];
    outgoingLastPage = outgoingData['lastPage'];
    outgoingPage = outgoingData['currentPage'];

    setState(() => isLoading = false);
  }

  void _onSearch() async {
    final query = await showSearch(
      context: context,
      delegate: MessageSearchDelegate(),
    );
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
        title: const Text(
          'رسائل الفريق',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _onSearch),
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'إلغاء البحث',
              onPressed: () {
                setState(() {
                  searchQuery = '';
                });
                fetchMessages();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          tabs: const [Tab(text: 'الواردة'), Tab(text: 'الصادرة')],
          labelStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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
                    child: Text(
                      'نتائج البحث عن: "$searchQuery"',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMessageList(
                        incomingMessages,
                        incomingPage,
                        incomingLastPage,
                        () {
                          if (incomingPage > 1) {
                            incomingPage--;
                            fetchMessages();
                          }
                        },
                        () {
                          if (incomingPage < incomingLastPage) {
                            incomingPage++;
                            fetchMessages();
                          }
                        },
                      ),
                      _buildMessageList(
                        outgoingMessages,
                        outgoingPage,
                        outgoingLastPage,
                        () {
                          if (outgoingPage > 1) {
                            outgoingPage--;
                            fetchMessages();
                          }
                        },
                        () {
                          if (outgoingPage < outgoingLastPage) {
                            outgoingPage++;
                            fetchMessages();
                          }
                        },
                      ),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewTeamMessageScreen()),
                );
              },
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('رسالة جديدة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildMessageList(
  List<dynamic> messages,
  int currentPage,
  int lastPage,
  VoidCallback onPrev,
  VoidCallback onNext,
) {
  if (messages.isEmpty) {
    return const Center(child: Text('لا توجد رسائل حاليًا'));
  }

  return Column(
    children: [
      Expanded(
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final subject = msg['subject'] ?? '';
            final isIncoming = _tabController.index == 0;

            final otherTeam = isIncoming
                ? (msg['send']?['name'] ?? 'غير معروف')
                : (msg['receiver']?['name'] ?? 'غير معروف');

            final date = (msg['created_at'] ?? '').toString().substring(0, 10);
            final isRead = msg['status'] == 1;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TeamMessageDetailScreen(
        message: msg,
        isIncoming: _tabController.index == 0,
      ),
    ),
  ).then((_) => fetchMessages()); // ✅ تحديث الحالة بعد الرجوع
},


                child: Container(
                  decoration: BoxDecoration(
                    color: isRead ? Colors.grey.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
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
                          const Icon(Icons.mail_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.group, color: Colors.grey.shade600, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                isIncoming ? 'من: $otherTeam' : 'إلى: $otherTeam',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
                              const SizedBox(width: 4),
                              Text(date, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                            style: TextStyle(
                              color: isRead ? Colors.green : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
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
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left, color: Colors.orange)),
            Text(
              'صفحة $currentPage من $lastPage',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right, color: Colors.orange)),
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
  TextDirection get textDirection => TextDirection.rtl;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(fontSize: 14),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () => close(context, ''),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      );

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
Widget buildSuggestions(BuildContext context) {
  if (query.trim().isEmpty) {
    return Center(
      child: Text(
        'أدخل عبارة للبحث عن الرسائل...',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }

  return ListView(
    children: [
      ListTile(
        leading: const Icon(Icons.search),
        title: Text('ابحث عن "$query"'),
        onTap: () {
          close(context, query); // ✅ يُعيد النص لواجهة TeamMessagesScreen
        },
      ),
    ],
  );
}

}
