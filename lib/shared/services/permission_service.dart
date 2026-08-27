import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles all device-level permission requests and hardware data fetches:
/// - FCM push notification permission + token retrieval
/// - GPS location permission + current position fetch
///
/// All methods are static and side-effect free beyond the OS dialog calls.
class PermissionService {
  PermissionService._();

  // ── Notification channel definition (Android 8+) ───────────────────────────

  static const _kChannelId = 'koolan_channel';
  static const _kChannelName = '1market Notifications';
  static const _kChannelDesc = 'Marketplace updates, messages, and alerts';
  static const _kMessagesChannelId = 'koolan_messages_channel';
  static const _kMessagesChannelName = 'New Messages';
  static const _kMessagesChannelDesc = 'Chat and direct message alerts';

  static AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      Platform.isAndroid
          ? localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          : null;

  /// The [FlutterLocalNotificationsPlugin] singleton initialised in main().
  static final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // ── Initialise local-notification plugin ───────────────────────────────────

  /// Call once from main() after Firebase.initializeApp().
  static Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
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

    // Create the Android notification channels.
    if (Platform.isAndroid) {
      await _ensureAndroidChannel(
        id: _kChannelId,
        name: _kChannelName,
        description: _kChannelDesc,
        enabled: true,
      );
      await _ensureAndroidChannel(
        id: _kMessagesChannelId,
        name: _kMessagesChannelName,
        description: _kMessagesChannelDesc,
        enabled: true,
      );
    }
  }

  static Future<void> _ensureAndroidChannel({
    required String id,
    required String name,
    required String description,
    required bool enabled,
  }) async {
    final plugin = _androidPlugin;
    if (plugin == null) return;

    // Channels are immutable for importance — delete and recreate to toggle.
    await plugin.deleteNotificationChannel(id);
    await plugin.createNotificationChannel(
      AndroidNotificationChannel(
        id,
        name,
        description: description,
        importance: enabled ? Importance.high : Importance.none,
        playSound: enabled,
        enableVibration: enabled,
      ),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Navigation on tap can be wired here if needed later.
    if (kDebugMode) debugPrint('[PermissionService] Notification tapped: ${response.payload}');
  }

  // ── FCM setup ──────────────────────────────────────────────────────────────

  /// Opens this app's notification page in system Settings.
  static Future<void> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PermissionService] openNotificationSettings error: $e');
      }
      await openAppSettings();
    }
  }

  /// Returns whether the OS currently allows notifications for this app.
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      if (Platform.isAndroid) {
        final plugin = _androidPlugin;
        final enabled = await plugin?.areNotificationsEnabled();
        if (enabled != null) return enabled;

        final status = await Permission.notification.status;
        return status.isGranted;
      }

      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PermissionService] notification permission check error: $e');
      }
      return false;
    }
  }

  /// Requests OS notification permission. Returns true when granted.
  static Future<bool> requestOsNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final plugin = _androidPlugin;
        if (plugin != null) {
          final granted = await plugin.requestNotificationsPermission();
          if (granted != null) return granted;
        }

        final status = await Permission.notification.request();
        return status.isGranted;
      }

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PermissionService] requestOsNotificationPermission error: $e');
      }
      return false;
    }
  }

  /// Enables or disables Android delivery channels (master + messages).
  static Future<void> setAndroidChannelsEnabled({
    required bool pushEnabled,
    required bool messagesEnabled,
  }) async {
    if (!Platform.isAndroid) return;
    await _ensureAndroidChannel(
      id: _kChannelId,
      name: _kChannelName,
      description: _kChannelDesc,
      enabled: pushEnabled,
    );
    await _ensureAndroidChannel(
      id: _kMessagesChannelId,
      name: _kMessagesChannelName,
      description: _kMessagesChannelDesc,
      enabled: pushEnabled && messagesEnabled,
    );
  }

  /// Stops receiving remote pushes on this device and suppresses foreground alerts.
  static Future<void> disablePushOnDevice({
    required bool messagesEnabled,
  }) async {
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      await FirebaseMessaging.instance.deleteToken();
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      await setAndroidChannelsEnabled(pushEnabled: false, messagesEnabled: false);
      await localNotifications.cancelAll();
      if (kDebugMode) debugPrint('[PermissionService] Push disabled on device');
    } catch (e) {
      if (kDebugMode) debugPrint('[PermissionService] disablePushOnDevice error: $e');
    }
  }

  /// Re-enables FCM and requests OS permission. Returns a token when granted.
  /// Pass [skipOsRequest] = true to skip the OS dialog (e.g. permission already
  /// granted) and just retrieve the FCM token directly.
  static Future<String?> enablePushOnDevice({
    required bool messagesEnabled,
    bool skipOsRequest = false,
  }) async {
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      if (!skipOsRequest) {
        final granted = await requestOsNotificationPermission();
        if (!granted) return null;
      }

      await setAndroidChannelsEnabled(
        pushEnabled: true,
        messagesEnabled: messagesEnabled,
      );

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        debugPrint(
          '[PermissionService] FCM token ${token == null ? "missing" : "obtained"}',
        );
      }
      return token;
    } catch (e) {
      if (kDebugMode) debugPrint('[PermissionService] enablePushOnDevice error: $e');
      return null;
    }
  }

  /// Toggles only the messages channel on Android (iOS uses server-side filter).
  static Future<void> setMessageNotificationsEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    final pushGranted = await isNotificationPermissionGranted();
    await _ensureAndroidChannel(
      id: _kMessagesChannelId,
      name: _kMessagesChannelName,
      description: _kMessagesChannelDesc,
      enabled: pushGranted && enabled,
    );
  }

  /// Whether an incoming FCM message should be surfaced on this device.
  static bool shouldDeliverPush(
    RemoteMessage message, {
    required bool pushEnabled,
    required bool messagesEnabled,
  }) {
    if (!pushEnabled) return false;

    final type = message.data['type'] as String?;
    final screen = message.data['screen'] as String?;
    final isMessage = type == 'new_message' || screen == 'chat';
    if (isMessage && !messagesEnabled) return false;

    return true;
  }

  /// Requests notification permission (Android 13+ / iOS) and returns the
  /// FCM device token, or null if permission was denied or an error occurred.
  static Future<String?> requestNotificationPermissionAndGetToken() async {
    return enablePushOnDevice(messagesEnabled: true);
  }

  /// Shows an FCM message as a local notification while the app is foregrounded.
  /// Call this from a FirebaseMessaging.onMessage listener.
  ///
  /// Falls back to [message.data] fields when the FCM message has no
  /// [notification] payload (data-only messages sent from the Edge Function).
  static Future<void> showForegroundNotification(
    RemoteMessage message, {
    required bool messagesEnabled,
  }) async {
    // Prefer the notification payload; fall back to data fields.
    final title = message.notification?.title ?? message.data['title'] as String?;
    final body  = message.notification?.body  ?? message.data['body']  as String?;

    // Nothing to show if we have no title and no body.
    if (title == null && body == null) return;

    final type = message.data['type'] as String?;
    final screen = message.data['screen'] as String?;
    final isMessage = type == 'new_message' || screen == 'chat';
    final channelId = isMessage ? _kMessagesChannelId : _kChannelId;
    final channelName = isMessage ? _kMessagesChannelName : _kChannelName;
    final channelDesc = isMessage ? _kMessagesChannelDesc : _kChannelDesc;

    if (isMessage && !messagesEnabled) return;

    // Prefer FCM's native image URL, then the data payload used by the
    // Edge Function (listing photo).
    final imageUrl = message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['imageUrl'] as String?;

    StyleInformation? styleInformation;
    DarwinNotificationDetails? iosDetails;
    String? largeIconPath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final localPath = await _downloadImage(imageUrl);
      if (localPath != null) {
        largeIconPath = localPath;
        styleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(localPath),
          largeIcon: FilePathAndroidBitmap(localPath),
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: true,
        );
        iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          attachments: [DarwinNotificationAttachment(localPath)],
        );
      }
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      styleInformation: styleInformation,
      largeIcon: largeIconPath != null
          ? FilePathAndroidBitmap(largeIconPath)
          : null,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails ??
          const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
    );

    // Use a stable int ID derived from the message so rapid inserts don't
    // clobber each other.
    final id = (message.messageId ?? message.data['notification_id'] ?? title ?? '')
        .hashCode
        .abs();

    await localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: message.data['screen'] as String?,
    );
  }

  /// Downloads [url] to a temp file for use as a notification attachment.
  /// Returns null on any failure so the notification still shows without an image.
  static Future<String?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;

      final dir = await getTemporaryDirectory();
      final ext = _imageExtension(url, response.headers['content-type']);
      final file = File(
        '${dir.path}/notif_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      if (kDebugMode) debugPrint('[PermissionService] notification image download failed: $e');
      return null;
    }
  }

  static String _imageExtension(String url, String? contentType) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.webp')) return '.webp';
    if (path.endsWith('.gif')) return '.gif';
    if (contentType != null) {
      if (contentType.contains('png')) return '.png';
      if (contentType.contains('webp')) return '.webp';
      if (contentType.contains('gif')) return '.gif';
    }
    return '.jpg';
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
        if (kDebugMode) debugPrint('[PermissionService] Location services disabled on device');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) debugPrint('[PermissionService] Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) debugPrint('[PermissionService] Location permission permanently denied');
        return null;
      }

      // Permission granted — get current position.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (kDebugMode) {
        debugPrint(
          '[PermissionService] Position: ${position.latitude}, ${position.longitude}',
        );
      }
      return position;
    } catch (e) {
      if (kDebugMode) debugPrint('[PermissionService] Location fetch error: $e');
      return null;
    }
  }
}
