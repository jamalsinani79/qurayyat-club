import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// استيراد الصفحات
import '../screens/home_view.dart';
import '../screens/team_info_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/team_players_screen.dart';
import '../screens/register_player_screen.dart';
import '../screens/player_requests_screen.dart';
import '../screens/borrow_requests_screen.dart';
import '../screens/transfer_requests_screen.dart';
import '../screens/assistant_screen.dart';
import '../screens/loan_out_screen.dart';
import '../screens/team_messages_screen.dart';
import '../screens/club_team_messages_screen.dart';
import '../services/club_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String userName = '';
  String teamName = '';
  String secretaryName = '';

  bool isRegisterOpen = false;
  bool isLoanOpen = false;
  bool isTransferOpen = false;
  bool isInternalLoanOpen = false;

  bool isRenewed = false;
  bool isExpired = false;

  @override
  void initState() {
    super.initState();
    loadTeamInfo();
    fetchRequestStatuses();
    fetchRenewalStatus();
  }

  Future<void> loadTeamInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('https://teams.quriyatclub.net/api/v1/team'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        final info = data['info'];

        setState(() {
          userName = info['name'] ?? '';
          teamName = info['club']?['name'] ?? '';
          secretaryName = info['user_fullname'] ?? '';
        });
      }
    }
  }

  Future<void> fetchRequestStatuses() async {
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
          setState(() {
            isRegisterOpen = info['create_player_status'] == 'on';
            isLoanOpen = info['loan_status'] == 'on';
            isTransferOpen = info['transfer_status'] == 'on';
            isInternalLoanOpen = info['internal_transfer_status'] == 'on';
          });
        }
      }
    }
  }

  Future<void> fetchRenewalStatus() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://teams.quriyatclub.net/api/v1/team/renewal-status-v2'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (!mounted) return;

        setState(() {
          isRenewed = data['is_renewed'] ?? false;
          isExpired = data['is_expired'] ?? false;
        });

        print('🔥 Drawer isRenewed: ${data['is_renewed']}');
        print('🔥 Drawer isExpired: ${data['is_expired']}');
      }
    } else {
      print('⚠️ فشل في renewalStatus Drawer: ${response.body}');
    }
  } catch (e) {
    print('💥 خطأ Drawer renewalStatus: $e');
  }
}

  void _logout() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'تأكيد الخروج',
      desc: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      btnCancelText: 'إلغاء',
      btnOkText: 'خروج',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
    ).show();
  }

  Future<void> openWhatsAppFromAPI() async {
    final club = await ClubService.fetchClubInfo();

    if (club == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في جلب رقم النادي من السيرفر')),
      );
      return;
    }

    final phone = club.phone;
    final uri = Uri.parse('https://wa.me/$phone');

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.rightSlide,
      body: Column(
        children: [
          const FaIcon(FontAwesomeIcons.whatsapp, size: 50, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'سيتم نقلك إلى تطبيق واتساب خارج التطبيق، هل ترغب في المتابعة؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      btnCancelText: 'إلغاء',
      btnOkText: 'موافقة',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح تطبيق واتساب')),
          );
        }
      },
    ).show();
  }

  void _navigateTo(Widget page) {
  Navigator.pop(context); // أولًا نغلق Drawer

  final navigator = Navigator.of(context, rootNavigator: true);

  // نحصل على الصفحة الحالية
  final currentWidget = navigator.widget;
  final currentRoute = ModalRoute.of(context);

  // نتأكد إذا الصفحة المعروضة حاليًا هي HomeView فلا نعمل شيئًا
  if (page.runtimeType == HomeView && context.widget.runtimeType == HomeView) {
    return;
  }

  if (page.runtimeType == HomeView) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeView()),
      (route) => false,
    );
  } else {
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }
}


  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset('assets/svg/blurry-gradient-haikei.svg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.90)),
          ),
          SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("مرحبًا", style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(secretaryName, style: const TextStyle(color: Colors.blue, fontSize: 14)),
                      ],
                    ),
                  ),
                  const Divider(),

                  
                  
                   _drawerItem(Icons.home, 'الرئيسية', onTap: () {
  Navigator.pop(context);

  // 🔒 تأكد أنك لست في HomeView قبل الفتح
  if (context.widget.runtimeType == HomeView) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const HomeView()),
  );
}),


                    _drawerItem(
  Icons.info_outline,
  isRenewed ? 'نبذة عن الفريق' : 'نبذة عن الفريق (مغلق)',
  onTap: () {
    if (!isRenewed) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'عذرًا',
        desc: 'هذه الخدمة متاحة فقط للفرق المجددة.',
        btnOkText: 'موافق',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    _navigateTo(const TeamInfoScreen());
  },
),

                    ExpansionTile(
  leading: const Icon(Icons.people, color: Colors.orange),
  title: Text(
    isRenewed ? 'اللاعبين' : 'اللاعبين (مغلق)',
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  ),
  trailing: _customArrow(),

  // 🔒 منع فتح القسم إذا غير مجدد
  onExpansionChanged: (expanded) {
    if (!isRenewed) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'عذرًا',
        desc: 'هذه الخدمة متاحة فقط للفرق المجددة.',
        btnOkText: 'موافق',
        btnOkOnPress: () {},
      ).show();
    }
  },

  childrenPadding: const EdgeInsets.only(right: 36, left: 8),

  children: isRenewed
      ? [
          // 🔥 تسجيل لاعب (مربوط بشرطين)
          (isRenewed && isRegisterOpen)
              ? _subDrawerItem(
                  'تسجيل لاعب',
                  icon: Icons.person_add,
                  onTap: () => _navigateTo(const RegisterPlayerScreen()),
                )
              : _subDrawerItem(
                  isRenewed
                      ? 'تسجيل لاعب (مغلق من النادي)'
                      : 'تسجيل لاعب (يتطلب تجديد)',
                  icon: Icons.lock,
                  onTap: () {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.info,
                      title: 'عذرًا',
                      desc: isRenewed
                          ? 'تم إغلاق تسجيل اللاعبين من قِبل إدارة النادي.'
                          : 'هذه الخدمة متاحة فقط للفرق المجددة.',
                      btnOkText: 'موافق',
                      btnOkOnPress: () {},
                    ).show();
                  },
                ),

          // 🔥 اللاعبين المنتسبين (مربوط فقط بالتجديد)
          _subDrawerItem(
            'اللاعبين المنتسبين',
            icon: Icons.group,
            onTap: () => _navigateTo(const TeamPlayersScreen()),
          ),

          // 🔥 الطلبات (مربوط فقط بالتجديد)
          _subDrawerItem(
            'طلبات تسجيل اللاعبين',
            icon: Icons.assignment,
            onTap: () => _navigateTo(const PlayerRequestsScreen()),
          ),
        ]
      : [],
),

                    ExpansionTile(
  leading: const Icon(Icons.swap_horiz, color: Colors.orange),
  title: Text(
    isRenewed ? 'الطلبات' : 'الطلبات (مغلق)',
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  ),
  trailing: _customArrow(),

  // 🔒 منع الفتح إذا غير مجدد
  onExpansionChanged: (expanded) {
    if (!isRenewed) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'عذرًا',
        desc: 'هذه الخدمة متاحة فقط للفرق المجددة.',
        btnOkText: 'موافق',
        btnOkOnPress: () {},
      ).show();
    }
  },

  childrenPadding: const EdgeInsets.only(right: 36, left: 8),

  children: isRenewed
      ? [
          // 🔥 طلب استعارة
          (isRenewed && isLoanOpen)
              ? _subDrawerItem(
                  'طلب استعارة',
                  icon: Icons.file_copy_outlined,
                  onTap: () => _navigateTo(const BorrowRequestsScreen()),
                )
              : _subDrawerItem(
                  isRenewed
                      ? 'طلب استعارة (مغلق من النادي)'
                      : 'طلب استعارة (يتطلب تجديد)',
                  icon: Icons.lock,
                  onTap: () {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.info,
                      title: 'عذرًا',
                      desc: isRenewed
                          ? 'تم إغلاق طلبات الإعارة من قِبل إدارة النادي.'
                          : 'هذه الخدمة متاحة فقط للفرق المجددة.',
                      btnOkText: 'موافق',
                      btnOkOnPress: () {},
                    ).show();
                  },
                ),

          // 🔥 طلب نقل
          (isRenewed && isTransferOpen)
              ? _subDrawerItem(
                  'طلب نقل',
                  icon: Icons.transfer_within_a_station,
                  onTap: () => _navigateTo(const TransferRequestsScreen()),
                )
              : _subDrawerItem(
                  isRenewed
                      ? 'طلب نقل (مغلق من النادي)'
                      : 'طلب نقل (يتطلب تجديد)',
                  icon: Icons.lock,
                  onTap: () {
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.info,
                      title: 'عذرًا',
                      desc: isRenewed
                          ? 'تم إغلاق طلبات النقل من قِبل إدارة النادي.'
                          : 'هذه الخدمة متاحة فقط للفرق المجددة.',
                      btnOkText: 'موافق',
                      btnOkOnPress: () {},
                    ).show();
                  },
                ),
        ]
      : [],
),

                    _drawerItem(
  Icons.groups,
  isRenewed ? 'الجهاز الفني' : 'الجهاز الفني (مغلق)',
  onTap: () {
    if (!isRenewed) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'عذرًا',
        desc: 'هذه الخدمة متاحة فقط للفرق المجددة.',
        btnOkText: 'موافق',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    _navigateTo(const AssistantScreen());
  },
),

_drawerItem(
  Icons.login_outlined,
  isRenewed ? 'الإعارة الخارجية' : 'الإعارة الخارجية (مغلق)',
  onTap: () {
    if (!isRenewed) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'عذرًا',
        desc: 'هذه الخدمة متاحة فقط للفرق المجددة.',
        btnOkText: 'موافق',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    _navigateTo(const LoanOutScreen());
  },
),
                  

                  // 🟢 هذه تظهر دائمًا
                  ExpansionTile(
  leading: const Icon(Icons.mail_outline, color: Colors.orange),
  title: const Text(
    'الرسائل',
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  ),
  trailing: _customArrow(),
  childrenPadding: const EdgeInsets.only(right: 36, left: 8),
  children: [
    // 🔒 رسائل الفرق
    _subDrawerItem(
      isRenewed ? 'رسائل الفرق' : 'رسائل الفرق (مغلق)',
      icon: isRenewed ? Icons.message : Icons.lock,
      onTap: () {
        if (!isRenewed) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.info,
            title: 'عذرًا',
            desc: 'هذه الخدمة متاحة فقط للفرق المجددة.',
            btnOkText: 'موافق',
            btnOkOnPress: () {},
          ).show();
          return;
        }

        _navigateTo(const TeamMessagesScreen());
      },
    ),

    // ✅ رسائل النادي (دائمًا مفتوحة)
    _subDrawerItem(
      'رسائل النادي',
      icon: Icons.mark_email_unread_outlined,
      onTap: () => _navigateTo(const ClubTeamMessagesScreen()),
    ),
  ],
),
                  _drawerItem(Icons.update, 'التجديد السنوي', badgeText: 'قريباً'),
                  _drawerItem(Icons.settings, 'إدارة الفريق', badgeText: 'قريباً'),
                  _drawerItem(Icons.support_agent, 'الدعم', onTap: () => openWhatsAppFromAPI()),

                  const SizedBox(height: 40),
                  const Spacer(),
                  const Divider(),
                  _drawerItem(Icons.logout, 'تسجيل الخروج', iconColor: Colors.red, onTap: _logout),
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: const [
                        Text('الإصدار 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('برمجة: جمال السناني', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label,
      {String? badgeText, Color iconColor = Colors.orange, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 24, child: Icon(icon, color: iconColor, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _subDrawerItem(String label, {IconData icon = Icons.arrow_right, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          children: [
            SizedBox(width: 24, child: Icon(icon, size: 18, color: Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            const Icon(Icons.chevron_right, size: 20, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _customArrow() {
    return Container(
      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
      padding: const EdgeInsets.all(4),
      child: const Icon(Icons.expand_more, color: Colors.white, size: 18),
    );
  }
}