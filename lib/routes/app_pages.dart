import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ استيراد الصفحات
import '../screens/auth/animated_logo_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_view.dart';
import '../screens/player_details_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/team_message_detail_screen.dart';
import '../screens/club_team_messages_screen.dart'; // ✅ تمت الإضافة

// ✅ استيراد الخدمة
import '../services/team_message_service.dart';

class AppPages {
  static const initial = '/animated-logo';

  static final routes = [
    GetPage(name: '/animated-logo', page: () => const AnimatedLogoScreen()),
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => const LoginScreen()),
    GetPage(name: '/home', page: () => const HomeView()),
    GetPage(name: '/player-details', page: () => PlayerDetailsScreen()),
    GetPage(name: '/notifications', page: () => const NotificationsScreen()),

    // ✅ صفحة تفاصيل رسالة الفريق
    GetPage(
      name: '/message-detail',
      page: () {
        final args = Get.arguments as Map;
        return FutureBuilder(
          future: TeamMessageService.fetchMessageById(args['id']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Scaffold(body: Center(child: Text('تعذر تحميل الرسالة')));
            }

            final message = snapshot.data!;
            return TeamMessageDetailScreen(
              message: message,
              isIncoming: true,
            );
          },
        );
      },
    ),

    // ✅ صفحة رسائل النادي (للوصول حتى لو لم يتم التجديد)
    GetPage(name: '/club-messages', page: () => const ClubTeamMessagesScreen()),
  ];
}
