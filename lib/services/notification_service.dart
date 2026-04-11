import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    if (kIsWeb) return; // Local notifications not supported on web

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
  }

  static Future<void> showBudgetAlert({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'budget_alert',
      'Budget Alerts',
      channelDescription: 'Notifications for budget limit warnings',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _plugin.show(0, title, body, notificationDetails);
  }

  static Future<void> showWeeklySummary({required String body}) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'weekly_summary',
      'Weekly Summary',
      channelDescription: 'Weekly spending summary notifications',
      importance: Importance.defaultImportance,
    );
    const notificationDetails =
        NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _plugin.show(1, 'Weekly Summary 📊', body, notificationDetails);
  }
}
