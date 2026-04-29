import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../screens/dashboard_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/wallet_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static NotificationService get instance => _instance;

  Future<void> init() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Subscribe to topics
    await _fcm.subscribeToTopic('all_users');
    await _fcm.subscribeToTopic('farming_alerts');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app snackbar or banner — no local notifications package needed
    final notification = message.notification;
    if (notification != null) {
      // Handled at app level via stream
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    Widget screen;
    switch (type) {
      case 'wallet':
      case 'payment':
      case 'credits':
        screen = const WalletScreen();
        break;
      case 'rain':
      case 'disease':
      case 'fertilizer':
      case 'weather':
      case 'alert':
      case 'notification':
        screen = const NotificationsScreen();
        break;
      default:
        screen = const DashboardScreen();
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<String?> getToken() async => await _fcm.getToken();

  Future<void> subscribeToTopic(String topic) async =>
      await _fcm.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) async =>
      await _fcm.unsubscribeFromTopic(topic);

  // Stream for foreground messages — listen to this in your UI
  Stream<RemoteMessage> get onForegroundMessage => FirebaseMessaging.onMessage;
}
