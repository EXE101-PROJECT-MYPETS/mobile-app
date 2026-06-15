import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pawly_mobile/app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();

  factory FirebaseNotificationService() {
    return _instance;
  }

  FirebaseNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'pawly_channel_id',
        'Pawly Thông báo',
        description: 'Kênh thông báo của Pawly',
        importance: Importance.max,
      );

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final String? type = data['type']?.toString();
      debugPrint("Handling notification click, type = $type, data = $data");

      if (type != null) {
        if (type.contains('ORDER')) {
          MyApp.navigatorKey.currentState?.pushNamed('/orders');
        } else if (type.contains('BOOKING') || type.contains('SERVICE')) {
          MyApp.navigatorKey.currentState?.pushNamed('/bookings');
        } else if (type == 'CHAT_MESSAGE') {
          MyApp.navigatorKey.currentState?.pushNamed('/conversations');
        }
      }
    } catch (e) {
      debugPrint("Error handling notification payload: $e");
    }
  }

  Future<void> init() async {
    try {
      await Firebase.initializeApp();

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) {
              debugPrint(
                'Notification clicked with payload: ${notificationResponse.payload}',
              );
              _handleNotificationPayload(notificationResponse.payload);
            },
      );

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();

      await androidPlugin?.createNotificationChannel(_androidChannel);

      // Xin quyền
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Check if the app was opened from a terminated state via a notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'App opened from terminated state via notification: ${initialMessage.messageId}',
        );
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleNotificationPayload(jsonEncode(initialMessage.data));
        });
      }

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          'App opened from background state via notification: ${message.messageId}',
        );
        _handleNotificationPayload(jsonEncode(message.data));
      });

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Lấy FCM Token và gửi lên server nếu đã đăng nhập
        await sendTokenToServer();

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.notification != null) {
            debugPrint(
              'Message also contained a notification: ${message.notification}',
            );
            _showLocalNotification(message);
          }
        });
      }
    } catch (e) {
      debugPrint("Firebase init error: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'pawly_channel_id',
          'Pawly Thông báo',
          channelDescription: 'Kênh thông báo của Pawly',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          ticker: 'ticker',
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      message.notification?.hashCode ?? 0,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> sendTokenToServer() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('FCM Token is null, cannot send to server');
        return;
      }
      debugPrint("Fetched FCM Token: $token");

      final box = await Hive.openBox('auth_box');
      final accessToken = box.get('access_token') as String?;
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint(
          'Access token is null, user not logged in yet. FCM token not sent.',
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('FCM token sent to server successfully');
      } else {
        debugPrint(
          'Failed to send FCM token to server: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending FCM token: $e');
    }
  }
}
