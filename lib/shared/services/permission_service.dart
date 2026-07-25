import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// Handles all device-level permission requests and hardware data fetches:
/// - FCM push notification permission + token retrieval
/// - GPS location permission + current position fetch
///
/// All methods are static and side-effect free beyond the OS dialog calls.
class PermissionService {
  PermissionService._();

  // ── Notification channel definition (Android 8+) ───────────────────────────

  static const _kChannelId = 'koolan_channel';
  static const _kChannelName = 'Koolan Notifications';
  static const _kChannelDesc = 'Marketplace updates, messages, and alerts';

  /// The [FlutterLocalNotificationsPlugin] singleton initialised in main().
  static final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // ── Initialise local-notification plugin ───────────────────────────────────

  /// Call once from main() after Firebase.initializeApp().
  static Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false, // we request via FCM instead
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await localNotifications.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android high-importance channel.
    if (Platform.isAndroid) {
      await localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _kChannelId,
              _kChannelName,
              description: _kChannelDesc,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            ),
          );
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Navigation on tap can be wired here if needed later.
    debugPrint('[PermissionService] Notification tapped: ${response.payload}');
  }

  // ── FCM setup ──────────────────────────────────────────────────────────────

  /// Requests notification permission (Android 13+ / iOS) and returns the
  /// FCM device token, or null if permission was denied or an error occurred.
  static Future<String?> requestNotificationPermissionAndGetToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
          '[PermissionService] Notification auth status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      // Foreground messages on iOS need explicit opt-in.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      debugPrint('[PermissionService] FCM token: $token');
      return token;
    } catch (e) {
      debugPrint('[PermissionService] FCM permission/token error: $e');
      return null;
    }
  }

  /// Shows an FCM message as a local notification while the app is foregrounded.
  /// Call this from a FirebaseMessaging.onMessage listener.
  static Future<void> showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data['screen'] as String?,
    );
  }

  // ── GPS location ───────────────────────────────────────────────────────────

  /// Requests location permission and fetches the current device position.
  ///
  /// Returns null if permission is denied or location services are disabled.
  static Future<Position?> requestLocationPermissionAndGetPosition() async {
    try {
      // Check whether location services are enabled at all.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[PermissionService] Location services disabled on device');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[PermissionService] Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[PermissionService] Location permission permanently denied');
        return null;
      }

      // Permission granted — get current position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      debugPrint(
          '[PermissionService] Position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('[PermissionService] Location fetch error: $e');
      return null;
    }
  }
}
