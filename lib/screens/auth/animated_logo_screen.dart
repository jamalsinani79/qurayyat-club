import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AnimatedLogoScreen extends StatefulWidget {
  const AnimatedLogoScreen({super.key});

  @override
  State<AnimatedLogoScreen> createState() => _AnimatedLogoScreenState();
}

class _AnimatedLogoScreenState extends State<AnimatedLogoScreen> {

  @override
  void initState() {
    super.initState();
    initApp(); // 👈 نبدأ كل شيء هنا
  }

  Future<void> initApp() async {
    try {
      // 🔥 تهيئة Firebase (بأمان)
      if (!kIsWeb) {
        await Firebase.initializeApp();

        await setupFirebaseMessaging();
      }

      // ⏳ الانتظار (اللوجو)
      await Future.delayed(const Duration(seconds: 3));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }

    } catch (e) {
      print("🔥 Error in initApp: $e");
      Get.offAllNamed('/login');
    }
  }

  // 🔔 إعداد الإشعارات
  Future<void> setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 🍎 iOS
      if (Platform.isIOS) {
        NotificationSettings settings =
            await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        print('🔔 iOS Permission: ${settings.authorizationStatus}');

        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // 🔥 التوكن
      String? token = await messaging.getToken();
      print("🔥 FCM TOKEN: $token");

      // 🔄 تحديث التوكن
      messaging.onTokenRefresh.listen((newToken) {
        print("🔄 NEW TOKEN: $newToken");
      });

      // 📩 أثناء فتح التطبيق
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 إشعار أثناء فتح التطبيق');
      });

      // 🚀 عند الضغط
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🚀 فتح من إشعار');
      });

    } catch (e) {
      print("❌ Notification Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/icon/logo_animate.gif',
          width: 220,
          height: 220,
        ),
      ),
    );
  }
}