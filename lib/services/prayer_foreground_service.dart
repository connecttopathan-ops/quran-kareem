import 'dart:async';
import 'dart:io';
import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Entry-point executed inside the foreground-service Dart isolate.
@pragma('vm:entry-point')
void prayerForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(PrayerTaskHandler());
}

/// Controls the prayer-times foreground service (Android only).
///
/// Responsibility: maintain a persistent status-bar notification that shows
///   Title: "Dubai | 22 Sha'ban 1447"
///   Text:  "Dhuhr, 12:34"
/// and updates automatically every minute and at each prayer boundary.
///
/// Actual prayer-alarm notifications continue to be fired by AlarmManager
/// (flutter_local_notifications) from the main app process — this service
/// does NOT replace them.  Its value is the always-visible live countdown and
/// the fact that [autoRunOnBoot] keeps the service (and therefore the
/// notification) alive across reboots without the user having to reopen
/// the app.
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
      // Already running — just tell it to re-read prefs and update.
      FlutterForegroundTask.sendDataToTask('refresh');
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: 512,
      notificationTitle: 'Get Quran',
      notificationText: 'Loading prayer times…',
      callback: prayerForegroundTaskCallback,
      // v9.1+: pass service type at runtime so startForeground() includes it.
      // Required when targetSdk >= 34 (Android 14+) — without this the OS
      // throws InvalidForegroundServiceTypeException and the service is killed.
      serviceTypes: [ForegroundServiceTypes.dataSync],
    );
  }

  /// Stop the service — call when the user turns off all notifications.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.stopService();
  }

  /// Ask the running service to recalculate prayer times from SharedPreferences.
  static void refresh() {
    if (!Platform.isAndroid) return;
    FlutterForegroundTask.sendDataToTask('refresh');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Runs inside the foreground-service Dart isolate.
///
/// Notification format:
///   Title: "Dubai | 22 Sha'ban 1447"
///   Text (upcoming):  "Dhuhr, 12:34  In 00:45:10"
///   Text (elapsed):   "Dhuhr, 12:34  ◉ +05:56"   ← 30-min grace period
class PrayerTaskHandler extends TaskHandler {
  Timer? _boundaryTimer;
  Timer? _tickTimer;    // 1-second tick drives the live display
  Timer? _graceTimer;   // fires after 30-min grace period → load next prayer

  // Upcoming prayer (shown while grace period is not active)
  String? _nextName;
  DateTime? _nextTime;

  // Last prayer that passed (shown during grace period)
  String? _lastPrayerName;
  DateTime? _lastPrayerTime;
  bool _inElapsedMode = false;

  String _cityName = '';

  static const _graceMinutes = 30;

  static const _hijriMonths = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
    'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhul-Qi'dah", 'Dhul-Hijjah',
  ];

  // ── TaskHandler lifecycle ─────────────────────────────────────────────────

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _loadNextPrayer();
  }

  /// Called every 60 s — skipped during grace period so elapsed display
  /// is not interrupted; a 'refresh' signal always forces a reload.
  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_inElapsedMode) _loadNextPrayer();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _boundaryTimer?.cancel();
    _tickTimer?.cancel();
    _graceTimer?.cancel();
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'refresh') _loadNextPrayer();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _loadNextPrayer() async {
    _boundaryTimer?.cancel();
    _tickTimer?.cancel();
    _graceTimer?.cancel();
    _inElapsedMode = false;
    _lastPrayerName = null;
    _lastPrayerTime = null;

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

    // Boundary timer: when prayer time arrives, enter the 30-min grace period.
    _boundaryTimer = Timer(nextTime.difference(now), _enterElapsedMode);

    // 1-second tick drives the live display.
    _tickTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateNotification());
    _updateNotification();
  }

  /// Called exactly at a prayer time. Switches the notification to elapsed
  /// mode ("◉ +MM:SS") and starts the 30-minute grace timer.
  void _enterElapsedMode() {
    _lastPrayerName = _nextName;
    _lastPrayerTime = _nextTime;
    _inElapsedMode = true;

    // After the grace period, load the next upcoming prayer.
    _graceTimer = Timer(
        const Duration(minutes: _graceMinutes), _loadNextPrayer);

    // _tickTimer is still running — it will now render elapsed mode.
    _updateNotification();
  }

  // ── Notification rendering ────────────────────────────────────────────────

  void _updateNotification() {
    final now = DateTime.now();
    final (hy, hm, hd) = _toHijri(now);
    final hijriStr = '$hd ${_hijriMonths[hm - 1]} $hy';
    final title = _cityName.isNotEmpty ? '$_cityName | $hijriStr' : hijriStr;

    if (_inElapsedMode) {
      _renderElapsed(title, now);
    } else {
      _renderUpcoming(title, now);
    }
  }

  /// Upcoming: "Maghrib, 16:26  In 00:30:03"
  void _renderUpcoming(String title, DateTime now) {
    if (_nextName == null || _nextTime == null) return;
    final rem = _nextTime!.difference(now);
    if (rem.isNegative) return;

    final local = _nextTime!.toLocal();
    final ph = local.hour.toString().padLeft(2, '0');
    final pm = local.minute.toString().padLeft(2, '0');

    final total = rem.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    final countdown =
        '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: '$_nextName, $ph:$pm  In $countdown',
    );
  }

  /// Elapsed: "Maghrib, 16:26  ◉ +05:56"
  void _renderElapsed(String title, DateTime now) {
    if (_lastPrayerName == null || _lastPrayerTime == null) return;
    final elapsed = now.difference(_lastPrayerTime!);

    final local = _lastPrayerTime!.toLocal();
    final ph = local.hour.toString().padLeft(2, '0');
    final pm = local.minute.toString().padLeft(2, '0');

    final total = elapsed.inSeconds.clamp(0, 99 * 60 + 59);
    final m = total ~/ 60;
    final s = total % 60;
    final mmss =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: '$_lastPrayerName, $ph:$pm  ◉ +$mmss',
    );
  }

  // ── Hijri calendar conversion ─────────────────────────────────────────────

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
    if (m <= 2) { y -= 1; m += 12; }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).toInt() +
        (30.6001 * (m + 1)).toInt() +
        d + b - 1524;
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
