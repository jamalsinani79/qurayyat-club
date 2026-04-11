import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssistantService {
  static const String apiBase = 'https://teams.quriyatclub.net/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// جلب بيانات الجهاز الفني المرتبط بالفريق
  static Future<Map<String, dynamic>> fetchAssistants() async {
    final token = await getToken();
    final url = Uri.parse('$apiBase/technical-team/');

    print('📥 [GET] $url');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📦 Response Code: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final list = data['info']['data'] ?? [];
        return {'status': true, 'info': List<Map<String, dynamic>>.from(list)};
      } else {
        return {'status': false, 'message': data['message'] ?? 'فشل في جلب البيانات'};
      }
    } catch (e) {
      print('❌ Error fetching assistants: $e');
      return {'status': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  /// إضافة عضو جديد في الجهاز الفني
  static Future<Map<String, dynamic>> addAssistant({
    required String cardId,
    required String name,
    required String birthDate,
    required String role,
    required String startDate,
    required String endDate,
    required File sportImage,
    required File frontImage,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$apiBase/technical-team/store');

    print('📤 [POST] $url');
    print('📤 بيانات الإرسال: $cardId, $name, $birthDate, role: $role');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['card_id'] = cardId
      ..fields['name'] = name
      ..fields['birthdate'] = birthDate
      ..fields['role'] = role
      ..fields['start_date'] = startDate
      ..fields['end_date'] = endDate;

    request.files.add(await http.MultipartFile.fromPath(
      'sport_image',
      sportImage.path,
      contentType: MediaType('image', 'jpeg'),
      filename: basename(sportImage.path),
    ));

    request.files.add(await http.MultipartFile.fromPath(
      'front_image',
      frontImage.path,
      contentType: MediaType('image', 'jpeg'),
      filename: basename(frontImage.path),
    ));

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('📡 Response Code: ${response.statusCode}');
      print('📡 Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        return {'status': true, 'info': data['info']};
      } else {
        return {
          'status': false,
          'message': data['message'] ?? 'فشل في إضافة العضو',
          'errors': data['errors'] ?? {}
        };
      }
    } catch (e) {
      print('❌ Error adding assistant: $e');
      return {'status': false, 'message': 'حدث خطأ أثناء إرسال البيانات'};
    }
  }

  static Future<Map<String, dynamic>> deleteAssistant(int id) async {
  final token = await getToken(); // إذا عندك توكن مخزن
  final response = await http.delete(
     Uri.parse('$apiBase/technical-team/$id'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> updateAssistant({
  required int technicalId,
  required String cardId,
  required String name,
  required String birthDate,
  required String role,
}) async {
  final token = await getToken();
  final url = Uri.parse('$apiBase/technical-team/update');

  final response = await http.patch(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
    body: {
      'technical_id': technicalId.toString(),
      'card_id': cardId,
      'name': name,
      'birthdate': birthDate,
      'role': role,
    },
  );

  return json.decode(response.body);
}

}
