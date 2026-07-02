import 'package:flutter/material.dart';

class DiseaseResult {
  final String id;
  final String disease;
  final double confidence;
  final String severity;
  final String colorHex;
  final String treatment;
  final String prevention;
  final DateTime timestamp;

  const DiseaseResult({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.colorHex,
    required this.treatment,
    required this.prevention,
    required this.timestamp,
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      id: json['id'] as String? ?? '',
      disease: json['disease'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'Unknown',
      colorHex: json['color'] as String? ?? '#2E7D32',
      treatment: json['treatment'] as String? ?? '',
      prevention: json['prevention'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

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
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
        return const Color(0xFFFF6F00);
      case 'low':
        return const Color(0xFFFDD835);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'disease': disease,
        'confidence': confidence,
        'severity': severity,
        'color': colorHex,
        'treatment': treatment,
        'prevention': prevention,
        'timestamp': timestamp.toIso8601String(),
      };
}
