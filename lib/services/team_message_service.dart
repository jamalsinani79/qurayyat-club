import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TeamMessageService {
  static Future<Map<String, dynamic>> fetchMessages({
  required bool incoming,
  String? query,
  int page = 1,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  print('🔄 Loading ${incoming ? "الواردة" : "الصادرة"} - الصفحة $page');
  print('🔎 Search Query: ${query ?? "(فارغة)"}');

  if (token == null) {
    print('❌ Missing token');
    return {
      'messages': [],
      'currentPage': 1,
      'lastPage': 1,
    };
  }

  // بناء الرابط مع المعلمات
  final queryParams = {
    'type': incoming ? 'received' : 'sent',
    'page': page.toString(),
    if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
  };

  final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/team/messages')
      .replace(queryParameters: queryParams);

  print('🌐 Request URL: $uri');

  try {
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    print('📥 Response status: ${res.statusCode}');
    print('📥 Response body: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == true) {
        final info = data['info'];
        return {
          'messages': List<Map<String, dynamic>>.from(info['data'] ?? []),
          'currentPage': info['current_page'] ?? 1,
          'lastPage': info['last_page'] ?? 1,
        };
      } else {
        print('⚠️ API returned false status');
      }
    } else {
      print('❌ HTTP error: ${res.statusCode}');
    }
  } catch (e) {
    print('❗ Exception: $e');
  }

  return {
    'messages': [],
    'currentPage': 1,
    'lastPage': 1,
  };
}


  
    static Future<Map<String, dynamic>> sendMessage({
  required String subject,
  required String body,
  required String team,
  required int target,
  File? file,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    return {'status': false, 'message': 'يرجى تسجيل الدخول أولًا'};
  }

  final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/team/messages');
  var request = http.MultipartRequest('POST', uri);

  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'application/json';

  request.fields['subject'] = subject;
  request.fields['body'] = body;
  request.fields['team'] = team;
  request.fields['target'] = target.toString(); // 1 = رئيس الفريق، 2 = أمين السر

  if (file != null) {
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
  }

  try {
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);

    return {
      'status': data['status'] == true,
      'message': data['message'] ?? 'تم الإرسال',
      'info': data['info']
    };
  } catch (e) {
    print('❗ Error while sending message: $e');
    return {'status': false, 'message': 'حدث خطأ أثناء إرسال الرسالة'};
  }
}

static Future<List<Map<String, dynamic>>> fetchAvailableTeams() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/team/other');

  try {
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    print('📡 fetchAvailableTeams status: ${res.statusCode}');
    print('📡 fetchAvailableTeams body: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == true && data['info'] != null) {
        return List<Map<String, dynamic>>.from(data['info']);
      }
    }
  } catch (e) {
    print('❗ fetchAvailableTeams error: $e');
  }

  return [];
}


static Future<List<Map<String, dynamic>>> fetchReceivers() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

 final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/team/other');

  try {
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['info']);
      }
    }
  } catch (e) {
    print('❗ fetchReceivers error: $e');
  }

  return [];
}

static Future<void> markAsRead(int messageId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    print('❌ لم يتم العثور على التوكن');
    return;
  }

  final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/team/message/update-status');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': messageId,
        'status': 1,
      }),
    );

    print('📨 تحديث حالة الرسالة status: ${response.statusCode}');
    print('📨 body: ${response.body}');

    if (response.statusCode != 200) {
      print('⚠️ فشل تحديث حالة الرسالة');
    }
  } catch (e) {
    print('❗ حدث خطأ أثناء تحديث حالة الرسالة: $e');
  }
}

static Future<Map<String, dynamic>> fetchClubMessages({
  required bool incoming,
  String? query,
  int page = 1,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    print('❌ لا يوجد توكن');
    return {
      'messages': [],
      'currentPage': 1,
      'lastPage': 1,
    };
  }

  final queryParams = {
    'type': incoming ? 'received' : 'sent',
    'page': page.toString(),
    if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
  };

  final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/club/messages')
      .replace(queryParameters: queryParams);

  print('📨 تحميل رسائل النادي - $uri');

  try {
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    print('📥 status: ${res.statusCode}');
    print('📥 body: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data['status'] == true) {
        final info = data['info'];

        print('📦 البيانات المستلمة من API:');
        print(info['data']);

        if (info['data'] is List) {
          for (var i = 0; i < info['data'].length; i++) {
            print('📌 العنصر رقم $i: ${info['data'][i]}');
            print('📌 النوع: ${info['data'][i].runtimeType}');
          }
        } else {
          print('⚠️ info["data"] ليست List');
        }

        return {
          'messages': List<Map<String, dynamic>>.from(info['data'] ?? []),
          'currentPage': info['current_page'] ?? 1,
          'lastPage': info['last_page'] ?? 1,
        };
      }
    }
  } catch (e) {
    print('❗ Exception in fetchClubMessages: $e');
  }

  return {
    'messages': [],
    'currentPage': 1,
    'lastPage': 1,
  };
}

static Future<Map<String, dynamic>> sendMessageToClub({
  required String subject,
  required String body,
  required String target, // هذا هو user_id الذي يمثل رئيس النادي أو الأمين
  File? file,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    return {'status': false, 'message': 'يرجى تسجيل الدخول أولًا'};
  }

  final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/club/messages');
  var request = http.MultipartRequest('POST', uri);

  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'application/json';

  request.fields['subject'] = subject;
  request.fields['body'] = body;
  request.fields['target'] = target;

  if (file != null) {
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
  }

  try {
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body);

    return {
      'status': data['status'] == true,
      'message': data['message'] ?? 'تم الإرسال',
      'info': data['info']
    };
  } catch (e) {
    print('❗ Error while sending message to club: $e');
    return {'status': false, 'message': 'حدث خطأ أثناء إرسال الرسالة إلى النادي'};
  }
}

static Future<Map<String, dynamic>?> fetchMessageById(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final uri = Uri.parse('https://teams.quriyatclub.net/api/v1/team/messages?id=$id');
  print('📡 طلب تفاصيل الرسالة برقم: $id');
  print('🔐 التوكن: $token');
  print('🌐 Endpoint: $uri');

  try {
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    print('📥 Status Code: ${res.statusCode}');
    print('📥 Response Body: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print('✅ تم فك JSON بنجاح');
      print('📊 محتوى data["status"]: ${data['status']}');
      print('📊 محتوى data["info"]: ${data['info']}');

      if (data['status'] == true) {
        final info = data['info'];
        if (info == null) {
          print('⚠️ البيانات info فارغة!');
        } else {
          print('✅ تم جلب بيانات الرسالة بنجاح');
          print('🆔 ID: ${info['id']}');
          print('📩 العنوان: ${info['subject']}');
          print('✉️ المحتوى: ${info['body']}');
        }
        return info;
      } else {
        print('❌ الحالة false من السيرفر');
      }
    } else {
      print('❌ فشل الاتصال: ${res.statusCode}');
    }
  } catch (e) {
    print('❗ استثناء أثناء الاتصال: $e');
  }

  return null;
}


}



