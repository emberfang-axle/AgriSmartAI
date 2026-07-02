import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/analytics_model.dart';
import '../models/farmer_model.dart';
import '../models/notification_model.dart';
import '../models/scan_model.dart';
import '../models/weather_model.dart';

/// Central API client for the admin dashboard.
/// All calls target http://localhost:8000 (Flask backend).
class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static const Duration _timeout = Duration(seconds: 15);

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('GET $path failed: ${resp.statusCode}');
  }

  Future<List<dynamic>> _getList(String path,
      {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode == 200) return jsonDecode(resp.body) as List<dynamic>;
    throw Exception('GET $path failed: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final resp = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    if (resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('POST $path failed: ${resp.statusCode}');
  }

  Future<void> _put(String path) async {
    await http.put(Uri.parse('$baseUrl$path')).timeout(_timeout);
  }

  Future<void> _delete(String path) async {
    await http.delete(Uri.parse('$baseUrl$path')).timeout(_timeout);
  }

  // ── Weather ──────────────────────────────────────────────────────────────────

  Future<WeatherData> getWeather() async {
    final data = await _get('/api/weather');
    return WeatherData.fromJson(data);
  }

  // ── Analytics ────────────────────────────────────────────────────────────────

  Future<AnalyticsOverview> getOverview() async {
    final data = await _get('/api/analytics/overview');
    return AnalyticsOverview.fromJson(data);
  }

  Future<List<TrendPoint>> getTrends({int days = 30}) async {
    final list = await _getList('/api/analytics/trends',
        params: {'days': days.toString()});
    return list.map((e) => TrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MonthlyPoint>> getMonthly() async {
    final list = await _getList('/api/analytics/monthly');
    return list.map((e) => MonthlyPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getPredictions() async {
    return _get('/api/analytics/predictions');
  }

  Future<List<DiseaseRank>> getMostCommon({int limit = 6}) async {
    final list = await _getList('/api/analytics/most-common',
        params: {'limit': limit.toString()});
    return list.map((e) => DiseaseRank.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Farmers ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getFarmers({
    int page = 1,
    int perPage = 10,
    String search = '',
    String barangay = '',
  }) async {
    return _get('/api/farmers', params: {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search.isNotEmpty) 'search': search,
      if (barangay.isNotEmpty) 'barangay': barangay,
    });
  }

  Future<FarmerModel> getFarmer(String id) async {
    final data = await _get('/api/farmers/$id');
    return FarmerModel.fromJson(data);
  }

  Future<FarmerModel> createFarmer(Map<String, String> fields) async {
    final data = await _post('/api/farmers', fields);
    return FarmerModel.fromJson(data);
  }

  Future<void> updateFarmer(String id, Map<String, String> fields) async {
    await http
        .put(
          Uri.parse('$baseUrl/api/farmers/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(fields),
        )
        .timeout(_timeout);
  }

  Future<void> deleteFarmer(String id) async => _delete('/api/farmers/$id');

  Future<Map<String, dynamic>> getFarmerScans(
    String farmerId, {
    int page = 1,
    int perPage = 10,
    String disease = '',
    String dateFrom = '',
    String dateTo = '',
    String sort = 'newest',
    String search = '',
  }) async {
    return _get('/api/farmers/$farmerId/scans', params: {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (disease.isNotEmpty) 'disease': disease,
      if (dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo.isNotEmpty) 'date_to': dateTo,
      'sort': sort,
      if (search.isNotEmpty) 'search': search,
    });
  }

  // ── Scans ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getScans({
    int page = 1,
    int perPage = 20,
    String disease = '',
    String farmerId = '',
    String search = '',
    String sort = 'newest',
  }) async {
    return _get('/api/scans', params: {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (disease.isNotEmpty) 'disease': disease,
      if (farmerId.isNotEmpty) 'farmer_id': farmerId,
      if (search.isNotEmpty) 'search': search,
      'sort': sort,
    });
  }

  // ── Admin notifications ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminNotifications({
    int page = 1,
    int perPage = 20,
    String type = '',
    bool unreadOnly = false,
    String since = '',
  }) async {
    return _get('/api/admin/notifications', params: {
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (type.isNotEmpty) 'type': type,
      if (unreadOnly) 'unread': 'true',
      if (since.isNotEmpty) 'since': since,
    });
  }

  Future<int> getAdminUnreadCount() async {
    final data = await _get('/api/admin/notifications/unread-count');
    return data['count'] as int? ?? 0;
  }

  Future<void> markAdminNotifRead(String id) async =>
      _put('/api/admin/notifications/$id/read');

  Future<void> markAllAdminNotifsRead() async =>
      _put('/api/admin/notifications/read-all');

  Future<void> deleteAdminNotif(String id) async =>
      _delete('/api/admin/notifications/$id');

  Future<void> clearAllAdminNotifs() async =>
      _delete('/api/admin/notifications');

  // ── Health ───────────────────────────────────────────────────────────────────

  Future<bool> isServerReachable() async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
