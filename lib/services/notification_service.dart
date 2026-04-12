// ⚠️ Replace placeholder files in android/app/src/main/res/raw/ with real adhan mp3 audio.
// adhan_makkah_fajr.mp3 is used for Fajr regardless of which mosque the user selects.

// ⚠️ IMPORTANT: After deploying this fix, the app MUST be uninstalled
// and reinstalled on the test device. Simply updating is not enough
// because Android persists old notification channels even across updates.
// Uninstall → reinstall → go to Prayer Notifications → Save & Schedule.

import 'dart:typed_data';
import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // Prayer slots: 7 days × 5 prayers = IDs 1–35 (one-shot absolute alarms,
  // no matchDateTimeComponents — avoids daily drift and clock-change issues)
  static const int _prayerBaseId = 1;
  static const int _prayerDays = 7;
  static const List<String> _prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha'
  ];

  // Bump this when channel config changes (sound, importance, etc.).
  // Channels are only deleted and recreated when this version advances —
  // preserving any per-channel OS settings the user has customised.
  static const int _channelVersion = 1;

  /// Writes reminder defaults to SharedPreferences the very first time the
  /// app runs.  Uses [containsKey] so existing users' choices are never touched.
  Future<void> _seedDefaultsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    // Morning reading reminder — 6:00 AM, enabled
    if (!prefs.containsKey('reminder_morning_enabled')) {
      await prefs.setBool('reminder_morning_enabled', true);
    }
    if (!prefs.containsKey('reminder_morning_hour')) {
      await prefs.setInt('reminder_morning_hour', 6);
    }
    if (!prefs.containsKey('reminder_morning_minute')) {
      await prefs.setInt('reminder_morning_minute', 0);
    }
    // Evening reading reminder — 8:00 PM, enabled
    if (!prefs.containsKey('reminder_evening_enabled')) {
      await prefs.setBool('reminder_evening_enabled', true);
    }
    if (!prefs.containsKey('reminder_evening_hour')) {
      await prefs.setInt('reminder_evening_hour', 20);
    }
    if (!prefs.containsKey('reminder_evening_minute')) {
      await prefs.setInt('reminder_evening_minute', 0);
    }
    // Ayah of the Day — 11:00 AM, enabled
    if (!prefs.containsKey('ayah_notification_enabled')) {
      await prefs.setBool('ayah_notification_enabled', true);
    }
    if (!prefs.containsKey('ayah_notification_hour')) {
      await prefs.setInt('ayah_notification_hour', 11);
    }
    if (!prefs.containsKey('ayah_notification_minute')) {
      await prefs.setInt('ayah_notification_minute', 0);
    }
  }

  Future<void> init() async {
    await _seedDefaultsIfNeeded();
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

    // Only migrate channels when the version advances — not on every launch.
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt('notification_channel_version') ?? 0;
    if (storedVersion < _channelVersion) {
      // Delete legacy channel IDs from old builds and current ones so they
      // are recreated with the correct sound / importance settings.
      await androidPlugin?.deleteNotificationChannel('prayer_times');
      await androidPlugin?.deleteNotificationChannel('prayer_times_adhan');
      await androidPlugin?.deleteNotificationChannel(_adhanMakkahChannelId);
      await androidPlugin?.deleteNotificationChannel(_adhanMadinahChannelId);
      await androidPlugin?.deleteNotificationChannel(_adhanFajrChannelId);
      await androidPlugin?.deleteNotificationChannel(_vibrationChannelId);
      await androidPlugin?.deleteNotificationChannel(_reminderChannelId);
      await androidPlugin?.deleteNotificationChannel(_ayahChannelId);

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

      await androidPlugin?.createNotificationChannel(adhanMakkahChannel);
      await androidPlugin?.createNotificationChannel(adhanMadinahChannel);
      await androidPlugin?.createNotificationChannel(adhanFajrChannel);
      await androidPlugin?.createNotificationChannel(vibrationChannel);
      await androidPlugin?.createNotificationChannel(reminderChannel);
      await androidPlugin?.createNotificationChannel(ayahChannel);

      await prefs.setInt('notification_channel_version', _channelVersion);
    }

    // NOTE: Runtime permissions (POST_NOTIFICATIONS on Android 13+, and the
    // SCHEDULE_EXACT_ALARM rationale dialog) are intentionally NOT requested
    // here. Doing so from init() — before runApp() — is unreliable because the
    // FlutterActivity hasn't fully attached yet, so the system dialog often
    // doesn't appear. HomeScreen requests them from a post-frame callback.
  }

  /// Returns true if POST_NOTIFICATIONS is granted (or not needed pre-Android 13).
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  /// Returns true if exact alarms are permitted.
  /// Uses AlarmManager.canScheduleExactAlarms() on Android 12+,
  /// always true on older Android and iOS.
  Future<bool> hasExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return false; // can't check on Android → assume not granted
      final canSchedule = await androidPlugin.canScheduleExactNotifications();
      return canSchedule ?? false; // null → assume not granted, show dialog
    } catch (_) {
      return false; // unknown → show the permission row to be safe
    }
  }

  /// Opens the Android Alarms & Reminders settings page for this app.
  Future<void> openExactAlarmSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {
      // Fallback: open general app settings if specific page unavailable
      await openAppSettings();
    }
  }


  /// Schedules [_prayerDays] × 5 one-shot absolute alarms using coordinates
  /// and a calculation method ID.  Each alarm fires exactly once at the
  /// calculated prayer time for that specific calendar day — no daily repeat,
  /// no accumulated drift.  Cancels all existing prayer slots first so calling
  /// this again (e.g. on every app open) always gives fresh, accurate times.
  Future<void> scheduleAllPrayers(
    double lat,
    double lng,
    String calcMethodId,
    PrayerNotificationMode mode, {
    AdhanType adhanType = AdhanType.makkah,
  }) async {
    await cancelPrayerNotifications(); // always clear old slots first

    if (mode == PrayerNotificationMode.off) return;

    final scheduleMode = await _resolveScheduleMode();
    final now = tz.TZDateTime.now(tz.local);

    final coordinates = adhan.Coordinates(lat, lng);
    final params = _adhanParamsForMethod(calcMethodId);

    int slotId = _prayerBaseId;

    for (int day = 0; day < _prayerDays; day++) {
      final date = DateTime.now().add(Duration(days: day));
      final pt = adhan.PrayerTimes(
        coordinates,
        adhan.DateComponents(date.year, date.month, date.day),
        params,
      );

      final prayerDateTimes = [pt.fajr, pt.dhuhr, pt.asr, pt.maghrib, pt.isha];

      for (int p = 0; p < _prayerNames.length; p++) {
        final prayerDT = prayerDateTimes[p];
        final scheduledDate = tz.TZDateTime.from(prayerDT, tz.local);

        if (scheduledDate.isBefore(now)) {
          slotId++;
          continue; // skip prayers that have already passed
        }

        final details = _buildNotificationDetails(_prayerNames[p], mode, adhanType);

        await _safeZonedSchedule(
          id: slotId,
          title: 'Prayer Time 🕌',
          body: "It's time for ${_prayerNames[p]}",
          scheduledDate: scheduledDate,
          details: details,
          scheduleMode: scheduleMode,
          // No matchDateTimeComponents — one-shot absolute alarm per day.
          // Rescheduled on every app open via _onPrayerTimesUpdated.
        );

        slotId++;
      }
    }
  }

  /// Returns adhan calculation parameters for the given method ID string.
  /// Mirrors LocationService._adhanParams() to keep services independent.
  adhan.CalculationParameters _adhanParamsForMethod(String id) {
    switch (id) {
      case 'ISNA':      return adhan.CalculationMethod.north_america.getParameters();
      case 'Egyptian':  return adhan.CalculationMethod.egyptian.getParameters();
      case 'Karachi':
        final p = adhan.CalculationMethod.karachi.getParameters();
        p.madhab = adhan.Madhab.hanafi;
        return p;
      case 'UmmAlQura': return adhan.CalculationMethod.umm_al_qura.getParameters();
      case 'Dubai':     return adhan.CalculationMethod.dubai.getParameters();
      case 'Kuwait':    return adhan.CalculationMethod.kuwait.getParameters();
      case 'Qatar':     return adhan.CalculationMethod.qatar.getParameters();
      case 'Singapore': return adhan.CalculationMethod.singapore.getParameters();
      case 'Tehran':    return adhan.CalculationMethod.tehran.getParameters();
      default:          return adhan.CalculationMethod.muslim_world_league.getParameters();
    }
  }

  /// Picks [AndroidScheduleMode.exactAllowWhileIdle] if we can schedule exact
  /// alarms, otherwise falls back to [AndroidScheduleMode.inexactAllowWhileIdle]
  /// so notifications still fire (with drift).
  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final canExact = await hasExactAlarmPermission();
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
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

    final scheduleMode = await _resolveScheduleMode();
    final now = tz.TZDateTime.now(tz.local);

    if (morningEnabled) {
      tz.TZDateTime morning = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, morningHour, morningMinute);
      if (morning.isBefore(now)) morning = morning.add(const Duration(days: 1));
      await _safeZonedSchedule(
        id: _morningReminderId,
        title: 'Time to Read Quran 📖',
        body: 'Start your morning with the words of Allah',
        scheduledDate: morning,
        details: details,
        scheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'read_quran',
      );
    }

    if (eveningEnabled) {
      tz.TZDateTime evening = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, eveningHour, eveningMinute);
      if (evening.isBefore(now)) evening = evening.add(const Duration(days: 1));
      await _safeZonedSchedule(
        id: _eveningReminderId,
        title: 'Evening Quran Reminder 🌙',
        body: 'End your day with the words of Allah',
        scheduledDate: evening,
        details: details,
        scheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'read_quran',
      );
    }
  }

  /// Wraps `zonedSchedule` with exact→inexact fallback and try/catch so a
  /// single SecurityException doesn't abort the rest of the batch.
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode scheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule id=$id ($scheduleMode): $e');
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
        } catch (e2) {
          debugPrint('[NotificationService] Fallback inexact also failed id=$id: $e2');
        }
      }
    }
  }

  // ── Ayah of the Day ────────────────────────────────────────────────────────

  // IDs 100–129 reserved for ayah of the day (30 days pre-scheduled)
  static const int _ayahBaseId = 100;
  static const int _ayahDays = 30;

  Future<void> scheduleAyahNotifications({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    // Cancel all previously scheduled ayah notifications
    for (int i = 0; i < _ayahDays; i++) {
      await _plugin.cancel(_ayahBaseId + i);
    }
    if (!enabled) return;

    final scheduleMode = await _resolveScheduleMode();
    final now = tz.TZDateTime.now(tz.local);
    // Starting ayah index: based on day-of-year so it advances daily
    final startIndex = now.difference(tz.TZDateTime(tz.local, now.year, 1, 1)).inDays %
        curatedAyahs.length;

    for (int i = 0; i < _ayahDays; i++) {
      final ayah = curatedAyahs[(startIndex + i) % curatedAyahs.length];
      tz.TZDateTime scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      scheduled = scheduled.add(Duration(days: i));
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

      await _safeZonedSchedule(
        id: _ayahBaseId + i,
        title: '✨ Ayah of the Day — ${ayah.surahName} ${ayah.surah}:${ayah.ayah}',
        body: '${ayah.translation}\n\n${ayah.message}',
        scheduledDate: scheduled,
        details: NotificationDetails(
          android: AndroidNotificationDetails(
            _ayahChannelId,
            'Ayah of the Day',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            styleInformation: BigTextStyleInformation(
              '${ayah.translation}\n\n${ayah.message}',
            ),
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        scheduleMode: scheduleMode,
        payload: 'ayah_of_the_day',
      );
    }
  }

  /// Cancels all prayer notification slots (IDs 1 – [_prayerBaseId + _prayerDays×5]).
  /// Does NOT touch daily reminders or ayah notifications.
  Future<void> cancelPrayerNotifications() async {
    final total = _prayerDays * _prayerNames.length;
    for (int i = 0; i < total; i++) {
      await _plugin.cancel(_prayerBaseId + i);
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

}
