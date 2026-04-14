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
        print("🤖 TOKEN READY: $token");
      }
    }

    // =========================
    // 🍎 IOS
    // =========================
    else if (Platform.isIOS) {
      print("🍎 IOS SETUP");

      // طلب الإذن
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print("🔔 Permission: ${settings.authorizationStatus}");

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 🔥 APNS
      String? apnsToken = await messaging.getAPNSToken();
      print("🍎 APNS TOKEN: $apnsToken");

      if (apnsToken != null) {
        Get.snackbar(
          "APNS TOKEN",
          apnsToken,
          duration: const Duration(seconds: 10),
        );
      }

      if (apnsToken == null) {
        print("❌ APNS NOT READY");
        return;
      }

      await Future.delayed(const Duration(seconds: 2));

      // 🔥 FCM
      String? fcmToken = await messaging.getToken();
      print("🍎 FCM TOKEN: $fcmToken");

      if (fcmToken != null) {
        Get.snackbar(
          "FCM TOKEN",
          fcmToken,
          duration: const Duration(seconds: 10),
        );
      }
    }

    // 🔄 تحديث التوكن
    messaging.onTokenRefresh.listen((newToken) async {
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
    print("❌ Notification error: $e");
  }
}

// 🚀 التطبيق
class QuriyatClubApp extends StatefulWidget {
  const QuriyatClubApp({super.key});

  @override
  State<QuriyatClubApp> createState() => _QuriyatClubAppState();
}

class _QuriyatClubAppState extends State<QuriyatClubApp> {

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      if (!kIsWeb) {
        await setupFirebaseMessaging();
      }
    });
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

      locale: const Locale('ar'),
      fallbackLocale: const Locale('en'),

      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },

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