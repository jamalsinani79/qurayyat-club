import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'routes/app_pages.dart';
import 'screens/auth/animated_logo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuriyatClubApp());
}

class QuriyatClubApp extends StatelessWidget {
  const QuriyatClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'نادي قريات',
      debugShowCheckedModeBanner: false,

      // 🌙 الثيم
      theme: ThemeData(
        fontFamily: 'Tajawal',
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),

      // 🌍 اللغات
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🔄 الاتجاه
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      // 🚀 شاشة البداية
      home: const AnimatedLogoScreen(),

      // 📌 المسارات
      getPages: AppPages.routes,
    );
  }
}