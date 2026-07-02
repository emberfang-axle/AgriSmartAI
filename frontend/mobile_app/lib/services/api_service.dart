import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/disease_result.dart';
import '../models/notification_model.dart';
import '../models/weather_data.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    // Android emulator routes to host machine via 10.0.2.2
    return 'http://10.0.2.2:8000';
  }

  // ── Weather ─────────────────────────────────────────────────────────────────

  Future<WeatherData> getWeather() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/weather'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return WeatherData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Weather fetch failed (${response.statusCode})');
  }

  // ── Disease detection ───────────────────────────────────────────────────────

  Future<DiseaseResult> detectDisease(Uint8List imageBytes) async {
    final uri = Uri.parse('$baseUrl/api/detect');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'leaf_capture.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return DiseaseResult.fromJson(jsonDecode(body) as Map<String, dynamic>);
    }
    throw Exception(
        'Detection failed (${streamedResponse.statusCode}): $body');
  }

  Future<List<DiseaseResult>> getDetectionHistory() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/detections'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => DiseaseResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Chat ────────────────────────────────────────────────────────────────────

  Future<String> chat(String message) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['response'] as String? ?? '';
    }
    throw Exception('Chat failed (${response.statusCode})');
  }

  // ── Notifications ───────────────────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/notifications'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> markNotificationRead(String id) async {
    await http
        .put(Uri.parse('$baseUrl/api/notifications/$id/read'))
        .timeout(const Duration(seconds: 10));
  }

  Future<void> markAllNotificationsRead() async {
    await http
        .put(Uri.parse('$baseUrl/api/notifications/read-all'))
        .timeout(const Duration(seconds: 10));
  }

  Future<void> deleteNotification(String id) async {
    await http
        .delete(Uri.parse('$baseUrl/api/notifications/$id'))
        .timeout(const Duration(seconds: 10));
  }

  Future<void> clearAllNotifications() async {
    await http
        .delete(Uri.parse('$baseUrl/api/notifications'))
        .timeout(const Duration(seconds: 10));
  }

  // ── Health ──────────────────────────────────────────────────────────────────

  Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
