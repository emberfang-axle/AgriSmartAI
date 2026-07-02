import 'package:flutter/material.dart';

enum NotificationType { diseaseAlert, farmingTip, system }

extension NotificationTypeExt on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.diseaseAlert:
        return 'Disease Alert';
      case NotificationType.farmingTip:
        return 'Farming Tip';
      case NotificationType.system:
        return 'System';
    }
  }

  String get value {
    switch (this) {
      case NotificationType.diseaseAlert:
        return 'diseaseAlert';
      case NotificationType.farmingTip:
        return 'farmingTip';
      case NotificationType.system:
        return 'system';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.diseaseAlert:
        return Icons.warning_amber_rounded;
      case NotificationType.farmingTip:
        return Icons.eco_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.diseaseAlert:
        return const Color(0xFFE53935);
      case NotificationType.farmingTip:
        return const Color(0xFF2E7D32);
      case NotificationType.system:
        return const Color(0xFF1976D2);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case NotificationType.diseaseAlert:
        return const Color(0xFFFFEBEE);
      case NotificationType.farmingTip:
        return const Color(0xFFE8F5E9);
      case NotificationType.system:
        return const Color(0xFFE3F2FD);
    }
  }
}

NotificationType _typeFromString(String? value) {
  switch (value) {
    case 'diseaseAlert':
      return NotificationType.diseaseAlert;
    case 'farmingTip':
      return NotificationType.farmingTip;
    default:
      return NotificationType.system;
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: _typeFromString(json['type'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.value,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        data: data,
      );
}
