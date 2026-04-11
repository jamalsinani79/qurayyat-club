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
    'high_importance_channel', // يجب أن تطابق القيمة في manifest
    'الإشعارات الهامة',
    description: 'قناة مخصصة للإشعارات ذات الأهمية العالية',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔐 إذن الإشعارات
  await FirebaseMessaging.instance.requestPermission();

  // 🛠️ تهيئة قناة الإشعارات
  setupNotificationChannel();

  // 🛠️ تهيئة local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // 🔔 استقبال في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔔 استقبال في الواجهة
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
   final title = message.notification?.title ?? message.data['title'] ?? '📩 إشعار جديد';
   final body = message.notification?.body ?? message.data['body'] ?? 'لا يوجد محتوى';


    print('📥 إشعار Foreground من Firebase');
    print('🔹 title: $title');
    print('🔹 body: $body');
    print('🔹 data: ${message.data}');
    print('📦 الرسالة الكاملة من Firebase: ${message.toMap()}');


    flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'الإشعارات الهامة',
          channelDescription: 'قناة مخصصة للإشعارات ذات الأهمية العالية',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  });

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.black,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
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
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
