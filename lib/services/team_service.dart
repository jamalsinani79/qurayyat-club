import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_model.dart';

class TeamService {
  static const String baseUrl = 'https://teams.quriyatclub.net/api/v1';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<TeamModel?> fetchTeamInfo(String token) async {
    final url = Uri.parse('$baseUrl/team');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        return TeamModel.fromJson(responseData['info']);
      }
    } catch (e) {
      print('❌ Error fetching team info: $e');
    }

    return null;
  }

  static Future<Map<String, dynamic>> getTeamPlayers({int page = 1, String? search}) async {
  final token = await getToken();
  final queryParams = {
    'page': '$page',
    if (search != null && search.isNotEmpty) 'search': search,
  };

  final uri = Uri.parse('$baseUrl/player/associate').replace(queryParameters: queryParams);

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['status'] == true) {
      return {
        'status': true,
        'info': responseData['info'],
      };
    } else {
      return {
        'status': false,
        'message': responseData['message'] ?? 'فشل في جلب اللاعبين',
      };
    }
  } catch (e) {
    print('❌ Error fetching team players: $e');
    return {
      'status': false,
      'message': 'حدث خطأ غير متوقع',
    };
  }
}

static Future<Map<String, dynamic>> registerPlayer({
  required String cardId,
  required String name,
  required String birthDate,
  required String location,
  required String phone,
  required String playerAccept,
  required String teamAccept,
  required http.MultipartFile playerImg,
  required http.MultipartFile cardFront,
  required http.MultipartFile cardBack,
  http.MultipartFile? birthDoc,
  http.MultipartFile? fatherCheckDoc,
  http.MultipartFile? fatherIdCard,
}) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/store');
  final request = http.MultipartRequest('POST', uri);

  request.headers.addAll({
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  });

  request.fields['card_id'] = cardId;
  request.fields['name'] = name;
  request.fields['birth_date'] = birthDate;
  request.fields['location'] = location;
  request.fields['phone'] = phone;
  request.fields['player_accept'] = playerAccept;
  request.fields['team_accept'] = teamAccept;

  request.files.addAll([
    playerImg,
    cardFront,
    cardBack,
  ]);

  if (birthDoc != null) request.files.add(birthDoc);
  if (fatherCheckDoc != null) request.files.add(fatherCheckDoc);
  if (fatherIdCard != null) request.files.add(fatherIdCard);

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return {'status': true, 'info': data['info']};
    } else {
      return {'status': false, 'message': data['message'], 'errors': data['errors']};
    }
  } catch (e) {
    print('❌ Error registering player: $e');
    return {'status': false, 'message': 'حدث خطأ أثناء إرسال البيانات'};
  }
}

static Future<Map<String, dynamic>> fetchPlayerRequests(String status) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/registration-requests?status=$status');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('🟠 بيانات الحالة $status: ${response.body}'); // 🔍 للمراقبة المؤقتة

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['status'] == true) {
      final info = responseData['info'];
      return {
        'status': true,
        'info': (info is Map && info['data'] is List) ? info['data'] : [],
      };
    } else {
      return {
        'status': false,
        'message': responseData['message'] ?? 'فشل في جلب الطلبات',
      };
    }
  } catch (e) {
    print('❌ Error fetching player requests: $e');
    return {
      'status': false,
      'message': 'حدث خطأ غير متوقع',
    };
  }
}


static Future<Map<String, dynamic>> updatePlayer({
  required String cardId,
  required String name,
  required String birthDate,
  required String location,
  required String phone,
  File? playerImg,
  File? cardFront,
  File? cardBack,
  File? birthDoc,
  File? fatherCheckDoc,
  File? fatherIdCard,
}) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/update');
  final request = http.MultipartRequest('POST', uri);

  request.headers.addAll({
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  });

  // الحقول النصية
  request.fields['card_id'] = cardId;
  request.fields['name'] = name;
  request.fields['birth_date'] = birthDate;
  request.fields['location'] = location;
  request.fields['phone'] = phone;

  // الصور (اختيارية)
  if (playerImg != null) {
    request.files.add(await http.MultipartFile.fromPath('player_img', playerImg.path));
  }

  if (cardFront != null) {
    request.files.add(await http.MultipartFile.fromPath('card_identy_front', cardFront.path));
  }

  if (cardBack != null) {
    request.files.add(await http.MultipartFile.fromPath('card_identy_back', cardBack.path));
  }

  if (birthDoc != null) {
    request.files.add(await http.MultipartFile.fromPath('birth_doc', birthDoc.path));
  }

  if (fatherCheckDoc != null) {
    request.files.add(await http.MultipartFile.fromPath('father_check_doc', fatherCheckDoc.path));
  }

  if (fatherIdCard != null) {
    request.files.add(await http.MultipartFile.fromPath('father_identy_card', fatherIdCard.path));
  }

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return {'status': true, 'info': data['info']};
    } else {
      return {'status': false, 'message': data['message'], 'errors': data['errors']};
    }
  } catch (e) {
    print('❌ Error updating player: $e');
    return {'status': false, 'message': 'حدث خطأ أثناء تحديث البيانات'};
  }
}

static Future<Map<String, dynamic>> sendPlayerToClub(String cardId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/send-to-club');
  final request = http.MultipartRequest('POST', uri);

  request.headers.addAll({
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  });

  request.fields['card_id'] = cardId;

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return {'status': true, 'info': data['info']};
    } else {
      return {'status': false, 'message': data['message'] ?? 'فشل الإرسال'};
    }
  } catch (e) {
    print('❌ Error sending player to club: $e');
    return {'status': false, 'message': 'حدث خطأ أثناء الإرسال'};
  }
}

static Future<Map<String, dynamic>> deletePlayer(String cardId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/destroy');

  try {
    final response = await http.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'card_id': cardId}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return {'status': true};
    } else {
      return {'status': false, 'message': data['message'] ?? 'فشل الحذف'};
    }
  } catch (e) {
    print('❌ Error deleting player: $e');
    return {'status': false, 'message': 'حدث خطأ أثناء الحذف'};
  }
}

static Future<Map<String, dynamic>> generatePaymentUrl(String cardId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/generate-payment-url');

  try {
    print('📤 إرسال طلب الدفع برقم مدني: $cardId');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'card_id': cardId,
      },
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['status'] == true && responseData['info'] != null) {
      print('✅ رابط الدفع تم إنشاؤه: ${responseData['info']['url']}');
      return {
        'status': true,
        'info': responseData['info'],
      };
    } else {
      print('❌ فشل في إنشاء رابط الدفع: ${responseData['message']}');
      return {
        'status': false,
        'message': responseData['message'] ?? 'فشل في إنشاء رابط الدفع',
      };
    }
  } catch (e) {
    print('🟥 Error in generatePaymentUrl: $e');
    return {
      'status': false,
      'message': 'حدث خطأ أثناء الاتصال بالسيرفر',
    };
  }
}

static Future<Map<String, dynamic>> getPlayerByCardId(String cardId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/show?id=$cardId');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return {
        'status': true,
        'info': data['info'],
      };
    } else {
      return {
        'status': false,
        'message': data['message'] ?? 'فشل في جلب بيانات اللاعب',
      };
    }
  } catch (e) {
    print('🟥 Error fetching player: $e');
    return {
      'status': false,
      'message': 'خطأ في الاتصال بالسيرفر',
    };
  }
}


  static Future<Map<String, dynamic>> searchPlayerByCardId(String cardId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/loan/search?card_id=$cardId');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('📥 RESPONSE BODY: ${response.body}');
    final responseData = json.decode(response.body);

    if (response.statusCode == 200 && responseData['status'] == true) {
      return {
        'status': true,
        'info': responseData['info'],
      };
    } else {
      return {
        'status': false,
        'message': responseData['message'] ?? 'فشل في جلب بيانات اللاعب',
      };
    }
  } catch (e) {
    print('🟥 Error in searchPlayerByCardId: $e');
    return {
      'status': false,
      'message': 'حدث خطأ أثناء الاتصال بالسيرفر',
    };
  }
}

static Future<Map<String, dynamic>> storeLoanRequest({
  required String cardId,
  required String startDate,
  required String endDate,
  required String note,
}) async {
  final token = await getToken(); // موجودة مسبقًا
  final uri = Uri.parse('$baseUrl/player/loan/store');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'card_id': cardId,
        'start': startDate,
        'end': endDate,
        'note': note,
        'terms': 'true',
      },
    );

    final responseData = json.decode(response.body);
    print('📤 Loan Request Response: $responseData');

    if (response.statusCode == 200 && responseData['status'] == true) {
      return {
        'status': true,
        'info': responseData['info'],
      };
    } else {
      return {
        'status': false,
        'message': responseData['message'] ?? 'فشل إرسال الطلب',
      };
    }
  } catch (e) {
    print('🟥 Error in storeLoanRequest: $e');
    return {
      'status': false,
      'message': 'حدث خطأ أثناء إرسال الطلب',
    };
  }
}

 static Future<List<Map<String, dynamic>>> fetchLoanRequests({String? type}) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/loan${type != null ? '?type=$type' : ''}');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);

    // 🔍 تحقق من وجود 'info' وعدم كونه null
    if (response.statusCode == 200 && data['status'] == true && data['info'] != null) {
      if (data['info']['data'] is List) {
        return List<Map<String, dynamic>>.from(data['info']['data']);
      } else {
        print('⚠️ لا توجد بيانات داخل info.data');
        return [];
      }
    } else {
        print('🟥 Fetch loan failed: ${data['message'] ?? 'لا توجد رسالة خطأ'}');
      return [];
    }
  } catch (e) {
    print('🟥 Error in fetchLoanRequests: $e');
    return [];
  }
}

static Future<bool> approveLoanRequest(int requestId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/loan/action');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'loan_id': requestId,
        'action': 'accept',
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return true;
    } else {
      print('🟥 فشل في الموافقة: ${data['message']}');
      return false;
    }
  } catch (e) {
    print('🟥 خطأ أثناء الموافقة: $e');
    return false;
  }
}

static Future<bool> rejectLoanRequest(int requestId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/loan/action');

  try {
    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'loan_id': requestId,
        'action': 'reject',
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return true;
    } else {
      print('🟥 فشل في الرفض: ${data['message']}');
      return false;
    }
  } catch (e) {
    print('🟥 خطأ أثناء الرفض: $e');
    return false;
  }
}

static Future<String?> generateLoanPaymentUrl(String requestId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      print('🔴 التوكن غير موجود');
      return null;
    }

    final uri = Uri.parse('$baseUrl/player/loan/generate-payment-url');

    // ✅ رابط الرجوع إلى التطبيق بعد الدفع
    final callbackUrl = 'quriyatclub://loan-success';

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'request_id': requestId,
        'callback': callbackUrl, // 👈 إضافة هنا
      },
    );

    final data = json.decode(response.body);
    
    print("✅ رابط الدفع الذي سيتم فتحه: ${data['info']['url']}");
    print("🔁 success_url المرسل لـ Thawani: ${data['info']['success_url']}");
    print("🔁 cancel_url: ${data['info']['cancel_url']}");

    if (response.statusCode == 200 && data['status'] == true) {
      return data['info']['url']; // ✅ رابط الدفع الجاهز من السيرفر
    } else {
      print('🟥 فشل إنشاء رابط الدفع: ${data['message']}');
      return null;
    }
  } catch (e) {
    print('🟥 خطأ في generateLoanPaymentUrl: $e');
    return null;
  }
}

  
  static Future<Map<String, dynamic>?> fetchLoanRequestDetails(String requestId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      print('🔴 التوكن غير موجود');
      return null;
    }

    final uri = Uri.parse('$baseUrl/player/loan/show/$requestId');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']; // ← حسب شكل الاستجابة من API
    } else {
      print('🟥 فشل في جلب تفاصيل الطلب');
      return null;
    }
  } catch (e) {
    print('🟥 خطأ في fetchLoanRequestDetails: $e');
    return null;
  }
}

static Future<List<Map<String, dynamic>>> fetchTransferRequests({String? type}) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/transfer${type != null ? '?type=$type' : ''}');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == true && data['info'] != null) {
      if (data['info']['data'] is List) {
        return List<Map<String, dynamic>>.from(data['info']['data']);
      } else {
        print('⚠️ لا توجد بيانات داخل info.data');
        return [];
      }
    } else {
      print('🟥 فشل في جلب طلبات النقل: ${data['message'] ?? 'لا توجد رسالة'}');
      return [];
    }
  } catch (e) {
    print('🟥 خطأ أثناء جلب طلبات النقل: $e');
    return [];
  }
}


static Future<Map<String, dynamic>> searchTransferPlayer(String cardId) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/transfer/search?card_id=$cardId');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);
    print('🔍 نتيجة البحث: $data');
    return data;
  } catch (e) {
    print('🟥 خطأ أثناء البحث عن لاعب نقل: $e');
    return {'status': false, 'info': null};
  }
}

static Future<Map<String, dynamic>> submitTransferRequest({
  required String cardId,
  File? playerDoc,
  File? fatherDoc,
  File? fatherId,
}) async {
  final token = await getToken();
  final uri = Uri.parse('$baseUrl/player/transfer/store');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..fields['card_id'] = cardId;

  if (playerDoc != null) {
    request.files.add(await http.MultipartFile.fromPath('player_approve_doc', playerDoc.path));
  }
  if (fatherDoc != null) {
    request.files.add(await http.MultipartFile.fromPath('father_approve_doc', fatherDoc.path));
  }
  if (fatherId != null) {
    request.files.add(await http.MultipartFile.fromPath('father_identy_doc', fatherId.path));
  }

  try {
  final response = await request.send();
  final body = await response.stream.bytesToString();

  print('📥 Status Code: ${response.statusCode}');
  print('📥 Response Body: $body');

  return json.decode(body);
} catch (e) {
  print('🟥 خطأ في رفع طلب النقل: $e');
  return {'status': false, 'message': 'فشل في الاتصال بالخادم'};
}

}


static Future<Map<String, dynamic>> rejectTransferRequest(int requestId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  print('🟢 TOKEN = $token'); // ✅ اطبعه للتأكد

  final url = Uri.parse('https://teams.quriyatclub.net/api/v1/player/transfer/action');

  final response = await http.post(
    url,
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: {
      'transfer_id': requestId.toString(),
      'action': 'reject',
    },
  );

  print('🔴 Status Code: ${response.statusCode}');
  print('🔴 Body: ${response.body}');

  if (response.statusCode == 200) {
    return {'status': true, 'message': 'تم رفض الطلب بنجاح'};
  } else {
    return {'status': false, 'message': 'فشل رفض الطلب'};
  }
}

static Future<Map<String, dynamic>> approveTransferRequest(int requestId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final url = Uri.parse('https://teams.quriyatclub.net/api/v1/player/transfer/action');

  try {
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'transfer_id': requestId.toString(),
        'action': 'accept',
      },
    );

    print('🟢 [approveTransferRequest] Status Code: ${response.statusCode}');
    print('🟢 [approveTransferRequest] Response Body: ${response.body}');

    final data = jsonDecode(response.body);

    return {
      'status': data['status'] == true,
      'message': data['message'] ?? 'تمت العملية',
    };
  } catch (e) {
    print('🟥 [approveTransferRequest] خطأ أثناء إرسال الطلب إلى النادي: $e');
    return {
      'status': false,
      'message': 'فشل الاتصال بالخادم',
    };
  }
}

static Future<Map<String, dynamic>> generateTransferPaymentUrl(int requestId) async {
  final token = await getToken(); // ✅ استخدام التوكن تلقائيًا من SharedPreferences
  final url = Uri.parse('$baseUrl/player/transfer/generate-payment-url');

  try {
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'request_id': requestId.toString(),
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true && data['info'] != null) {
      print('✅ تم إنشاء رابط دفع النقل: ${data['info']['url']}');
      return data['info'];
    } else {
      print('🟥 فشل إنشاء رابط الدفع: ${data['message']}');
      return {
        'status': false,
        'message': data['message'] ?? 'حدث خطأ في إنشاء رابط الدفع',
      };
    }
  } catch (e) {
    print('🟥 Exception in generateTransferPaymentUrl: $e');
    return {
      'status': false,
      'message': 'حدث خطأ أثناء الاتصال بالخادم',
    };
  }
}

static Future<Map<String, dynamic>> fetchRenewalStatus() async {
  final token = await getToken();
  print('📤 استدعاء fetchRenewalStatus');
  print('🔑 التوكن: $token');

  final uri = Uri.parse('$baseUrl/renewal-status');
  print('🌐 GET $uri');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('📥 Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      final isRenewed = data['is_renewed'] ?? false;
      final isExpired = data['is_expired'] ?? false;
      final renewalStatus = data['renewal_status'];

      print('✅ isRenewed: $isRenewed | isExpired: $isExpired | status: $renewalStatus');

      return {
        'status': true,
        'isRenewed': isRenewed,
        'isExpired': isExpired,
        'renewalStatus': renewalStatus,
      };
    } else {
      print('❌ فشل في استدعاء حالة التجديد: ${data['message']}');
      return {
        'status': false,
        'message': data['message'] ?? 'فشل في التحقق من حالة التجديد',
      };
    }
  } catch (e) {
    print('🟥 Exception in fetchRenewalStatus: $e');
    return {
      'status': false,
      'message': 'حدث خطأ أثناء الاتصال بالسيرفر',
    };
  }
}



  
}

