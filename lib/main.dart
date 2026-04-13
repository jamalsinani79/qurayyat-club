import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'screens/auth/animated_logo_screen.dart';
import 'services/auth_service.dart';

// 📩 استقبال الإشعارات بالخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("📩 رسالة في الخلفية: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  runApp(const QuriyatClubApp());
}

// 🔥 إعداد الإشعارات (مفصول Android / iOS)
Future<void> setupFirebaseMessaging() async {
  try {
    if (kIsWeb) return;

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // =========================
    // 🤖 ANDROID
    // =========================
    if (Platform.isAndroid) {
      print("🤖 ANDROID SETUP");

      String? token = await messaging.getToken();
      print("🤖 ANDROID TOKEN: $token");

      if (token != null) {
        await sendTokenToServer(token);
      }
    }

    // =========================
    // 🍎 IOS
    // =========================
    else if (Platform.isIOS) {
      print("🍎 IOS SETUP");

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token;

      // 🔥 retry مهم للـ iOS
      for (int i = 0; i < 5; i++) {
        token = await messaging.getToken();

        if (token != null && token.isNotEmpty) break;

        await Future.delayed(const Duration(seconds: 1));
      }

      print("🍎 IOS TOKEN: $token");

      if (token != null) {
        await sendTokenToServer(token);
      }
    }

    // 🔄 تحديث التوكن
    messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 NEW TOKEN: $newToken");
      await sendTokenToServer(newToken);
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
    print("❌ Notification error: $e");
  }
}

// 🔥 إرسال التوكن للسيرفر
Future<void> sendTokenToServer(String token) async {
  try {
    await AuthService.updateDeviceToken(token);
  } catch (e) {
    print("❌ فشل إرسال التوكن: $e");
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