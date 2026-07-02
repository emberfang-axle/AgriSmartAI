import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'agrismartai_channel';
  static const _channelName = 'AgriSmartAI Alerts';
  static const _channelDesc = 'Disease detection and farming alerts';

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    // Create notification channel (Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showDiseaseAlert({
    required String disease,
    required double confidence,
    required String severity,
  }) async {
    if (kIsWeb) return;
    final isHealthy = disease == 'Healthy';
    await _show(
      id: 1,
      title: isHealthy ? 'Scan Complete — Healthy Crop' : '⚠ $disease Detected',
      body: isHealthy
          ? 'Your rice crop appears healthy. Keep up the good work!'
          : '$disease found with ${confidence.toStringAsFixed(1)}% confidence. '
              'Severity: $severity. Tap for treatment advice.',
    );
  }

  static Future<void> showFarmingTip(String tip) async {
    if (kIsWeb) return;
    await _show(id: 2, title: '🌾 Farming Tip', body: tip);
  }

  static Future<void> showSystemMessage(String message) async {
    if (kIsWeb) return;
    await _show(id: 3, title: 'AgriSmartAI', body: message);
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }
}
