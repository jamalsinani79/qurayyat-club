import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'screens/auth/animated_logo_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 تهيئة Firebase بالطريقة الصحيحة (مهم جدًا)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const QuriyatClubApp());
}

class QuriyatClubApp extends StatefulWidget {
  const QuriyatClubApp({super.key});

  @override
  State<QuriyatClubApp> createState() => _QuriyatClubAppState();
}

class _QuriyatClubAppState extends State<QuriyatClubApp> {

  @override
  void initState() {
    super.initState();

    // 🔔 تشغيل الإشعارات بعد تشغيل التطبيق
    initNotifications();
  }

  Future<void> initNotifications() async {
    try {
      if (kIsWeb) return;

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 🔔 طلب الإذن
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print("Authorization: ${settings.authorizationStatus}");

      String? fcmToken = await messaging.getToken();
      print("🔥 FCM TOKEN: $fcmToken");

      // 📩 استقبال الإشعار أثناء فتح التطبيق
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📩 Notification: ${message.notification?.title}");
      });

    } catch (e) {
      print("❌ Notification error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'نادي قريات',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        fontFamily: 'Tajawal',
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
      ),

      // 🌍 اللغة
      locale: const Locale('ar'),
      fallbackLocale: const Locale('en'),

      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const AnimatedLogoScreen(),
      getPages: AppPages.routes,
    );
  }
}