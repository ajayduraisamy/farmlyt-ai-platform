// lib/providers/notifications_provider.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    int? unreadCount,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    // Listen to foreground FCM messages as soon as provider is created
    _listenToFcm();
    return const NotificationsState();
  }

  void _listenToFcm() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _addFromRemoteMessage(message);
    });

    // Messages that opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _addFromRemoteMessage(message);
    });

    // Check if app was launched from a terminated state via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _addFromRemoteMessage(message);
      }
    });
  }

  void _addFromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    // Determine type from data payload, fallback to 'general'
    final type = _resolveType(data['type']?.toString() ?? '');

    final model = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? data['title']?.toString() ?? 'New Alert',
      body: notification?.body ??
          data['body']?.toString() ??
          data['message']?.toString() ??
          '',
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    final updated = [model, ...state.notifications];
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  /// Manually add a notification (useful for testing or local triggers)
  void addNotification(NotificationModel notification) {
    final updated = [notification, ...state.notifications];
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  void markAllRead() {
    final updated = state.notifications.map((n) => _markRead(n)).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  void markRead(String id) {
    final updated =
        state.notifications.map((n) => n.id == id ? _markRead(n) : n).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  void removeNotification(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  void clearAll() {
    state = const NotificationsState();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  NotificationModel _markRead(NotificationModel n) => NotificationModel(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        timestamp: n.timestamp,
        isRead: true,
      );

  /// Maps FCM data 'type' values to your internal type strings
  String _resolveType(String raw) {
    switch (raw.toLowerCase()) {
      case 'rain':
      case 'weather':
      case 'weather_update':
        return 'rain';
      case 'disease':
      case 'disease_alert':
        return 'disease';
      case 'fertilizer':
      case 'fertilizer_reminder':
        return 'fertilizer';
      default:
        return 'general';
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
        NotificationsNotifier.new);
