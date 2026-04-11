import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/club_model.dart';

class ClubService {
  static const String baseUrl = 'https://teams.quriyatclub.net/api/v1/club';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<ClubModel?> fetchClubInfo() async {
    final token = await _getToken();

    if (token == null) {
      print("❌ لم يتم العثور على التوكن");
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/info'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('📤 Club Info Request: $baseUrl/info');
    print('📥 Status Code: ${response.statusCode}');
    print('📥 Response: ${response.body}');

    if (response.statusCode == 200 &&
        response.headers['content-type']?.contains('application/json') == true) {
      final json = jsonDecode(response.body);
      return ClubModel.fromJson(json['info']);
    } else {
      print("⚠️ استجابة غير متوقعة من السيرفر");
      return null;
    }
  }
}
