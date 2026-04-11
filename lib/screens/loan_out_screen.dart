// lib/screens/loan_out_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/loan_out_service.dart';
import '../widgets/loan_out_player_card.dart';
import '../screens/add_loan_out_player_screen.dart';
import 'loan_out_detail_screen.dart';



class LoanOutScreen extends StatefulWidget {
  const LoanOutScreen({super.key});

  @override
  State<LoanOutScreen> createState() => _LoanOutScreenState();
}

class _LoanOutScreenState extends State<LoanOutScreen> {
  List<Map<String, dynamic>> players = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlayers();
  }

  Future<void> fetchPlayers() async {
    try {
      // استبدل هذا بالتوكن الحقيقي للفريق الحالي
      const token = 'your_team_token_here';
      final result = await LoanOutService.fetchLoanOutPlayers(); 
      setState(() {
        players = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('خطأ', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('الإعارة الخارجية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : players.isEmpty
                ? const Center(child: Text('لا توجد بيانات حالياً'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return GestureDetector(
  onTap: () async {
    final result = await Get.to(() => LoanOutDetailScreen(player: player));
    if (result == true) {
      fetchPlayers(); // ✅ تحديث البيانات إذا تم الإرسال
    }
  },
  child: LoanOutPlayerCard(player: player),
);


                    },
                        ),
                       
        floatingActionButton: FloatingActionButton.extended(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLoanOutPlayerScreen()),
    );
    if (result == true) {
      fetchPlayers();
    }
  },
  backgroundColor: Colors.red,
  icon: const Icon(Icons.add, color: Colors.white),
  label: const Text('إضافة لاعب خارجي', style: TextStyle(color: Colors.white)),
),

      ),
    );
  }
}
