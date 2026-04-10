import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:adhan/adhan.dart' as adhan;
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
///   • A persistent foreground notification shows "Next Prayer: Asr · 2h 14m"
///     and updates every minute — users see it in the status bar.
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
            'Shows next prayer countdown and ensures accurate notifications.',
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

  /// Start (or restart) the service. Safe to call on every app open.
  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: 512,
      notificationTitle: 'Get Quran',
      notificationText: 'Loading prayer times…',
      callback: prayerForegroundTaskCallback,
    );
  }

  /// Stop the service — call when the user turns off all notifications.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.stopService();
  }

  /// Ask the running service to recalculate prayer times from SharedPreferences.
  /// Call after a location change or after saving notification settings.
  static Future<void> refresh() async {
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
  PrayerNotificationMode _mode = PrayerNotificationMode.singleVibration;
  AdhanType _adhanType = AdhanType.makkah;
  final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  // ── TaskHandler lifecycle ─────────────────────────────────────────────────

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _initNotifications();
    await _loadNextPrayer();
  }

  /// Called every 60 s — updates countdown and acts as safety net.
  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateCountdown();
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
    _updateCountdown();
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

  void _updateCountdown() {
    if (_nextName == null || _nextTime == null) return;
    final rem = _nextTime!.difference(DateTime.now());
    if (rem.isNegative) return;
    final h = rem.inHours;
    final m = rem.inMinutes % 60;
    FlutterForegroundTask.updateService(
      notificationTitle: 'Next Prayer: $_nextName',
      notificationText: h > 0 ? '${h}h ${m}m away' : '${m}m away',
    );
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
