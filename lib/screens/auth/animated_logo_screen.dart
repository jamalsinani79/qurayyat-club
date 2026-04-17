import 'dart:async';
import '../../main.dart';
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
      print("🔥 INIT STATE WORKING");
    startAnimationAndNavigate();
  }

  Future<void> startAnimationAndNavigate() async {
  try {
    print("🚀 START SPLASH");

    await Future.delayed(const Duration(seconds: 3));
    print("⏳ DELAY DONE");

    final prefs = await SharedPreferences.getInstance();
    print("📦 PREFS READY");

    final token = prefs.getString('auth_token');
    print("🔑 TOKEN: $token");

    if (token != null && token.isNotEmpty) {
      print("➡️ USER LOGGED IN");

      print("🔥 BEFORE FIREBASE SETUP");
      await setupFirebaseMessaging();
      print("🔥 AFTER FIREBASE SETUP");

      print("➡️ GO TO HOME");
      Get.offAllNamed('/home');
    } else {
      print("➡️ GO TO LOGIN");
      Get.offAllNamed('/login');
    }

  } catch (e) {
    print("❌ Navigation Error: $e");
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
}