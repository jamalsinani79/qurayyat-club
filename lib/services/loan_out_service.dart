import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoanOutService {
  static const String baseUrl = 'https://teams.quriyatclub.net/api/v1';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // المفتاح حسب تخزينك
  }

  static Future<List<Map<String, dynamic>>> fetchLoanOutPlayers() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('لم يتم العثور على التوكن. يرجى تسجيل الدخول أولاً.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/player/out-loan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('🔗 API CALL: $baseUrl/player/out-loan');
    print('📤 Token: $token');
    print('📥 Response Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List items = data['info']['data'];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('فشل في جلب لاعبي الإعارة الخارجية');
    }
  }

  static Future<bool> addLoanOutPlayer({
  required String cardId,
  required String name,
  required String birthDate,
  required String startDate,
  required String endDate,
  required File sportImage,
  required File frontImage,
  required File letterImage,
}) async {
  final token = await _getToken();
  if (token == null) {
    throw Exception('لم يتم العثور على التوكن. يرجى تسجيل الدخول أولاً.');
  }

  final uri = Uri.parse('$baseUrl/player/out-loan-store');
  final request = http.MultipartRequest('POST', uri);
  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'application/json';

  request.fields['card_id'] = cardId;
  request.fields['name'] = name;
  request.fields['birth_date'] = birthDate;
  request.fields['start'] = startDate;
  request.fields['end'] = endDate;

  request.files.add(await http.MultipartFile.fromPath(
    'sport_image',
    sportImage.path,
    contentType: MediaType('image', 'jpeg'),
  ));
  request.files.add(await http.MultipartFile.fromPath(
    'front_image',
    frontImage.path,
    contentType: MediaType('image', 'jpeg'),
  ));
  request.files.add(await http.MultipartFile.fromPath(
    'letter_image',
    letterImage.path,
    contentType: MediaType('image', 'jpeg'),
  ));

  final response = await request.send();
  final body = await response.stream.bytesToString();

  print('📤 Add OutLoan Response Code: ${response.statusCode}');
  print('📥 Add OutLoan Response Body: $body');

  return response.statusCode == 200;
}

static Future<bool> sendLoanOutToClub(int outLoanId) async {
  final token = await _getToken();
  if (token == null) throw Exception('التوكن غير موجود');

  final url = Uri.parse('$baseUrl/player/out-loan/send-to-club');
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: json.encode({'out_loan_id': outLoanId}),
  );

  print('📤 إرسال الإعارة الخارجية: ${response.statusCode} - ${response.body}');

  return response.statusCode == 200;
}

static Future<bool> deleteLoanOutPlayer(int outLoanId) async {
  final token = await _getToken();
  if (token == null) throw Exception('التوكن غير موجود');

  final uri = Uri.parse('$baseUrl/player/out-loan/destroy');

  final request = http.Request('DELETE', uri)
    ..headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    })
    ..bodyFields = {
      'out_loan_id': outLoanId.toString(),
    };

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  print('🗑️ حذف الإعارة الخارجية: ${response.statusCode} - ${response.body}');

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return json['status'] == true;
  } else {
    return false;
  }
}

static Future<String?> generatePaymentUrl(int outLoanId) async {
  final token = await _getToken();
  if (token == null) {
    throw Exception('التوكن غير موجود');
  }

  final url = Uri.parse('$baseUrl/player/out-loan/generate-payment-url');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'id': outLoanId}),
  );

  print('💳 طلب رابط الدفع للإعارة الخارجية: ${response.statusCode} - ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == true && data['info'] != null) {
      return data['info']['url'];
    }
  }

  return null;
}

static Future<Map<String, dynamic>?> getLoanOutPlayer(int id) async {
  final token = await _getToken();
  if (token == null) throw Exception('التوكن غير موجود');

  final url = Uri.parse('$baseUrl/player/out-loan/$id');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  print('📥 API Status Code: ${response.statusCode}');
  print('📥 API Response: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == true) {
      return data['info'];
    }
  }

  return null;
}

static Future<bool> sendPaymentLinkToEmail(int id) async {
  final token = await _getToken();

  if (token == null) {
    throw Exception('التوكن غير موجود');
  }

  final response = await http.post(
    Uri.parse('$baseUrl/send-out-loan-payment-link'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'id': id,
    }),
  );

  print('📤 إرسال رابط الدفع: ${response.statusCode}');
  print('📥 Response: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['status'] == true;
  }

  return false;
}

}
