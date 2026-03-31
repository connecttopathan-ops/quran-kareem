import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Location {
  final double latitude;
  final double longitude;
  const Location({required this.latitude, required this.longitude});
}

Future<List<Location>> locationFromAddress(String address) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(address)}&format=json&limit=5',
    );
    final response = await http.get(uri, headers: {
      'User-Agent': 'GetQuran/1.0',
      'Accept-Language': 'en',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final results = jsonDecode(response.body) as List;
      return results
          .map((item) => Location(
                latitude: double.parse(item['lat'] as String),
                longitude: double.parse(item['lon'] as String),
              ))
          .toList();
    }
  } catch (_) {}
  return [];
}

Future<String> _reverseGeocode(double lat, double lng) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$lat&lon=$lng&format=json',
    );
    final response = await http.get(uri, headers: {
      'User-Agent': 'GetQuran/1.0',
      'Accept-Language': 'en',
    }).timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address != null) {
        return address['city'] as String? ??
            address['town'] as String? ??
            address['village'] as String? ??
            address['county'] as String? ??
            'My Location';
      }
    }
  } catch (_) {}
  return 'My Location';
}

class PrayerTimes {
  final double lat, lng;
  final String cityName, calcMethod;
  final String fajrStr, dhuhrStr, asrStr, maghribStr, ishaStr;
  final String nextPrayerName;
  final Duration timeUntilNext;

  const PrayerTimes({
    required this.lat, required this.lng, required this.cityName,
    required this.calcMethod, required this.fajrStr, required this.dhuhrStr,
    required this.asrStr, required this.maghribStr, required this.ishaStr,
    required this.nextPrayerName, required this.timeUntilNext,
  });
}

class CalcMethod {
  final String id, name;
  const CalcMethod({required this.id, required this.name});
  static const List<CalcMethod> all = [
    CalcMethod(id: 'MWL', name: 'Muslim World League'),
    CalcMethod(id: 'ISNA', name: 'ISNA (North America)'),
    CalcMethod(id: 'Egyptian', name: 'Egyptian Authority'),
    CalcMethod(id: 'Karachi', name: 'Karachi (Hanafi)'),
    CalcMethod(id: 'UmmAlQura', name: 'Umm Al-Qura (Mecca)'),
    CalcMethod(id: 'Tehran', name: 'Tehran Institute'),
  ];
}

class LocationService extends ChangeNotifier {
  PrayerTimes? _prayerTimes;
  bool _loading = false;
  String? _error;
  String _calcMethodId = 'MWL';

  PrayerTimes? get prayerTimes => _prayerTimes;
  bool get loading => _loading;
  String? get error => _error;
  String get calcMethodId => _calcMethodId;

  LocationService() { _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _calcMethodId = p.getString('calcMethod') ?? 'MWL';
    final lat = p.getDouble('lat');
    final lng = p.getDouble('lng');
    final city = p.getString('cityName');
    if (lat != null && lng != null && city != null) {
      _prayerTimes = _calc(lat, lng, city);
      notifyListeners();
    } else {
      // No stored location — silently auto-fetch if permission already granted
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        fetchLocation(); // fire-and-forget; it calls notifyListeners() internally
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> fetchLocation() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services disabled. Please enable GPS.';
        _loading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _error = 'Location permission denied. Please set city manually.';
        _loading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final cityName = await _reverseGeocode(position.latitude, position.longitude);
      await setManualLocation(position.latitude, position.longitude, cityName);
    } catch (e) {
      _error = 'Could not get location. Please set city manually.';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setManualLocation(double lat, double lng, String city) async {
    _prayerTimes = _calc(lat, lng, city);
    _error = null;
    _loading = false;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('lat', lat);
    await p.setDouble('lng', lng);
    await p.setString('cityName', city);
    await _saveWidgetData(_prayerTimes!);
    notifyListeners();
  }

  /// Saves prayer times and qibla data so home screen widgets can read them.
  /// - Android: writes to FlutterSharedPreferences (keys prefixed `flutter.`)
  ///            and broadcasts widget update via MethodChannel.
  /// - iOS:     passes data through MethodChannel so native WidgetPlugin writes
  ///            to the shared App Group UserDefaults and reloads WidgetKit timelines.
  Future<void> _saveWidgetData(PrayerTimes pt) async {
    try {
      final bearing = _calcQiblaBearing(pt.lat, pt.lng);
      final hijri   = _hijriDate();

      // Android: write to Flutter SharedPreferences (widgets read these directly)
      final p = await SharedPreferences.getInstance();
      await p.setString('widget_fajr',         pt.fajrStr);
      await p.setString('widget_dhuhr',         pt.dhuhrStr);
      await p.setString('widget_asr',           pt.asrStr);
      await p.setString('widget_maghrib',       pt.maghribStr);
      await p.setString('widget_isha',          pt.ishaStr);
      await p.setString('widget_city',          pt.cityName);
      await p.setString('widget_next_prayer',   pt.nextPrayerName);
      await p.setDouble('widget_qibla_degrees', bearing);
      await p.setString('widget_hijri',         hijri);

      // Trigger widget refresh via MethodChannel.
      // On Android → MainActivity broadcasts update to AppWidgetProviders.
      // On iOS     → WidgetPlugin writes to App Group UserDefaults + reloads WidgetKit.
      try {
        await const MethodChannel('co.getquran.app/widget').invokeMethod(
          'updateWidgets',
          {
            'widget_fajr':         pt.fajrStr,
            'widget_dhuhr':        pt.dhuhrStr,
            'widget_asr':          pt.asrStr,
            'widget_maghrib':      pt.maghribStr,
            'widget_isha':         pt.ishaStr,
            'widget_city':         pt.cityName,
            'widget_next_prayer':  pt.nextPrayerName,
            'widget_qibla_degrees': bearing,
            'widget_hijri':        hijri,
          },
        );
      } catch (_) {}
    } catch (_) {}
  }

  String _hijriDate() {
    // Simple Hijri approximation (±1 day accuracy)
    final now = DateTime.now();
    final jd = _julianDay(now.year, now.month, now.day);
    final z = (jd - 1948439.5).floor();
    final a = ((z - 122.1) / 365.25).floor();
    final b = z - (365.25 * a).floor();
    final c = ((b - 0.1) / 30.6001).floor();
    final day = b - (30.6001 * c).floor();
    final rawMonth = c < 14 ? c - 1 : c - 13;
    final rawYear = rawMonth > 2 ? a - 4716 : a - 4715;
    // Convert Gregorian JD to Hijri
    final l = z + 68569 + 60;
    final n = (4 * l ~/ 146097);
    final l2 = l - (146097 * n + 3) ~/ 4;
    final i = 4000 * (l2 + 1) ~/ 1461001;
    final l3 = l2 - 1461 * i ~/ 4 + 31;
    final j = 80 * l3 ~/ 2447;
    final d = l3 - 2447 * j ~/ 80;
    final l4 = j ~/ 11;
    final m = j + 2 - 12 * l4;
    final y = 100 * (n - 49) + i + l4;
    // Hijri conversion
    final jdHijri = jd.floor();
    final l5 = jdHijri - 1948440 + 10632;
    final n2 = (l5 - 1) ~/ 10631;
    final l6 = l5 - 10631 * n2 + 354;
    final j2 = ((10985 - l6) ~/ 5316) * ((50 * l6) ~/ 17719) +
        (l6 ~/ 5670) * ((43 * l6) ~/ 15238);
    final l7 = l6 - ((30 - j2) ~/ 15) * ((17719 * j2) ~/ 50) -
        (j2 ~/ 16) * ((15238 * j2) ~/ 43) + 29;
    final month = 24 * l7 ~/ 709;
    final day2 = l7 - 709 * month ~/ 24;
    final year = 30 * n2 + j2 - 30;
    const months = [
      'Muharram','Safar','Rabi I','Rabi II','Jumada I','Jumada II',
      'Rajab','Sha\'ban','Ramadan','Shawwal','Dhu al-Qi\'dah','Dhu al-Hijjah'
    ];
    final mIdx = (month - 1).clamp(0, 11);
    return '$day2 ${months[mIdx]} $year';
  }

  double _julianDay(int y, int m, int d) {
    if (m <= 2) { y -= 1; m += 12; }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() + d + b - 1524.5;
  }

  double _calcQiblaBearing(double lat, double lng) {
    const mLat = 21.4225 * pi / 180;
    const mLon = 39.8262 * pi / 180;
    final uLat = lat * pi / 180;
    final uLon = lng * pi / 180;
    final dLon = mLon - uLon;
    final y = sin(dLon) * cos(mLat);
    final x = cos(uLat) * sin(mLat) - sin(uLat) * cos(mLat) * cos(dLon);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  Future<void> setCalcMethod(String id) async {
    _calcMethodId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('calcMethod', id);
    if (_prayerTimes != null) {
      _prayerTimes = _calc(_prayerTimes!.lat, _prayerTimes!.lng, _prayerTimes!.cityName);
      await _saveWidgetData(_prayerTimes!);
    }
    notifyListeners();
  }

  PrayerTimes _calc(double lat, double lng, String city) {
    final now = DateTime.now();

    // ── Julian Day Number for today ──────────────────────────────────────────
    int y = now.year, m = now.month, d = now.day;
    if (m <= 2) { y--; m += 12; }
    final int A = y ~/ 100;
    final int B = 2 - A + A ~/ 4;
    final double jd = (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d.toDouble() +
        B -
        1524.5;

    // ── Solar position (USNO low-precision formulae) ─────────────────────────
    final double D = jd - 2451545.0; // days from J2000.0
    final double g = _fixAngle(357.529 + 0.98560028 * D); // mean anomaly (°)
    final double q = _fixAngle(280.459 + 0.98564736 * D); // mean longitude (°)
    final double L = _fixAngle(
        q + 1.915 * sin(_rad(g)) + 0.02 * sin(_rad(2 * g))); // ecliptic lon (°)
    final double e = 23.439 - 0.00000036 * D; // obliquity of ecliptic (°)

    // Right ascension (hours, 0–24)
    double RA = _fixAngle(_deg(atan2(cos(_rad(e)) * sin(_rad(L)), cos(_rad(L))))) / 15;
    // Declination (radians)
    final double decl = asin(sin(_rad(e)) * sin(_rad(L)));
    // Equation of time (hours)
    double EqT = q / 15 - RA;
    if (EqT > 12) EqT -= 24;
    if (EqT < -12) EqT += 24;

    // UTC offset of the device
    final double utcOffset = now.timeZoneOffset.inMinutes / 60.0;

    // Solar noon in local device time (hours)
    final double midday = 12 - lng / 15 - EqT + utcOffset;

    // ── Hour-angle helper ────────────────────────────────────────────────────
    // Returns hours from midday to reach a given sun altitude (degrees).
    double ha(double altDeg) {
      double cosT = (sin(_rad(altDeg)) - sin(_rad(lat)) * sin(decl)) /
          (cos(_rad(lat)) * cos(decl));
      cosT = cosT.clamp(-1.0, 1.0);
      return _deg(acos(cosT)) / 15;
    }

    // ── Fajr / Isha angles by calculation method ─────────────────────────────
    double fajrAngle, ishaAngle;
    bool ishaIsOffset = false;
    int ishaOffsetMin = 0;
    switch (_calcMethodId) {
      case 'ISNA':
        fajrAngle = 15.0; ishaAngle = 15.0;
      case 'Egyptian':
        fajrAngle = 19.5; ishaAngle = 17.5;
      case 'Karachi':
        fajrAngle = 18.0; ishaAngle = 18.0;
      case 'UmmAlQura':
        fajrAngle = 18.5; ishaAngle = 0; ishaIsOffset = true; ishaOffsetMin = 90;
      case 'Tehran':
        fajrAngle = 17.7; ishaAngle = 14.0;
      default: // MWL
        fajrAngle = 18.0; ishaAngle = 17.0;
    }

    // ── Asr altitude (shadow factor: Shafi'i = 1, Hanafi = 2) ───────────────
    final double asrFactor = _calcMethodId == 'Karachi' ? 2.0 : 1.0;
    final double asrAlt =
        atan(1.0 / (asrFactor + tan((decl - _rad(lat)).abs())));
    // Hour angle for Asr (sun above horizon at asrAlt radians)
    double asrCosT = (sin(asrAlt) - sin(_rad(lat)) * sin(decl)) /
        (cos(_rad(lat)) * cos(decl));
    asrCosT = asrCosT.clamp(-1.0, 1.0);
    final double asrHA = _deg(acos(asrCosT)) / 15;

    // ── Prayer hours (local device time, decimal) ────────────────────────────
    final double fajrHour    = midday - ha(-fajrAngle);
    final double dhuhrHour   = midday;
    final double asrHour     = midday + asrHA;
    final double maghribHour = midday + ha(-0.833);
    final double ishaHour    = ishaIsOffset
        ? maghribHour + ishaOffsetMin / 60.0
        : midday + ha(-ishaAngle);

    // ── Convert decimal hours → local DateTime ───────────────────────────────
    DateTime toDateTime(double hours) {
      final int totalMins = (hours * 60).round();
      return DateTime(
          now.year, now.month, now.day, (totalMins ~/ 60) % 24, totalMins % 60);
    }

    String fmt(DateTime t) {
      final int h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? "PM" : "AM"}';
    }

    final times = [
      toDateTime(fajrHour),
      toDateTime(dhuhrHour),
      toDateTime(asrHour),
      toDateTime(maghribHour),
      toDateTime(ishaHour),
    ];
    const names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    String nextName = names[0];
    Duration untilNext = const Duration(hours: 8);
    for (int i = 0; i < times.length; i++) {
      if (now.isBefore(times[i])) {
        nextName = names[i];
        untilNext = times[i].difference(now);
        break;
      }
    }
    // Past Isha → next is Fajr tomorrow
    if (now.isAfter(times[4])) {
      nextName = names[0];
      untilNext = toDateTime(fajrHour).add(const Duration(days: 1)).difference(now);
    }

    return PrayerTimes(
      lat: lat, lng: lng, cityName: city, calcMethod: _calcMethodId,
      fajrStr: fmt(times[0]), dhuhrStr: fmt(times[1]), asrStr: fmt(times[2]),
      maghribStr: fmt(times[3]), ishaStr: fmt(times[4]),
      nextPrayerName: nextName, timeUntilNext: untilNext,
    );
  }

  // ── Math helpers ─────────────────────────────────────────────────────────
  static double _rad(double deg) => deg * pi / 180;
  static double _deg(double rad) => rad * 180 / pi;
  static double _fixAngle(double a) => a - 360.0 * (a / 360.0).floor();
}
