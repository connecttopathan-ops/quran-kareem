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
/// Intentionally simple: reads prefs, calculates the next prayer, updates
/// the persistent notification, and sets a [Timer] to refresh at the prayer
/// boundary.  No flutter_local_notifications usage here — prayer alarm
/// notifications are handled by AlarmManager in the main process.
class PrayerTaskHandler extends TaskHandler {
  Timer? _boundaryTimer;
  String? _nextName;
  DateTime? _nextTime;
  String _cityName = '';

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

  /// Called every 60 s — keeps the notification text fresh.
  @override
  void onRepeatEvent(DateTime timestamp) {
    _updateNotification();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _boundaryTimer?.cancel();
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'refresh') _loadNextPrayer();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _loadNextPrayer() async {
    _boundaryTimer?.cancel();

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

    // Timer fires at the prayer boundary so the notification updates to the
    // next prayer instantly rather than waiting for the 60 s tick.
    _boundaryTimer = Timer(nextTime.difference(now), _loadNextPrayer);
    _updateNotification();
  }

  /// Updates the persistent notification to match Salatuk's style:
  ///   Title: "Dubai | 22 Sha'ban 1447"
  ///   Text:  "Maghrib, 18:43  -01:22"   (prayer time + live countdown)
  void _updateNotification() {
    if (_nextName == null || _nextTime == null) return;
    final now = DateTime.now();
    final rem = _nextTime!.difference(now);
    if (rem.isNegative) return;

    final (hy, hm, hd) = _toHijri(now);
    final hijriStr = '$hd ${_hijriMonths[hm - 1]} $hy';
    final title = _cityName.isNotEmpty ? '$_cityName | $hijriStr' : hijriStr;

    final local = _nextTime!.toLocal();
    final ph = local.hour.toString().padLeft(2, '0');
    final pm = local.minute.toString().padLeft(2, '0');

    // Countdown: "-1h 23m" when > 1 h, "-01:22" (mm:ss) when under 1 h.
    final String countdown;
    if (rem.inHours >= 1) {
      final h = rem.inHours;
      final m = rem.inMinutes % 60;
      countdown = '-${h}h ${m}m';
    } else {
      final m = rem.inMinutes;
      final s = rem.inSeconds % 60;
      countdown =
          '-${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: '$_nextName, $ph:$pm  $countdown',
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
