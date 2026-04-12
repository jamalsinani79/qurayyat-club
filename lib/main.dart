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

    // 🔔 الخلفية
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // 🔔 طلب إذن (مهم جدًا للآيفون)
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 حالة الإذن: ${settings.authorizationStatus}');

    // 🔥 جلب التوكن
    String? token = await FirebaseMessaging.instance.getToken();
    print("🔥 FCM TOKEN: $token");

    // 🔄 تحديث التوكن
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("🔄 NEW FCM TOKEN: $newToken");
    });

    // ✅ استقبال الإشعار والتطبيق مفتوح
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 إشعار أثناء فتح التطبيق');
      print('📌 Title: ${message.notification?.title}');
      print('📌 Body: ${message.notification?.body}');
    });

    // ✅ عند الضغط على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 تم فتح التطبيق من إشعار');
    });

    // 🔥 مهم جدًا للآيفون (عرض الإشعار أثناء التشغيل)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

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
        scaffoldBackgroundColor: Colors.white,
      ),

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

      // ✅ الاتجاه الصحيح
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },

      home: const AnimatedLogoScreen(),
      getPages: AppPages.routes,
    );
  }
}