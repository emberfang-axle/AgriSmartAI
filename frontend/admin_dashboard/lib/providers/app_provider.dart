import 'dart:async';

import 'package:flutter/material.dart';

import '../models/analytics_model.dart';
import '../models/notification_model.dart';
import '../models/weather_model.dart';
import '../services/api_service.dart';

/// Central state provider for the admin dashboard.
/// Handles weather refresh, notification polling, and dashboard overview.
class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── State ──────────────────────────────────────────────────────────────────
  WeatherData? weather;
  AnalyticsOverview? overview;
  List<AdminNotification> notifications = [];
  int unreadCount = 0;

  bool initialized = false;
  bool loadingOverview = false;
  bool loadingWeather = false;
  bool loadingNotifications = false;
  bool hasNewNotifications = false;
  String? error;

  // Polling timer for real-time notification updates
  Timer? _pollTimer;
  DateTime _lastPollAt = DateTime.now().subtract(const Duration(hours: 1));

  // ── Init & dispose ─────────────────────────────────────────────────────────

  Future<void> init() async {
    await Future.wait([
      refreshWeather(),
      refreshOverview(),
      refreshNotifications(),
    ]);
    initialized = true;
    notifyListeners();
    _startPolling();
  }

  void _startPolling() {
    // Poll every 15 seconds for new notifications and overview stats
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final prev = unreadCount;
      await _pollNotifications();
      if (unreadCount > prev) {
        hasNewNotifications = true;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Weather ────────────────────────────────────────────────────────────────

  Future<void> refreshWeather() async {
    loadingWeather = true;
    notifyListeners();
    try {
      weather = await _api.getWeather();
      error = null;
    } catch (e) {
      error = 'Weather unavailable';
    } finally {
      loadingWeather = false;
      notifyListeners();
    }
  }

  // ── Overview ───────────────────────────────────────────────────────────────

  Future<void> refreshOverview() async {
    loadingOverview = true;
    notifyListeners();
    try {
      overview = await _api.getOverview();
      unreadCount = overview?.adminUnread ?? unreadCount;
      error = null;
    } catch (e) {
      error = 'Dashboard data unavailable. Is the server running?';
    } finally {
      loadingOverview = false;
      notifyListeners();
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> refreshNotifications() async {
    loadingNotifications = true;
    notifyListeners();
    try {
      final data = await _api.getAdminNotifications(perPage: 50);
      final items = data['items'] as List<dynamic>? ?? [];
      notifications = items
          .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      unreadCount = data['unread_count'] as int? ?? 0;
      _lastPollAt = DateTime.now();
      hasNewNotifications = false;
    } catch (_) {
      // Silent fail on background poll
    } finally {
      loadingNotifications = false;
      notifyListeners();
    }
  }

  /// Silent background poll — only notifies if count changes.
  Future<void> _pollNotifications() async {
    try {
      final count = await _api.getAdminUnreadCount();
      if (count != unreadCount) {
        unreadCount = count;
        // Fetch full list to show latest
        final data = await _api.getAdminNotifications(perPage: 50);
        final items = data['items'] as List<dynamic>? ?? [];
        notifications = items
            .map((e) => AdminNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    notifications[idx].isRead = true;
    if (unreadCount > 0) unreadCount--;
    notifyListeners();
    try {
      await _api.markAdminNotifRead(id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    for (final n in notifications) {
      n.isRead = true;
    }
    unreadCount = 0;
    notifyListeners();
    try {
      await _api.markAllAdminNotifsRead();
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    final removed = notifications.firstWhere((n) => n.id == id,
        orElse: () => AdminNotification(
            id: '', title: '', body: '',
            type: AdminNotifType.system, createdAt: DateTime.now()));
    notifications.removeWhere((n) => n.id == id);
    if (!removed.isRead && unreadCount > 0) unreadCount--;
    notifyListeners();
    try {
      await _api.deleteAdminNotif(id);
    } catch (_) {}
  }

  Future<void> clearAllNotifications() async {
    notifications.clear();
    unreadCount = 0;
    notifyListeners();
    try {
      await _api.clearAllAdminNotifs();
    } catch (_) {}
  }

  void acknowledgeNew() {
    hasNewNotifications = false;
    notifyListeners();
  }
}
