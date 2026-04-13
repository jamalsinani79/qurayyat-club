import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'routes/app_pages.dart';
import 'screens/auth/animated_logo_screen.dart';

// 📩 استقبال الإشعارات بالخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
  print("📩 رسالة في الخلفية: ${message.messageId}");
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ❌ لا تشغل Firebase هنا (مهم جدًا)

  runApp(const QuriyatClubApp());
}

// 🔥 إعداد الإشعارات
Future<void> setupFirebaseMessaging() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🍎 IOS
    if (Platform.isIOS) {
      print("🍎 إعداد iOS");

      NotificationSettings settings =
          await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('🔔 حالة الإذن: ${settings.authorizationStatus}');

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 🤖 ANDROID
    if (Platform.isAndroid) {
      print("🤖 إعداد Android");
    }

    // 🔥 التوكن
    String? token = await messaging.getToken();
    print("🔥 TOKEN: $token");

    // 🔄 تحديث التوكن
    messaging.onTokenRefresh.listen((newToken) {
      print("🔄 NEW TOKEN: $newToken");
    });

    // 📩 أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 إشعار أثناء فتح التطبيق');
      print('📌 Title: ${message.notification?.title}');
      print('📌 Body: ${message.notification?.body}');
    });

    // 🚀 عند الضغط على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 تم فتح التطبيق من إشعار');
    });

  } catch (e) {
    print("❌ خطأ في الإشعارات: $e");
  }
}

// 🚀 التطبيق
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
        scaffoldBackgroundColor: Colors.white,
      ),

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