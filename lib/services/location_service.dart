import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    }
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> setCalcMethod(String id) async {
    _calcMethodId = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('calcMethod', id);
    if (_prayerTimes != null) {
      _prayerTimes = _calc(_prayerTimes!.lat, _prayerTimes!.lng, _prayerTimes!.cityName);
    }
    notifyListeners();
  }

  PrayerTimes _calc(double lat, double lng, String city) {
    final now = DateTime.now();
    final times = [
      DateTime(now.year, now.month, now.day, 5, 15),
      DateTime(now.year, now.month, now.day, 12, 30),
      DateTime(now.year, now.month, now.day, 15, 45),
      DateTime(now.year, now.month, now.day, 18, 20),
      DateTime(now.year, now.month, now.day, 19, 45),
    ];
    final names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    String fmt(DateTime t) {
      final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      return '$h:${t.minute.toString().padLeft(2,'0')} ${t.hour >= 12 ? "PM" : "AM"}';
    }

    String nextName = 'Fajr';
    Duration untilNext = const Duration(hours: 8);
    for (int i = 0; i < times.length; i++) {
      if (now.isBefore(times[i])) {
        nextName = names[i];
        untilNext = times[i].difference(now);
        break;
      }
    }

    return PrayerTimes(
      lat: lat, lng: lng, cityName: city, calcMethod: _calcMethodId,
      fajrStr: fmt(times[0]), dhuhrStr: fmt(times[1]), asrStr: fmt(times[2]),
      maghribStr: fmt(times[3]), ishaStr: fmt(times[4]),
      nextPrayerName: nextName, timeUntilNext: untilNext,
    );
  }
}
