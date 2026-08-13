import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'google_sheet_api_service.dart';

class NotificationService {
  NotificationService({GoogleSheetApiService? apiService})
      : _apiService = apiService ?? GoogleSheetApiService();

  final GoogleSheetApiService _apiService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('NotificationService: Web detected, skipping FCM token save.');
      return;
    }

    await _initializeLocalNotifications();
    await _requestNotificationPermission();
    await saveCurrentDeviceToken();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(initializationSettings);

    const androidChannel = AndroidNotificationChannel(
      'facility_reports',
      'Facility report alerts',
      description: 'Notifications for new facility reports.',
      importance: Importance.high,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
    }
  }

  Future<void> saveCurrentDeviceToken() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('Cannot get FCM token because Firebase is not initialized.');
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM token is null or empty.');
        return;
      }

      debugPrint('FCM token: $token');
      await saveDeviceToken(token);
    } catch (error) {
      debugPrint('Failed to get or register FCM token: $error');
    }
  }

  Future<void> saveDeviceToken(String token) async {
    try {
      await _apiService.registerDeviceToken(
        token: token,
        role: 'STAFF',
        userName: 'Bảo vệ 1',
      );
      debugPrint('Registered FCM token with Apps Script DeviceTokens sheet.');
    } catch (error) {
      debugPrint('Failed to register FCM token with Apps Script: $error');
    }
  }
}
