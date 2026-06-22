import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp();

  log("Background Message: ${message.messageId}");
  final notification = message.notification;

  if (notification != null) {
    AppNotificationService.instance.showLocalNotification(
      notification.title ?? '',
      notification.body ?? '',
    );
  }
}

class AppNotificationService {
  AppNotificationService._private();

  static final AppNotificationService instance =
  AppNotificationService._private();

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin
  _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'channel_id',
    'General Notifications',
    description: 'General notifications channel',
    importance: Importance.max,
  );

  Future<void> init() async {
    await tokenFCM();

    await _requestPermissions();

    await _initLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _listenToMessages();

    await _checkInitialMessage();
  }

  Future<void> tokenFCM() async {
    try {
      SharedPreferences preferences =
      await SharedPreferences.getInstance();

      String? token =
      await FirebaseMessaging.instance.getToken();

      log("FCM TOKEN => $token");

      if (token != null) {
        await preferences.setString(
          'fcm_token',
          token,
        );
      }
    } catch (e, s) {
      log(
        'FCM Token Error: $e',
        stackTrace: s,
      );
    }
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings
    androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings
    iosSettings =
    DarwinInitializationSettings();

    const InitializationSettings
    initializationSettings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (
          NotificationResponse response,
          ) async {
        log(
          'Notification tapped: ${response.payload}',
        );
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _listenToMessages() {
    FirebaseMessaging.onMessage.listen((
        RemoteMessage message,
        ) {
      log(
        "Foreground Message: ${message.messageId}",
      );

      final notification =
          message.notification;

      if (notification != null) {
        showLocalNotification(
          notification.title ?? '',
          notification.body ?? '',
        );
      }
    });

    /// User tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
        ) {
      log(
        "Notification Opened: ${message.messageId}",
      );

      // Navigation logic here if needed
    });
  }

  Future<void> _checkInitialMessage() async {
    final RemoteMessage? message =
    await _messaging.getInitialMessage();

    if (message != null) {
      log(
        "App opened from terminated state",
      );

      // Navigation logic here if needed
    }
  }

  Future<void> showLocalNotification(
      String title,
      String body,
      ) async {
    const AndroidNotificationDetails
    androidDetails =
    AndroidNotificationDetails(
      'channel_id',
      'General Notifications',
      channelDescription:
      'General notifications channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails
    iosDetails =
    DarwinNotificationDetails();

    const NotificationDetails
    notificationDetails =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

 static Future<bool> checkNotificationPermission() async {
    NotificationSettings settings =
    await FirebaseMessaging.instance.getNotificationSettings();

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

 static Future<bool> requestNotificationPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

}