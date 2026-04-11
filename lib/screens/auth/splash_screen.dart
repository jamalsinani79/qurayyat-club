import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // مدة عرض السبلاتش

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // الخلفية
          Image.asset(
            'assets/images/splash.png',
            fit: BoxFit.cover,
          ),

          // الشعار المتحرك في المنتصف
          Center(
            child: Image.asset(
              'assets/images/logo.png', // ← هنا الشعار الجديد
              width: 250,
              height: 250,
            ),
          ),
        ],
      ),
    );
  }
}
