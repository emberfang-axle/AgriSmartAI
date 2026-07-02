import 'package:flutter/material.dart';

enum AdminNotifType { diseaseAlert, newScan, weatherAlert, highRisk, system }

extension AdminNotifTypeExt on AdminNotifType {
  String get label {
    switch (this) {
      case AdminNotifType.diseaseAlert:  return 'Disease Alert';
      case AdminNotifType.newScan:       return 'New Scan';
      case AdminNotifType.weatherAlert:  return 'Weather Alert';
      case AdminNotifType.highRisk:      return 'High Risk';
      case AdminNotifType.system:        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminNotifType.diseaseAlert:  return Icons.warning_amber_rounded;
      case AdminNotifType.newScan:       return Icons.document_scanner_rounded;
      case AdminNotifType.weatherAlert:  return Icons.thunderstorm_rounded;
      case AdminNotifType.highRisk:      return Icons.emergency_rounded;
      case AdminNotifType.system:        return Icons.info_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AdminNotifType.diseaseAlert:  return const Color(0xFFE53935);
      case AdminNotifType.newScan:       return const Color(0xFF1976D2);
      case AdminNotifType.weatherAlert:  return const Color(0xFFFF6F00);
      case AdminNotifType.highRisk:      return const Color(0xFFD32F2F);
      case AdminNotifType.system:        return const Color(0xFF607D8B);
    }
  }

  Color get bgColor {
    switch (this) {
      case AdminNotifType.diseaseAlert:  return const Color(0xFFFFEBEE);
      case AdminNotifType.newScan:       return const Color(0xFFE3F2FD);
      case AdminNotifType.weatherAlert:  return const Color(0xFFFFF3E0);
      case AdminNotifType.highRisk:      return const Color(0xFFFFEBEE);
      case AdminNotifType.system:        return const Color(0xFFECEFF1);
    }
  }
}

AdminNotifType _typeFromString(String? value) {
  switch (value) {
    case 'diseaseAlert': return AdminNotifType.diseaseAlert;
    case 'newScan':      return AdminNotifType.newScan;
    case 'weatherAlert': return AdminNotifType.weatherAlert;
    case 'highRisk':     return AdminNotifType.highRisk;
    default:             return AdminNotifType.system;
  }
}

class AdminNotification {
  final String id;
  final String title;
  final String body;
  final AdminNotifType type;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic> data;

  AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) =>
      AdminNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: _typeFromString(json['type'] as String?),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        isRead: json['is_read'] as bool? ?? false,
        data: (json['data'] as Map<String, dynamic>?) ?? {},
      );
}
