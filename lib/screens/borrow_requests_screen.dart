import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/team_service.dart';
import '../widgets/player_card.dart';
import 'loan_request_screen.dart';
import 'loan_request_details_screen.dart';

class BorrowRequestsScreen extends StatefulWidget {
  const BorrowRequestsScreen({super.key});

  @override
  State<BorrowRequestsScreen> createState() => _BorrowRequestsScreenState();
}

class _BorrowRequestsScreenState extends State<BorrowRequestsScreen> {
  bool isSentSelected = true;
  final TextEditingController cardIdController = TextEditingController();
  Map<String, dynamic>? searchResult;
  bool isSearching = false;
  List<Map<String, dynamic>> loanRequests = [];
  bool isLoadingRequests = false;
  int? teamId;

  @override
  void initState() {
    super.initState();
    loadTeamId();
  }

  Future<void> loadTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    teamId = prefs.getInt('team_id');
    print('✅ teamId: $teamId'); // طباعة للتأكد
    loadRequests();
  }

  Future<void> loadRequests() async {
  setState(() => isLoadingRequests = true);

  final type = isSentSelected ? 'sender' : 'receiver';
  final fetched = await TeamService.fetchLoanRequests(type: type);

  if (!mounted) return; // ✅ الإضافة المهمة

  setState(() {
    loanRequests = fetched;
    isLoadingRequests = false;
  });
}



  Future<void> searchPlayer() async {
  final cardId = cardIdController.text.trim();
  if (cardId.isEmpty) return;

  setState(() {
    isSearching = true;
  });

  final data = await TeamService.searchPlayerByCardId(cardId);

  if (!mounted) return;

  if (data['status'] == true && data['info'] != null) {
    final player = data['info'];
    final joinStatus = player['join_status']?.toString() ?? '';

    if (joinStatus == 'موقف' || joinStatus == 'معار') {
      setState(() {
        searchResult = null;
      });

      String reason = joinStatus == 'موقف'
          ? 'هذا اللاعب موقوف ولا يمكن تقديم طلب استعارة له'
          : 'هذا اللاعب معار حاليًا ولا يمكن تقديم طلب جديد';

      Color color = joinStatus == 'موقف' ? Colors.red.shade600 : Colors.blue;

      Flushbar(
        message: reason,
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      ).show(context);

      return;
    }

    setState(() {
      searchResult = player;
    });
  } else {
    setState(() {
      searchResult = null;
    });

    Flushbar(
      message: 'لم يتم العثور على لاعب بالرقم المدني',
      backgroundColor: Colors.grey.shade800,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    ).show(context);
  }
}


  void clearSearch() {
    setState(() {
      cardIdController.clear();
      isSearching = false;
      searchResult = null;
    });
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: cardIdController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'أدخل الرقم المدني',
                hintStyle: const TextStyle(fontSize: 14),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => searchPlayer(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: searchPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'بحث',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoanRequestCards() {
  final filtered = loanRequests; // ✅ بدون فلترة


  if (filtered.isEmpty) {
    return const Center(child: Text('لا توجد طلبات حتى الآن'));
  }

  return ListView(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  children: filtered.map((req) {
    final player = req['player'] ?? {};
    final name = player['name'] ?? 'لاعب';
    final start = req['start'] ?? '';
    final end = req['end'] ?? '';
    final status = req['status'] ?? '';
    final otherTeam = isSentSelected
        ? (req['basic']?['name'] ?? 'الفريق المستقبل')
        : (req['sender']?['name'] ?? 'الفريق المرسل');

    return InkWell(
      onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoanRequestDetailsScreen(
          request: req,
         isSent: isSentSelected,
         ),
      ),
    );
    
    if (result == true && isSentSelected) {
      // ✅ احذف الطلب من القائمة عند الرفض أو الموافقة
      setState(() {
        loanRequests.removeWhere((r) => r['id'] == req['id']);
      });
    }
  },


      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 اللاعب: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('📅 من $start إلى $end'),
            Text('🏟 الفريق الآخر: $otherTeam'),
            Text(
              '📌 الحالة: $status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status == 'مقبول'
                    ? Colors.green
                    : status == 'مرفوض'
                        ? Colors.red
                        : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }).toList(),
);

  }




  @override
  Widget build(BuildContext context) {
    String status = '';
    bool canRequest = false;
    if (isSearching && searchResult != null) {
      status = searchResult!['join_status']?.toString() ?? '';
      canRequest = status == 'منتسب';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'طلبات الاستعارة',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          //actions: [
            //IconButton(
             //onPressed: () {},
              //icon: const Icon(Icons.notifications, color: Colors.orange),
          //  )
          //],
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
        ),
        body: Column(
          children: [
            buildSearchBar(),
            if (isSearching && searchResult != null)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    PlayerCard(player: searchResult!),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: canRequest
    ? () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoanRequestScreen(player: searchResult!),
          ),
        );

        if (result == true) {
          loadRequests(); // إعادة تحميل الطلبات
          clearSearch();  // إخفاء نتائج البحث
        }
      }
    : null,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'تقديم طلب استعارة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (!isSearching) ...[
              Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.orange),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Expanded(
        child: InkWell(
          onTap: () {
            setState(() => isSentSelected = true);
            loadRequests(); // تحميل الطلبات بعد التغيير
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSentSelected ? Colors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              'مرسلة',
              style: TextStyle(
                color: isSentSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: InkWell(
          onTap: () {
            setState(() => isSentSelected = false);
            loadRequests(); // تحميل الطلبات بعد التغيير
          },
          child: Container(
            decoration: BoxDecoration(
              color: !isSentSelected ? Colors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              'مستقبلة',
              style: TextStyle(
                color: !isSentSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),

              const SizedBox(height: 16),
              if (isLoadingRequests)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              else
                Expanded(child: buildLoanRequestCards()),
            ]
          ],
        ),
      ),
    );
  }
}  