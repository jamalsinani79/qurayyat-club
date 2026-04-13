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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Firebase.initializeApp();

    // 🔔 استقبال إشعارات الخلفية
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // 🔥 إعداد الإشعارات حسب النظام
    await setupFirebaseMessaging();
  }

  runApp(const QuriyatClubApp());
}

// 🔥 إعداد الإشعارات
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🤖 ANDROID
  if (Platform.isAndroid) {
    print("🤖 إعداد Android");

    String? token = await messaging.getToken();
    print("🔥 ANDROID TOKEN: $token");
  }

  // 🍎 IOS
  else if (Platform.isIOS) {
    print("🍎 إعداد iOS");

    NotificationSettings settings = await messaging.requestPermission(
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

    String? token = await messaging.getToken();
    print("🔥 IOS TOKEN: $token");
  }

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

      // ❌ لا تستخدم Directionality هنا (مهم جدًا)
      // Flutter يحدد الاتجاه تلقائيًا حسب اللغة

      home: const AnimatedLogoScreen(),
      getPages: AppPages.routes,
    );
  }
}