import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'screens/auth/animated_logo_screen.dart';
import 'routes/app_pages.dart';

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

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr, // 👈 مهم للعربي
          child: child!,
        );
      },

      home: const AnimatedLogoScreen(), // 👈 هنا التعديل

      getPages: AppPages.routes,
    );
  }
}
