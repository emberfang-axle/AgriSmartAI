import 'package:flutter/material.dart';

import '../models/weather_data.dart';
import '../services/api_service.dart';

class WeatherProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  WeatherData? weather;
  bool loading = false;
  String? error;

  Future<void> fetchWeather() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      weather = await _api.getWeather();
    } catch (e) {
      error = 'Weather unavailable';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchWeather();
}
