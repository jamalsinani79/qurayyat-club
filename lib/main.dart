import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'routes/app_pages.dart';

// 🔔 الخلفية
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 [خلفية] تم استلام إشعار: ${message.messageId}");
}

// قناة الإشعارات
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupNotificationChannel() {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'الإشعارات الهامة',
    description: 'قناة مخصصة للإشعارات ذات الأهمية العالية',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
      await Future.delayed(const Duration(seconds: 2));

      // 🔐 طلب الإذن
      await FirebaseMessaging.instance.requestPermission();

      // 🔔 تهيئة القناة (Android فقط)
      setupNotificationChannel();

      // 🔔 local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
          initializationSettings);

      // 🔔 background
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 🔔 foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ??
            message.data['title'] ??
            '📩 إشعار جديد';

        final body = message.notification?.body ??
            message.data['body'] ??
            'لا يوجد محتوى';

        flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'الإشعارات الهامة',
              channelDescription:
                  'قناة مخصصة للإشعارات ذات الأهمية العالية',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      });

      String? token = await FirebaseMessaging.instance.getToken();
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

      home: Scaffold(
        body: Center(
          child: Text("Main Loaded ✅"),
        ),
      ),
    );
  }
}