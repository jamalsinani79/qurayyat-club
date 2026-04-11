import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../services/team_service.dart';
import '../widgets/player_card.dart';
import '../screens/submit_transfer_request_screen.dart';
import '../screens/transfer_review_screen.dart';

class TransferRequestsScreen extends StatefulWidget {
  const TransferRequestsScreen({super.key});

  @override
  State<TransferRequestsScreen> createState() => _TransferRequestsScreenState();
}

class _TransferRequestsScreenState extends State<TransferRequestsScreen> {
  bool isSentSelected = true;
  final TextEditingController cardIdController = TextEditingController();
  Map<String, dynamic>? searchResult;
  bool isSearching = false;
  List<Map<String, dynamic>> transferRequests = [];
  bool isLoadingRequests = false;
  int? teamId;

  Set<int> locallyRejectedRequests = {};

  @override
  void initState() {
    super.initState();
    loadTeamId();
  }

  Future<void> loadTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    teamId = prefs.getInt('team_id');
    loadRequests();
  }

  Future<void> loadRequests() async {
    setState(() => isLoadingRequests = true);
    final type = isSentSelected ? 'sender' : 'receiver';
    final fetched = await TeamService.fetchTransferRequests(type: type);
    if (!mounted) return;
    setState(() {
      transferRequests = fetched;
      isLoadingRequests = false;
    });
  }

  Future<void> searchPlayer() async {
  final cardId = cardIdController.text.trim();
  if (cardId.isEmpty) return;

  setState(() => isSearching = true);
  final data = await TeamService.searchTransferPlayer(cardId);

  if (!mounted) return;

  if (data['status'] == true && data['info'] != null) {
    final player = data['info'];
    final joinStatus = player['join_status']?.toString() ?? '';

    if (joinStatus == 'معار' || joinStatus == 'موقف') {
      setState(() {
        searchResult = null;
      });

      String reason = '';
      Color color = Colors.orange;

      if (joinStatus == 'معار') {
        reason = 'هذا اللاعب معار حاليًا ولا يمكن نقله';
        color = Colors.blue;
      } else if (joinStatus == 'موقف') {
        reason = 'هذا اللاعب موقوف حاليًا ولا يمكن نقله';
        color = Colors.red.shade600;
      }

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

    setState(() => searchResult = player);
  } else {
    setState(() => searchResult = null);

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

  void showTopMessage(String message, Color color) {
    Flushbar(
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
    ).show(context);
  }

  void acceptRequest(int requestId) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.rightSlide,
      title: 'تأكيد القبول',
      desc: 'هل أنت متأكد من قبول هذا الطلب؟',
      btnCancelText: 'لا',
      btnOkText: 'نعم',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final result = await TeamService.approveTransferRequest(requestId);
        if (!mounted) return;
        if (result['status']) {
          showTopMessage(result['message'], Colors.green);
          loadRequests();
        } else {
          showTopMessage(result['message'], Colors.red);
        }
      },
    ).show();
  }

  void rejectRequest(Map<String, dynamic> req) {
    final int id = req['id'];
    setState(() {
      locallyRejectedRequests.add(id);
    });
    showTopMessage('تم رفض الطلب بنجاح', Colors.red);
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
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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

  Widget buildTransferCard(Map<String, dynamic> req) {
    final player = req['player'] ?? {};
    final status = req['status'] ?? '';
    final senderTeam = req['sender']?['name'] ?? 'الفريق المرسل';
    final basicTeam = req['basic']?['name'] ?? 'الفريق الأساسي';

    Color statusColor = Colors.orange;
    if (status == 'وافق عليه الفريق الاساسي') statusColor = Colors.blue;
    else if (status == 'وافق عليه النادي') statusColor = Colors.purple;
    else if (status == 'تم النقل') statusColor = Colors.green;
    else if (status == 'مرفوض من الفريق الاساسي') statusColor = Colors.red;

    return InkWell(
      onTap: () {
        if (isSentSelected && status == 'وافق عليه النادي') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubmitTransferRequestScreen(
                player: player,
                request: req,
                isReviewMode: true,
              ),
            ),
          );
        } else if (!isSentSelected &&
            status == 'مرسل الى الفريق الاساسي' &&
            !locallyRejectedRequests.contains(req['id'])) {
          showTransferReview(req);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 اللاعب: ${player['name'] ?? 'لاعب'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('🚩 الفريق المرسل: $senderTeam'),
            Text('🏟 الفريق الأساسي: $basicTeam'),
            Text('📌 الحالة: $status', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void showTransferReview(Map<String, dynamic> req) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferReviewScreen(request: req),
      ),
    );

    if (result == true) {
      loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('طلبات النقل'),
        ),
        body: Column(
          children: [
            buildSearchBar(),
            if (searchResult != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: PlayerCard(player: searchResult!),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubmitTransferRequestScreen(player: searchResult!),
                            ),
                          ).then((result) {
                            if (result == true) {
                              clearSearch();
                              loadRequests();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'تقديم طلب نقل',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
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
                          loadRequests();
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
                          loadRequests();
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
              const SizedBox(height: 12),
              if (isLoadingRequests)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              else
                Expanded(
                  child: transferRequests.isEmpty
                      ? const Center(child: Text('لا توجد طلبات حالياً'))
                      : ListView(
                          children: transferRequests.map(buildTransferCard).toList(),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
