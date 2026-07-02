import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../models/disease_result.dart';

class StorageService {
  static const _notifKey = 'agrismart_notifications';
  static const _historyKey = 'agrismart_detection_history';

  // ── Notifications ───────────────────────────────────────────────────────────

  static Future<List<NotificationModel>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_notifKey) ?? [];
    return raw
        .map((s) {
          try {
            return NotificationModel.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<NotificationModel>()
        .toList();
  }

  static Future<void> saveNotifications(
      List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notifKey, raw);
  }

  // ── Detection history ───────────────────────────────────────────────────────

  static Future<List<DiseaseResult>> loadDetectionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((s) {
          try {
            return DiseaseResult.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<DiseaseResult>()
        .toList();
  }

  static Future<void> saveDetectionHistory(List<DiseaseResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep last 50 detections
    final trimmed = history.take(50).toList();
    final raw = trimmed.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_historyKey, raw);
  }

  static Future<void> addDetection(DiseaseResult result) async {
    final history = await loadDetectionHistory();
    history.insert(0, result);
    await saveDetectionHistory(history);
  }
}
