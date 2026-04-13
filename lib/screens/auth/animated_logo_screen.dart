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
    startAnimationAndNavigate();
  }

  Future<void> startAnimationAndNavigate() async {
    try {
      await Future.delayed(const Duration(seconds: 3));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        await setupFirebaseMessaging();
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }

    } catch (e) {
      print("Navigation Error: $e");
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