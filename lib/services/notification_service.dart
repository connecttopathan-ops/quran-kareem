// ⚠️ Replace placeholder files in android/app/src/main/res/raw/ with real adhan mp3 audio.
// adhan_makkah_fajr.mp3 is used for Fajr regardless of which mosque the user selects.

// ⚠️ IMPORTANT: After deploying this fix, the app MUST be uninstalled
// and reinstalled on the test device. Simply updating is not enough
// because Android persists old notification channels even across updates.
// Uninstall → reinstall → go to Prayer Notifications → Save & Schedule.

import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

enum PrayerNotificationMode { adhan, vibration, singleVibration, off }

enum AdhanType { makkah, madinah }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _adhanChannelId = 'prayer_times_adhan';
  static const String _adhanChannelName = 'Prayer Times (Adhan)';
  static const String _vibrationChannelId = 'prayer_times_vibration';
  static const String _vibrationChannelName = 'Prayer Times (Vibration)';

  static const List<int> _prayerIds = [1, 2, 3, 4, 5];
  static const List<String> _prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha'
  ];

  Future<void> init() async {
    tzdata.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Always delete old channels to force recreation with correct sound.
    // Android caches channel settings after first creation — deleting ensures
    // the channel is recreated with the correct sound/vibration config.
    await androidPlugin?.deleteNotificationChannel('prayer_times');
    await androidPlugin?.deleteNotificationChannel(_adhanChannelId);
    await androidPlugin?.deleteNotificationChannel(_vibrationChannelId);

    // Channel 1 — adhan (with sound)
    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      _adhanChannelId,
      _adhanChannelName,
      description: 'Adhan audio at prayer times',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Channel 2 — vibration only (no sound)
    const AndroidNotificationChannel vibrationChannel =
        AndroidNotificationChannel(
      _vibrationChannelId,
      _vibrationChannelName,
      description: 'Vibration alert at prayer times',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(adhanChannel);
    await androidPlugin?.createNotificationChannel(vibrationChannel);

    // Request POST_NOTIFICATIONS permission on Android 13+
    await Permission.notification.request();
  }

  Future<void> scheduleAllPrayers(
    Map<String, String> prayerTimes,
    PrayerNotificationMode mode, {
    AdhanType adhanType = AdhanType.makkah,
  }) async {
    if (mode == PrayerNotificationMode.off) {
      await cancelAll();
      return;
    }

    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < _prayerNames.length; i++) {
      final name = _prayerNames[i];
      final timeStr = prayerTimes[name];
      if (timeStr == null) continue;

      final parsed = _parseTimeString(timeStr);
      if (parsed == null) continue;

      final scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsed.$1,
        parsed.$2,
      );

      // Skip if time has already passed today
      if (scheduledDate.isBefore(now)) continue;

      final details = _buildNotificationDetails(name, mode, adhanType);

      await _plugin.zonedSchedule(
        _prayerIds[i],
        'Prayer Time 🕌',
        "It's time for $name",
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  NotificationDetails _buildNotificationDetails(
    String prayerName,
    PrayerNotificationMode mode,
    AdhanType adhanType,
  ) {
    AndroidNotificationDetails androidDetails;

    switch (mode) {
      case PrayerNotificationMode.adhan:
        // Fajr always uses adhan_makkah_fajr regardless of adhanType
        final soundFile = prayerName == 'Fajr'
            ? 'adhan_makkah_fajr'
            : (adhanType == AdhanType.makkah ? 'adhan_makkah' : 'adhan_madinah');
        androidDetails = AndroidNotificationDetails(
          _adhanChannelId,
          _adhanChannelName,
          channelDescription: 'Adhan audio at prayer times',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundFile),
          enableVibration: true,
        );

      case PrayerNotificationMode.vibration:
        androidDetails = AndroidNotificationDetails(
          _vibrationChannelId,
          _vibrationChannelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        );

      case PrayerNotificationMode.singleVibration:
        androidDetails = AndroidNotificationDetails(
          _vibrationChannelId,
          _vibrationChannelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400]),
        );

      case PrayerNotificationMode.off:
        androidDetails = const AndroidNotificationDetails(
          _adhanChannelId,
          _adhanChannelName,
        );
    }

    return NotificationDetails(android: androidDetails);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> sendTestNotification(
    PrayerNotificationMode mode,
    AdhanType adhanType,
  ) async {
    final details = _buildNotificationDetails('Dhuhr', mode, adhanType);
    await _plugin.show(
      0,
      'Prayer Time 🕌',
      'Test — notification is working ✓',
      details,
    );
  }

  (int, int)? _parseTimeString(String timeStr) {
    try {
      final cleaned = timeStr.trim();
      final upper = cleaned.toUpperCase();
      if (upper.contains('AM') || upper.contains('PM')) {
        final parts = cleaned.split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return (hour, minute);
      } else {
        final parts = cleaned.split(':');
        return (int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (_) {
      return null;
    }
  }
}
