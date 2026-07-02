import 'package:flutter/material.dart';

class WeatherData {
  final double temperature;
  final int humidity;
  final int precipitationProbability;
  final double windSpeed;
  final int weatherCode;
  final String condition;
  final String location;
  final DateTime updatedAt;
  final String source;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.weatherCode,
    required this.condition,
    required this.location,
    required this.updatedAt,
    this.source = 'open-meteo',
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        temperature:
            (json['temperature'] as num?)?.toDouble() ?? 29.0,
        humidity: json['humidity'] as int? ?? 75,
        precipitationProbability:
            json['precipitation_probability'] as int? ?? 30,
        windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 10.0,
        weatherCode: json['weather_code'] as int? ?? 0,
        condition: json['condition'] as String? ?? 'Unknown',
        location: json['location'] as String? ?? 'New Bataan',
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
                DateTime.now(),
        source: json['source'] as String? ?? 'open-meteo',
      );

  IconData get icon {
    if (weatherCode == 0) return Icons.wb_sunny_rounded;
    if (weatherCode <= 3) return Icons.cloud_rounded;
    if (weatherCode <= 48) return Icons.foggy;
    if (weatherCode <= 67) return Icons.grain_rounded;
    if (weatherCode <= 82) return Icons.umbrella_rounded;
    return Icons.thunderstorm_rounded;
  }

  Color get iconColor {
    if (weatherCode == 0) return const Color(0xFFFDD835);
    if (weatherCode <= 3) return const Color(0xFF90A4AE);
    if (weatherCode <= 48) return const Color(0xFFB0BEC5);
    return const Color(0xFF1976D2);
  }

  String get riskDescription {
    if (humidity > 88 && precipitationProbability > 65) {
      return 'High disease risk — favorable for Leaf Blast & Blight';
    }
    if (humidity > 78 || precipitationProbability > 50) {
      return 'Moderate disease risk — monitor fields closely';
    }
    return 'Low disease risk — current conditions are manageable';
  }

  Color get riskColor {
    if (humidity > 88 && precipitationProbability > 65) {
      return const Color(0xFFE53935);
    }
    if (humidity > 78 || precipitationProbability > 50) {
      return const Color(0xFFFF6F00);
    }
    return const Color(0xFF2E7D32);
  }
}
