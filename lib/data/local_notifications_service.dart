import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'navigation_service.dart';

class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'pocketpt_general',
    'General Notifications',
    description: 'Reminders and updates from PocketPT',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return; // Not supported on web

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
      macOS: null,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload ?? '';
        _handlePayload(payload);
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    if (Platform.isAndroid) {
      // Create channel
      await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_defaultChannel);
    }

    _initialized = true;
  }

  // Background tap handler (must be a top-level or static function)
  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    final payload = response.payload ?? '';
    instance._handlePayload(payload);
  }

  void _handlePayload(String payload) {
    // payload format: actionType
    final actionType = payload;
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;

    switch (actionType) {
      case 'daily_assessment':
        // Navigate to the daily instruction page route if available
        // Since routes are mostly created via MaterialPageRoute inline, just push dashboard and let its dialog prompt
        // Best we can do: bring app to foreground; dashboard logic will show dialog
        break;
      case 'start_exercise':
      case 'resume_exercise':
        // Open dashboard; user can tap Resume/Start
        break;
      case 'regenerate_plan':
        // Open dashboard; it will prompt regenerate if needed
        break;
      default:
        break;
    }
  }

  Future<void> showUniqueDailyNotification({
    required int id,
    required String title,
    required String body,
    required String actionType,
  }) async {
    if (!_initialized || kIsWeb) return;

    final String todayKey = _makeTodayKey(actionType);
    try {
      final box = Hive.isBoxOpen('rehabBox') ? Hive.box('rehabBox') : await Hive.openBox('rehabBox');
      final alreadyNotified = box.get(todayKey, defaultValue: false) as bool;
      if (alreadyNotified) return;

      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: actionType,
      );

      await box.put(todayKey, true);
    } catch (_) {
      // ignore failures silently
    }
  }

  String _makeTodayKey(String actionType) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'notif_sent_${actionType}_$y$m$d';
  }
}


