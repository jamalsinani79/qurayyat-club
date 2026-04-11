import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AnimatedLogoScreen extends StatefulWidget {
  const AnimatedLogoScreen({super.key});

  @override
  State<AnimatedLogoScreen> createState() => _AnimatedLogoScreenState();
}

class _AnimatedLogoScreenState extends State<AnimatedLogoScreen> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    startAnimationAndNavigate();
  }

  Future<void> startAnimationAndNavigate() async {
    // ننتظر مدة عرض الجيف
    await Future.delayed(const Duration(seconds: 3));

    // التحقق من وجود التوكن
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
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

    Future<void> requestNotificationPermission() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        print("FCM TOKEN: $token");
      } else {
        print("❌ User رفض الإشعارات");
      }

    } catch (e) {
      print("Notification error: $e");
    }
  }

}
