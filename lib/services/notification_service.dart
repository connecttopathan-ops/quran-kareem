// ⚠️ Replace placeholder files in android/app/src/main/res/raw/ with real adhan mp3 audio.
// adhan_makkah_fajr.mp3 is used for Fajr regardless of which mosque the user selects.

// ⚠️ IMPORTANT: After deploying this fix, the app MUST be uninstalled
// and reinstalled on the test device. Simply updating is not enough
// because Android persists old notification channels even across updates.
// Uninstall → reinstall → go to Prayer Notifications → Save & Schedule.

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../data/curated_ayahs.dart';

enum PrayerNotificationMode { adhan, vibration, singleVibration, off }

enum AdhanType { makkah, madinah }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Emits the payload of the last tapped notification.
  /// HomeScreen listens to scroll to the relevant section.
  static final ValueNotifier<String?> notificationPayload = ValueNotifier(null);

  static const String _adhanMakkahChannelId = 'prayer_times_adhan_makkah';
  static const String _adhanMadinahChannelId = 'prayer_times_adhan_madinah';
  static const String _adhanFajrChannelId = 'prayer_times_adhan_fajr';
  static const String _vibrationChannelId = 'prayer_times_vibration';
  static const String _vibrationChannelName = 'Prayer Times (Vibration)';

  static const String _reminderChannelId = 'daily_reminders';
  static const String _ayahChannelId = 'ayah_of_the_day';

  // Notification IDs
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
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          notificationPayload.value = details.payload;
        }
      },
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Cancel all active notifications first — Android refuses to delete
    // a channel that has a currently-visible notification.
    await _plugin.cancelAll();

    // Delete old channels so they are recreated with the correct sound.
    // Android caches channel settings — must delete to update sound.
    await androidPlugin?.deleteNotificationChannel('prayer_times');
    await androidPlugin?.deleteNotificationChannel('prayer_times_adhan');
    await androidPlugin?.deleteNotificationChannel(_adhanMakkahChannelId);
    await androidPlugin?.deleteNotificationChannel(_adhanMadinahChannelId);
    await androidPlugin?.deleteNotificationChannel(_adhanFajrChannelId);
    await androidPlugin?.deleteNotificationChannel(_vibrationChannelId);

    // One channel per sound — Android locks sound at channel creation time.
    const AndroidNotificationChannel adhanMakkahChannel =
        AndroidNotificationChannel(
      _adhanMakkahChannelId,
      'Prayer Times (Makkah Adhan)',
      description: 'Makkah adhan at prayer times',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_makkah'),
      enableVibration: true,
    );
    const AndroidNotificationChannel adhanMadinahChannel =
        AndroidNotificationChannel(
      _adhanMadinahChannelId,
      'Prayer Times (Madinah Adhan)',
      description: 'Madinah adhan at prayer times',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_madinah'),
      enableVibration: true,
    );
    const AndroidNotificationChannel adhanFajrChannel =
        AndroidNotificationChannel(
      _adhanFajrChannelId,
      'Prayer Times (Fajr Adhan)',
      description: 'Fajr adhan at prayer times',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adhan_makkah_fajr'),
      enableVibration: true,
    );
    const AndroidNotificationChannel vibrationChannel =
        AndroidNotificationChannel(
      _vibrationChannelId,
      _vibrationChannelName,
      description: 'Vibration alert at prayer times',
      importance: Importance.high,
      playSound: false,
      enableVibration: true,
    );

    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
      _reminderChannelId,
      'Daily Reminders',
      description: 'Daily Quran reading reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    const AndroidNotificationChannel ayahChannel = AndroidNotificationChannel(
      _ayahChannelId,
      'Ayah of the Day',
      description: 'Daily ayah notification',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.deleteNotificationChannel(_reminderChannelId);
    await androidPlugin?.deleteNotificationChannel(_ayahChannelId);

    await androidPlugin?.createNotificationChannel(adhanMakkahChannel);
    await androidPlugin?.createNotificationChannel(adhanMadinahChannel);
    await androidPlugin?.createNotificationChannel(adhanFajrChannel);
    await androidPlugin?.createNotificationChannel(vibrationChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(ayahChannel);

    // Request POST_NOTIFICATIONS permission on Android 13+
    // (permission dialog is now shown from UI with context — just init here)
    await Permission.notification.request();

    // SCHEDULE_EXACT_ALARM is requested from UI with rationale dialog
    // so we don't blindly request it here anymore
  }

  /// Returns true if POST_NOTIFICATIONS is granted (or not needed pre-Android 13).
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
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

      // Build scheduled time for today; if already passed, schedule for tomorrow.
      // matchDateTimeComponents: DateTimeComponents.time will repeat daily after that.
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsed.$1,
        parsed.$2,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final details = _buildNotificationDetails(name, mode, adhanType);

      await _plugin.zonedSchedule(
        _prayerIds[i],
        'Prayer Time 🕌',
        "It's time for $name",
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
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
        // Each prayer uses the channel whose sound was set at creation time.
        // Fajr always uses the Fajr channel regardless of adhanType.
        final String channelId;
        final String channelName;
        final String soundFile;
        if (prayerName == 'Fajr') {
          channelId = _adhanFajrChannelId;
          channelName = 'Prayer Times (Fajr Adhan)';
          soundFile = 'adhan_makkah_fajr';
        } else if (adhanType == AdhanType.makkah) {
          channelId = _adhanMakkahChannelId;
          channelName = 'Prayer Times (Makkah Adhan)';
          soundFile = 'adhan_makkah';
        } else {
          channelId = _adhanMadinahChannelId;
          channelName = 'Prayer Times (Madinah Adhan)';
          soundFile = 'adhan_madinah';
        }
        androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
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
          _adhanMakkahChannelId,
          'Prayer Times (Makkah Adhan)',
        );
    }

    // iOS notification details — use short .caf clips (<30s) bundled in the app
    String? iOSSound;
    if (mode == PrayerNotificationMode.adhan) {
      iOSSound = prayerName == 'Fajr'
          ? 'adhan_makkah_fajr_notification.caf'
          : (adhanType == AdhanType.makkah
              ? 'adhan_makkah_notification.caf'
              : 'adhan_madinah_notification.caf');
    }

    final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: mode != PrayerNotificationMode.off,
      sound: iOSSound,
    );

    return NotificationDetails(android: androidDetails, iOS: iOSDetails);
  }

  // ── Daily Reminders ────────────────────────────────────────────────────────

  static const int _morningReminderId = 50;
  static const int _eveningReminderId = 51;

  Future<void> scheduleDailyReminders({
    required bool morningEnabled,
    required int morningHour,
    required int morningMinute,
    required bool eveningEnabled,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    await _plugin.cancel(_morningReminderId);
    await _plugin.cancel(_eveningReminderId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        'Daily Reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );

    final now = tz.TZDateTime.now(tz.local);

    if (morningEnabled) {
      tz.TZDateTime morning = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, morningHour, morningMinute);
      if (morning.isBefore(now)) morning = morning.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        _morningReminderId,
        'Time to Read Quran 📖',
        'Start your morning with the words of Allah',
        morning,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    if (eveningEnabled) {
      tz.TZDateTime evening = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, eveningHour, eveningMinute);
      if (evening.isBefore(now)) evening = evening.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        _eveningReminderId,
        'Evening Quran Reminder 🌙',
        'End your day with the words of Allah',
        evening,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // ── Ayah of the Day ────────────────────────────────────────────────────────

  // IDs 100–129 reserved for ayah of the day (30 days pre-scheduled)
  static const int _ayahBaseId = 100;

  Future<void> scheduleAyahNotifications({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    // Cancel all previously scheduled ayah notifications
    for (int i = 0; i < 30; i++) {
      await _plugin.cancel(_ayahBaseId + i);
    }
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    // Starting ayah index: based on day-of-year so it advances daily
    final startIndex = now.difference(tz.TZDateTime(tz.local, now.year, 1, 1)).inDays %
        curatedAyahs.length;

    for (int i = 0; i < 30; i++) {
      final ayah = curatedAyahs[(startIndex + i) % curatedAyahs.length];
      tz.TZDateTime scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      scheduled = scheduled.add(Duration(days: i));
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

      await _plugin.zonedSchedule(
        _ayahBaseId + i,
        '✨ Ayah of the Day — ${ayah.surahName} ${ayah.surah}:${ayah.ayah}',
        '${ayah.translation}\n\n${ayah.message}',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _ayahChannelId,
            'Ayah of the Day',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'ayah_of_the_day',
      );
    }
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
