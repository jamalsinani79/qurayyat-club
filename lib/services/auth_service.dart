import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://teams.quriyatclub.net/api/v1';

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String deviceToken,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    print('🚀 Sending POST to: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {
          'username': username,
          'password': password,
          'device_token': deviceToken,
        },
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
  final token = responseData['info']['token'];
print('🔑 التوكن المستلم من السيرفر: $token');

final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);

  return {
    'success': true,
    'user': responseData['info'],
    'token': responseData['info']['token'],
  };

      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'فشل تسجيل الدخول',
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {
        'success': false,
        'message': 'حدث خطأ أثناء الاتصال بالسيرفر',
      };
    }

  }

static Future<Map<String, dynamic>> forgotPassword(String email) async {
  final url = Uri.parse('$baseUrl/forgot-password');
  print('📤 Sending reset password request to: $url');
  print('📨 Email: $email');

  try {
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email},
    );

    print('📥 Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    final data = jsonDecode(response.body);
    return {
      'success': data['status'] ?? false,
      'message': data['message'] ?? 'حدث خطأ غير متوقع',
    };
  } catch (e) {
    print('❌ Exception: $e');
    return {
      'success': false,
      'message': 'فشل الاتصال بالسيرفر',
    };
  }
}


}