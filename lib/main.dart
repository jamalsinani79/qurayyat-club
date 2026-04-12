import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'routes/app_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // التقاط أخطاء Flutter
  FlutterError.onError = (details) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text(
              "ERROR:\n${details.exception}",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  };

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

      // ❌ بدون builder (كان يسبب الشاشة السوداء)

      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            "SAFE MODE ✅",
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),

      getPages: AppPages.routes,
    );
  }
}