import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'dart:io';

import 'screens/auth/animated_logo_screen.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 بدون Firebase مؤقتًا (للتأكد أن iOS يشتغل)
  runApp(const QuriyatClubApp());
}

class QuriyatClubApp extends StatelessWidget {
  const QuriyatClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'نادي قريات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tajawal',
        primarySwatch: Colors.orange,
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],

      locale: const Locale('ar'),

      // ✅ اتجاه عربي (عدل حسب رغبتك)
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr, // استخدم TextDirection.rtl إذا كنت تريد اتجاه عربي
          child: child!,
        );
      },

      // ✅ البداية
      home: const AnimatedLogoScreen(),

      // routes (ما تضر)
      getPages: AppPages.routes,
    );
  }
}