// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  static const String _endpoint = '${AuthService.baseUrl}/notifications';

  static Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      print('📤 تم إرسال طلب الإشعارات إلى: $_endpoint');
      print('🔐 التوكن المستخدم: $token');

      final response = await http.get(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📥 كود الاستجابة: ${response.statusCode}');
      print('📥 الجسم المستلم: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List items = data['info']['data'];
        print('✅ تم جلب ${items.length} إشعار(ات)');
        
        for (var item in items) {
          print('🔔 إشعار: ${item['title']} - النوع: ${item['data']?['type']}');
        }

        return items.map((e) => NotificationModel.fromJson(e)).toList();
      } else {
        print('❌ فشل في جلب الإشعارات: الحالة ${data['status']}');
        throw Exception('فشل في جلب الإشعارات');
      }
    } catch (e) {
      print('💥 خطأ أثناء الاتصال بـ NotificationService: $e');
      rethrow;
    }
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final url = Uri.parse('$_endpoint/$notificationId/read');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📤 تم إرسال طلب قراءة الإشعار $notificationId');
      print('📥 كود الاستجابة: ${response.statusCode}');
      print('📥 الجسم المستلم: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('فشل في تحديث الإشعار كمقروء');
      }
    } catch (e) {
      print('💥 خطأ أثناء تحديث حالة الإشعار: $e');
      rethrow;
    }
  }
}
