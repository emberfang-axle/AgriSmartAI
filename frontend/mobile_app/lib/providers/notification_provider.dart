import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/disease_result.dart';
import '../models/notification_model.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _loaded = false;

  List<NotificationModel> get all => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  List<NotificationModel> get unread =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get diseaseAlerts => _notifications
      .where((n) => n.type == NotificationType.diseaseAlert)
      .toList();

  List<NotificationModel> get farmingTips => _notifications
      .where((n) => n.type == NotificationType.farmingTip)
      .toList();

  Future<void> loadFromStorage() async {
    if (_loaded) return;
    _notifications = await StorageService.loadNotifications();
    if (_notifications.isEmpty) {
      _seedInitialNotifications();
    }
    _loaded = true;
    notifyListeners();
  }

  void _seedInitialNotifications() {
    final tips = [
      NotificationModel(
        id: _uuid.v4(),
        title: 'Welcome to AgriSmartAI',
        body:
            'Scan your rice leaves to detect diseases early and get treatment advice. Tap the green Scan button to start.',
        type: NotificationType.system,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: _uuid.v4(),
        title: 'Farming Tip: Water Management',
        body:
            'Maintain 2–5 cm of standing water during the vegetative stage for optimal rice growth.',
        type: NotificationType.farmingTip,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      NotificationModel(
        id: _uuid.v4(),
        title: 'Farming Tip: Early Detection',
        body:
            'Scout your fields twice a week. Early disease detection can save up to 30% of your harvest.',
        type: NotificationType.farmingTip,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
    ];
    _notifications.addAll(tips);
    _persist();
  }

  void addDetectionNotification(DiseaseResult result) {
    final isDisease = !result.isHealthy;
    final notif = NotificationModel(
      id: _uuid.v4(),
      title: isDisease ? 'Disease Detected!' : 'Scan Complete — Healthy',
      body: isDisease
          ? '${result.disease} detected with ${result.confidence.toStringAsFixed(1)}% confidence. '
              'Severity: ${result.severity}. Tap to view treatment.'
          : 'Your rice crop appears healthy! Keep monitoring regularly.',
      type: isDisease
          ? NotificationType.diseaseAlert
          : NotificationType.system,
      createdAt: DateTime.now(),
      isRead: false,
      data: {
        'resultId': result.id,
        'disease': result.disease,
        'confidence': result.confidence,
      },
    );
    _notifications.insert(0, notif);
    _persist();
    notifyListeners();
  }

  void add(NotificationModel notification) {
    _notifications.insert(0, notification);
    _persist();
    notifyListeners();
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    _persist();
    notifyListeners();
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  void delete(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _persist();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _persist();
    notifyListeners();
  }

  List<NotificationModel> filtered(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return all;
      case NotificationFilter.unread:
        return unread;
      case NotificationFilter.diseaseAlerts:
        return diseaseAlerts;
      case NotificationFilter.farmingTips:
        return farmingTips;
    }
  }

  void _persist() {
    StorageService.saveNotifications(_notifications);
  }
}

enum NotificationFilter { all, unread, diseaseAlerts, farmingTips }

extension NotificationFilterExt on NotificationFilter {
  String get label {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.diseaseAlerts:
        return 'Disease Alerts';
      case NotificationFilter.farmingTips:
        return 'Tips';
    }
  }
}
