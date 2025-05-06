import 'dart:convert';

class AppNotification {
  final String? id;
  final String? title;
  final String? body;
  final String? image;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? readAt;
  final String? createdAt;
  
  AppNotification({
    this.id,
    this.title,
    this.body,
    this.image,
    this.type,
    this.data,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });
  
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? dataMap;
    if (json['data'] != null && json['data'] is String) {
      try {
        dataMap = Map<String, dynamic>.from(jsonDecode(json['data']));
      } catch (e) {
        dataMap = null;
      }
    } else if (json['data'] != null) {
      dataMap = Map<String, dynamic>.from(json['data']);
    }
    
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      image: json['image'],
      type: json['type'],
      data: dataMap,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      readAt: json['read_at'],
      createdAt: json['created_at'],
    );
  }
  
  static List<AppNotification> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => AppNotification.fromJson(json)).toList();
  }
}