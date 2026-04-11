import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/team_service.dart';
import '../../widgets/player_card.dart';
import '../../utils/pdf_utils.dart';

class TeamPlayersScreen extends StatefulWidget {
  const TeamPlayersScreen({super.key});

  @override
  State<TeamPlayersScreen> createState() => _TeamPlayersScreenState();
}

class _TeamPlayersScreenState extends State<TeamPlayersScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  List players = [];
  int currentPage = 1;
  int totalPages = 1;

  // شعار الفريق (raw path مثل logo/abc.png)
  String rawLogoPath = '';

  @override
  void initState() {
    super.initState();
    fetchPlayers(page: 1);
    loadTeamInfo(); // لجلب شعار الفريق
  }

  // تحميل اللاعبين
  void fetchPlayers({int page = 1, String? search}) async {
    setState(() => isLoading = true);

    final searchText = search ?? searchController.text.trim();
    final result = await TeamService.getTeamPlayers(page: page, search: searchText);

    if (result['status']) {
      final info = result['info'];
      setState(() {
        players = info['data'];
        currentPage = info['current_page'];
        totalPages = info['last_page'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      Get.snackbar('خطأ', result['message']);
    }
  }

  // تحميل معلومات الفريق بما فيها الشعار
  void loadTeamInfo() async {
    final token = await TeamService.getToken();
    if (token == null) return;

    final team = await TeamService.fetchTeamInfo(token);
    if (team != null && team.logo != null) {
      setState(() {
        rawLogoPath = team.logo!;
      });
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false, 
  title: const Text('اللاعبين المنتسبين'),
  actions: [
    IconButton(
      icon: const Icon(Icons.arrow_forward_ios),
      onPressed: () => Navigator.pop(context),
    ),
  ],
),
    body: SafeArea(
      child: Column(
        children: [
            // البحث والطباعة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'ابحث باستخدام الرقم المدني',
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              fetchPlayers(page: 1);
                            },
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    searchController.clear();
                                    fetchPlayers(page: 1);
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        onSubmitted: (value) {
                          fetchPlayers(page: 1);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
  icon: const Icon(Icons.print, color: Colors.grey),
  onPressed: () async {
  Get.dialog(
    const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('يتم الآن تحميل القائمة، نرجو الانتظار...'),
        ],
      ),
    ),
    barrierDismissible: false,
  );

  List allPlayers = [];
  int page = 1;
  bool hasMore = true;

  while (hasMore) {
    final result = await TeamService.getTeamPlayers(page: page);
    if (result['status']) {
      final info = result['info'];
      allPlayers.addAll(info['data']);
      if (page >= info['last_page']) {
        hasMore = false;
      } else {
        page++;
      }
    } else {
      hasMore = false;
      Get.back(); // إغلاق نافذة التحميل
      Get.snackbar('خطأ', result['message']);
    }
  }

  Get.back(); // إغلاق نافذة "جاري التحميل"

  if (allPlayers.isNotEmpty) {
    // عرض رسالة "سيتم تحويلك حاليًا إلى القائمة..."
    Get.dialog(
      const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 40),
            SizedBox(height: 12),
            Text('سيتم تحويلك حاليًا إلى القائمة...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    await Future.delayed(const Duration(seconds: 2));
    Get.back(); // إغلاق رسالة التحويل

    await printPlayers(allPlayers, rawLogoPath: rawLogoPath);
  } else {
    Get.snackbar('تنبيه', 'لا توجد بيانات للطباعة');
  }
},


),

                ],
              ),
            ),

            // قائمة البطاقات
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : players.isEmpty
                      ? const Center(child: Text('لا يوجد لاعبين حاليًا'))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: players.length,
                                itemBuilder: (context, index) => PlayerCard(
                                  player: players[index],
                                ),
                              ),
                            ),

                            // التنقل بين الصفحات
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12, top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: currentPage > 1
                                        ? () => fetchPlayers(page: currentPage - 1)
                                        : null,
                                  ),
                                  Text(
                                    'الصفحة $currentPage من $totalPages',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: currentPage < totalPages
                                        ? () => fetchPlayers(page: currentPage + 1)
                                        : null,
                                  ),
                                ],
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
}
