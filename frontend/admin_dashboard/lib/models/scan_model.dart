import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ScanModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String farmerBarangay;
  final String disease;
  final double confidence;
  final String severity;
  final String colorHex;
  final String treatment;
  final String prevention;
  final String status;
  final DateTime createdAt;
  final double? weatherTemp;
  final int? weatherHumidity;
  final int? weatherPrecip;
  final String? weatherCondition;

  const ScanModel({
    required this.id,
    required this.farmerId,
    this.farmerName = '',
    this.farmerBarangay = '',
    required this.disease,
    required this.confidence,
    this.severity = '',
    this.colorHex = '#2E7D32',
    this.treatment = '',
    this.prevention = '',
    this.status = 'pending',
    required this.createdAt,
    this.weatherTemp,
    this.weatherHumidity,
    this.weatherPrecip,
    this.weatherCondition,
  });

  factory ScanModel.fromJson(Map<String, dynamic> json) => ScanModel(
        id: json['id'] as String? ?? '',
        farmerId: json['farmer_id'] as String? ?? '',
        farmerName: json['farmer_name'] as String? ?? '',
        farmerBarangay: json['farmer_barangay'] as String? ?? '',
        disease: json['disease'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        severity: json['severity'] as String? ?? '',
        colorHex: json['color'] as String? ?? '#2E7D32',
        treatment: json['treatment'] as String? ?? '',
        prevention: json['prevention'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        weatherTemp: (json['weather_temp'] as num?)?.toDouble(),
        weatherHumidity: json['weather_humidity'] as int?,
        weatherPrecip: json['weather_precip'] as int?,
        weatherCondition: json['weather_condition'] as String?,
      );

  bool get isHealthy => disease == 'Healthy';

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'high':   return const Color(0xFFE53935);
      case 'medium': return const Color(0xFFFF6F00);
      case 'low':    return const Color(0xFFFDD835);
      default:       return const Color(0xFF2E7D32);
    }
  }

  Color get statusColor =>
      status == 'reviewed' ? const Color(0xFF2E7D32) : const Color(0xFF1976D2);
}
