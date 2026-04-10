import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Entry-point executed inside the foreground-service Dart isolate.
@pragma('vm:entry-point')
void prayerForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(PrayerTaskHandler());
}

/// Controls the prayer-times foreground service (Android only).
///
/// Architecture:
///   • A persistent foreground notification shows "Dubai | 22 Sha'ban 1447"
///     on the first line and "Dhuhr, 12:34" on the second — updates every
///     minute via the 60 s repeat event.
///   • Inside the service's Dart isolate a [Timer] fires at the exact
///     millisecond of each prayer and shows the adhan/vibration notification
///     directly, without going through AlarmManager.
///   • [autoRunOnBoot] restarts the service after device reboot.
///   • When the service is running, [NotificationService.scheduleAllPrayers]
///     skips AlarmManager scheduling to avoid duplicate notifications.
class PrayerForegroundService {
  PrayerForegroundService._();

  /// Call once in [main] before [runApp].
  static void setup() {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'prayer_service',
        channelName: 'Prayer Times Service',
        channelDescription:
            'Shows next prayer and ensures accurate notifications.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // 60 s tick
        autoRunOnBoot: true,
        allowWakeLock: true,
      ),
    );
  }

  /// Start the service if not running, or refresh its data if already running.
  /// Safe to call on every app open.
  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      // Already running — just tell it to re-read prefs and rearm the timer.
      FlutterForegroundTask.sendDataToTask('refresh');
      return;
    }
    final result = await FlutterForegroundTask.startService(
      serviceId: 512,
      notificationTitle: 'Get Quran',
      notificationText: 'Loading prayer times…',
      callback: prayerForegroundTaskCallback,
      // Required on Android 14+: must match foregroundServiceType in manifest.
      serviceTypes: [ForegroundServiceTypes.dataSync],
    );
    if (!result.success) {
      debugPrint('[ForegroundService] startService failed: ${result.error}');
    }
  }

  /// Stop the service — call when the user turns off all notifications.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.stopService();
  }

  /// Ask the running service to recalculate prayer times from SharedPreferences.
  /// Call after a location change or after saving notification settings.
  static void refresh() {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.sendDataToTask('refresh');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Runs inside the foreground-service Dart isolate.
class PrayerTaskHandler extends TaskHandler {
  Timer? _timer;
  String? _nextName;
  DateTime? _nextTime;
  String _cityName = '';
  PrayerNotificationMode _mode = PrayerNotificationMode.singleVibration;
  AdhanType _adhanType = AdhanType.makkah;
  final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static const _hijriMonths = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhul-Qi'dah", 'Dhul-Hijjah',
  ];

  // ── TaskHandler lifecycle ─────────────────────────────────────────────────

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _initNotifications();
    await _loadNextPrayer();
  }

  /// Called every 60 s — updates the status-bar notification and acts as
  /// a safety net in case the Dart Timer somehow misfired.
  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateNotification();
    if (_nextTime != null && DateTime.now().isAfter(_nextTime!)) {
      _firePrayer(); // backup: timer somehow misfired
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _timer?.cancel();
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'refresh') _loadNextPrayer();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    await _notif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    // Create channels in this isolate — they may not exist after a fresh boot
    // before the main app has ever been opened.
    final android = _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final ch in [
      const AndroidNotificationChannel(
        'prayer_times_adhan_makkah', 'Prayer Times (Makkah Adhan)',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan_makkah'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'prayer_times_adhan_madinah', 'Prayer Times (Madinah Adhan)',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan_madinah'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'prayer_times_adhan_fajr', 'Prayer Times (Fajr Adhan)',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan_makkah_fajr'),
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        'prayer_times_vibration', 'Prayer Times (Vibration)',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    ]) {
      await android.createNotificationChannel(ch);
    }
  }

  Future<void> _loadNextPrayer() async {
    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('lat');
    final lng = prefs.getDouble('lng');
    if (lat == null || lng == null) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'Get Quran',
        notificationText: 'Open the app to set your location',
      );
      return;
    }

    _cityName = prefs.getString('cityName') ?? '';
    final calcMethodId = prefs.getString('calcMethod') ?? 'MWL';
    _mode = PrayerNotificationMode.values.firstWhere(
      (e) =>
          e.name ==
          (prefs.getString('prayer_notification_mode') ??
              PrayerNotificationMode.singleVibration.name),
      orElse: () => PrayerNotificationMode.singleVibration,
    );
    _adhanType = AdhanType.values.firstWhere(
      (e) => e.name == (prefs.getString('adhan_type') ?? 'makkah'),
      orElse: () => AdhanType.makkah,
    );

    final coords = adhan.Coordinates(lat, lng);
    final params = _paramsFor(calcMethodId);
    final now = DateTime.now();

    // Find the next upcoming prayer across today and (if needed) tomorrow.
    DateTime? nextTime;
    String? nextName;
    outer:
    for (var day = 0; day <= 1; day++) {
      final date = now.add(Duration(days: day));
      final pt = adhan.PrayerTimes(
        coords,
        adhan.DateComponents(date.year, date.month, date.day),
        params,
      );
      for (final (name, time) in [
        ('Fajr', pt.fajr),
        ('Dhuhr', pt.dhuhr),
        ('Asr', pt.asr),
        ('Maghrib', pt.maghrib),
        ('Isha', pt.isha),
      ]) {
        if (time.isAfter(now)) {
          nextTime = time;
          nextName = name;
          break outer;
        }
      }
    }
    if (nextTime == null) return;

    _nextName = nextName;
    _nextTime = nextTime;

    // Exact Dart Timer — fires in the foreground-service process, not via
    // AlarmManager, so it is immune to Doze and battery optimisation.
    _timer = Timer(nextTime.difference(now), _firePrayer);
    _updateNotification();
  }

  void _firePrayer() {
    _timer?.cancel();
    final name = _nextName;
    if (name == null || _mode == PrayerNotificationMode.off) {
      _loadNextPrayer(); // arm the next prayer even when mode is off
      return;
    }

    final AndroidNotificationDetails android;
    switch (_mode) {
      case PrayerNotificationMode.adhan:
        final channelId = name == 'Fajr'
            ? 'prayer_times_adhan_fajr'
            : (_adhanType == AdhanType.makkah
                ? 'prayer_times_adhan_makkah'
                : 'prayer_times_adhan_madinah');
        final channelName = name == 'Fajr'
            ? 'Prayer Times (Fajr Adhan)'
            : (_adhanType == AdhanType.makkah
                ? 'Prayer Times (Makkah Adhan)'
                : 'Prayer Times (Madinah Adhan)');
        final sound = name == 'Fajr'
            ? 'adhan_makkah_fajr'
            : (_adhanType == AdhanType.makkah ? 'adhan_makkah' : 'adhan_madinah');
        android = AndroidNotificationDetails(
          channelId, channelName,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(sound),
          enableVibration: true,
        );
      case PrayerNotificationMode.vibration:
        android = AndroidNotificationDetails(
          'prayer_times_vibration', 'Prayer Times (Vibration)',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        );
      case PrayerNotificationMode.singleVibration:
      default:
        android = AndroidNotificationDetails(
          'prayer_times_vibration', 'Prayer Times (Vibration)',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400]),
        );
    }

    // Fixed IDs per prayer name — matches the IDs used by AlarmManager
    // so if both fire at the same instant they coalesce into one notification.
    const ids = {'Fajr': 1, 'Dhuhr': 2, 'Asr': 3, 'Maghrib': 4, 'Isha': 5};
    _notif.show(
      ids[name] ?? 1,
      'Prayer Time 🕌',
      "It's time for $name",
      NotificationDetails(android: android),
    );

    _loadNextPrayer(); // arm the next prayer
  }

  /// Updates the persistent status-bar notification to:
  ///   Title: "Dubai | 22 Sha'ban 1447"
  ///   Text:  "Dhuhr, 12:34"
  void _updateNotification() {
    if (_nextName == null || _nextTime == null) return;
    final rem = _nextTime!.difference(DateTime.now());
    if (rem.isNegative) return;

    final now = DateTime.now();
    final (hy, hm, hd) = _toHijri(now);
    final hijriStr = '$hd ${_hijriMonths[hm - 1]} $hy';

    final title = _cityName.isNotEmpty ? '$_cityName | $hijriStr' : hijriStr;

    final local = _nextTime!.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: '$_nextName, $hh:$mm',
    );
  }

  // ── Hijri calendar conversion ─────────────────────────────────────────────

  /// Converts a Gregorian [date] to (hijriYear, hijriMonth, hijriDay).
  /// Uses the standard tabular Islamic calendar algorithm.
  (int, int, int) _toHijri(DateTime date) {
    final jd = _toJulianDay(date.year, date.month, date.day);
    final l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    final ll = l - 10631 * n + 354;
    final j = ((10985 - ll) ~/ 5316) * ((50 * ll) ~/ 17719) +
        (ll ~/ 5670) * ((43 * ll) ~/ 15238);
    final lll = ll -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final hMonth = (24 * lll) ~/ 709;
    final hDay = lll - (709 * hMonth) ~/ 24;
    final hYear = 30 * n + j - 30;
    return (hYear, hMonth.clamp(1, 12), hDay.clamp(1, 30));
  }

  int _toJulianDay(int y, int m, int d) {
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).toInt() +
        (30.6001 * (m + 1)).toInt() +
        d +
        b -
        1524;
  }

  adhan.CalculationParameters _paramsFor(String id) {
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
}
