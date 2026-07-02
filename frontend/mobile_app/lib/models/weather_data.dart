class WeatherData {
  final double temperature;
  final int humidity;
  final int precipitationProbability;
  final double windSpeed;
  final String condition;
  final int weatherCode;
  final DateTime lastUpdated;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.condition,
    required this.weatherCode,
    required this.lastUpdated,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: json['humidity'] as int,
      precipitationProbability: json['precipitation_probability'] as int,
      windSpeed: (json['wind_speed'] as num).toDouble(),
      condition: json['condition'] as String,
      weatherCode: json['weather_code'] as int? ?? 0,
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // Disease risk level based on weather conditions
  String get diseaseRisk {
    if (humidity >= 85 && precipitationProbability >= 60) return 'High';
    if (humidity >= 75 && precipitationProbability >= 40) return 'Moderate';
    return 'Low';
  }

  // Icon character for current condition
  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌦️';
    return '⛈️';
  }
}
