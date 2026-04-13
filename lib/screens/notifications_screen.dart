import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;
  List<NotificationModel> _notifications = [];
  List<String> _readNotificationIds = [];

  @override
void initState() {
  super.initState();
  _loadReadNotifications();
  _notificationsFuture = NotificationService.fetchNotifications();
}


  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readNotificationIds = prefs.getStringList('read_notifications') ?? [];
    });
  }

  Future<void> _markAsReadLocally(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _readNotificationIds.add(id);
    await prefs.setStringList('read_notifications', _readNotificationIds);
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _clearReadNotifications() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'تنبيه هام',
      desc: 'سيتم حذف سجل الإشعارات المقروءة من هذا الجهاز فقط.\nهل تود المتابعة؟',
      btnCancelText: 'إلغاء',
      btnOkText: 'نعم، متابعة',
      btnCancelOnPress: () {},
      btnOkOnPress: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('read_notifications');
        setState(() {
          _readNotificationIds.clear();
          _notificationsFuture = NotificationService.fetchNotifications();
        });
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات'),
          backgroundColor: Colors.orange,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline), // سلة المهملات
              tooltip: 'حذف الإشعارات المقروءة',
              onPressed: _clearReadNotifications,
            ),
          ],
        ),
        body: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('حدث خطأ أثناء تحميل الإشعارات'));
            }

            if (snapshot.hasData) {
              _notifications = snapshot.data!
                  .where((n) => !_readNotificationIds.contains(n.id))
                  .toList();
            }

            if (_notifications.isEmpty) {
              return const Center(child: Text('لا توجد إشعارات حالياً'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final createdAt = notif.createdAt.split('T').first;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.notifications, color: Colors.deepOrange),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          createdAt,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        notif.body,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    onTap: () => _markAsReadLocally(notif.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
