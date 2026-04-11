import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

import 'screens/auth/animated_logo_screen.dart';
import 'routes/app_pages.dart';

// 🔔 background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// 🔔 local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupNotificationChannel() {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'الإشعارات الهامة',
    description: 'قناة مخصصة للإشعارات',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase لكل المنصات (الآن آمن)
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

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
    initNotifications();
  }

  Future<void> initNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 🔐 طلب الإذن (مهم لـ iOS)
      await messaging.requestPermission();

      // 🔔 Android channel
      if (Platform.isAndroid) {
        setupNotificationChannel();

        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);

        await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      }

      // 🔔 foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? '📩 إشعار';
        final body = message.notification?.body ?? '';

        if (Platform.isAndroid) {
          flutterLocalNotificationsPlugin.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title,
            body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'الإشعارات الهامة',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      // 🔑 token
      String? token = await messaging.getToken();
      print("FCM TOKEN: $token");

    } catch (e) {
      print("Notification error: $e");
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
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },

      home: const AnimatedLogoScreen(),
      getPages: AppPages.routes,
    );
  }
}