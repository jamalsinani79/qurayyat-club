import 'dart:convert';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String createdAt;
  final Map<String, dynamic> data; // ✅ أضف هذا السطر

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.data, // ✅ واجب في الكونستركتر
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['created_at'] ?? '',
      data: json['data'] ?? {}, // ✅ بدون jsonDecode
    );
  }
}
