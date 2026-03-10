import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

// Reading themes
enum ReaderTheme { warm, paper, dark }

// Reading modes
enum ReadingMode { list, page, focus }

class AppState extends ChangeNotifier {
  // ── Language ────────────────────────────────────────────────────
  String _langCode = 'en';

  // ── Display ─────────────────────────────────────────────────────
  bool _isDarkMode = false;        // app-level dark mode
  ReaderTheme _readerTheme = ReaderTheme.warm; // reader-specific theme

  // ── Text sizes ──────────────────────────────────────────────────
  double _arabicFontSize   = 24.0; // range 16–40
  double _translitFontSize = 13.0; // range 10–22
  double _translationFontSize = 14.0; // range 10–22

  // ── Visibility toggles ──────────────────────────────────────────
  bool _showTranslit    = true;
  bool _showTranslation = true;

  // ── Reading ─────────────────────────────────────────────────────
  ReadingMode _readingMode = ReadingMode.list;
  bool _keepScreenOn = true;

  // ── Stats & Continue Reading ────────────────────────────────────
  int _dayStreak = 0;
  int _surahsRead = 0;
  int _versesRead = 0;
  int _lastSurahNumber = 1;
  String _lastSurahName = 'Al-Fatihah';
  Set<int> _readSurahs = {};

  // ── Getters ─────────────────────────────────────────────────────
  String get langCode           => _langCode;
  bool   get isDarkMode         => _isDarkMode;
  ReaderTheme get readerTheme   => _readerTheme;
  double get arabicFontSize     => _arabicFontSize;
  double get translitFontSize   => _translitFontSize;
  double get translationFontSize => _translationFontSize;
  bool   get showTranslit       => _showTranslit;
  bool   get showTranslation    => _showTranslation;
  ReadingMode get readingMode   => _readingMode;
  bool   get keepScreenOn       => _keepScreenOn;
  int    get dayStreak          => _dayStreak;
  int    get surahsRead         => _surahsRead;
  int    get versesRead         => _versesRead;
  int    get lastSurahNumber    => _lastSurahNumber;
  String get lastSurahName      => _lastSurahName;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Language get currentLanguage =>
      kLanguages.firstWhere((l) => l.code == _langCode,
          orElse: () => kLanguages.first);

  AppState() { _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _langCode            = p.getString('langCode')     ?? 'en';
    _isDarkMode          = p.getBool('isDarkMode')     ?? false;
    _readerTheme         = ReaderTheme.values[p.getInt('readerTheme') ?? 0];
    _arabicFontSize      = p.getDouble('arabicSize')   ?? 24.0;
    _translitFontSize    = p.getDouble('translitSize') ?? 13.0;
    _translationFontSize = p.getDouble('transSize')    ?? 14.0;
    _showTranslit        = p.getBool('showTranslit')   ?? true;
    _showTranslation     = p.getBool('showTranslation')?? true;
    _readingMode         = ReadingMode.values[p.getInt('readingMode') ?? 0];
    _keepScreenOn        = p.getBool('keepScreenOn')   ?? true;
    _dayStreak           = p.getInt('dayStreak')       ?? 0;
    _surahsRead          = p.getInt('surahsRead')      ?? 0;
    _versesRead          = p.getInt('versesRead')      ?? 0;
    _lastSurahNumber     = p.getInt('lastSurahNumber') ?? 1;
    _lastSurahName       = p.getString('lastSurahName') ?? 'Al-Fatihah';
    final readSurahsList = p.getStringList('readSurahs') ?? [];
    _readSurahs          = readSurahsList.map(int.parse).toSet();
    notifyListeners();
  }

  // ── Setters ─────────────────────────────────────────────────────
  Future<void> setLanguage(String code) async {
    _langCode = code;
    final p = await SharedPreferences.getInstance();
    await p.setString('langCode', code);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final p = await SharedPreferences.getInstance();
    await p.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setReaderTheme(ReaderTheme theme) async {
    _readerTheme = theme;
    final p = await SharedPreferences.getInstance();
    await p.setInt('readerTheme', theme.index);
    notifyListeners();
  }

  Future<void> setArabicFontSize(double size) async {
    _arabicFontSize = size.clamp(16.0, 40.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('arabicSize', _arabicFontSize);
    notifyListeners();
  }

  Future<void> setTranslitFontSize(double size) async {
    _translitFontSize = size.clamp(10.0, 22.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('translitSize', _translitFontSize);
    notifyListeners();
  }

  Future<void> setTranslationFontSize(double size) async {
    _translationFontSize = size.clamp(10.0, 22.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble('transSize', _translationFontSize);
    notifyListeners();
  }

  Future<void> toggleTranslit() async {
    _showTranslit = !_showTranslit;
    final p = await SharedPreferences.getInstance();
    await p.setBool('showTranslit', _showTranslit);
    notifyListeners();
  }

  Future<void> toggleTranslation() async {
    _showTranslation = !_showTranslation;
    final p = await SharedPreferences.getInstance();
    await p.setBool('showTranslation', _showTranslation);
    notifyListeners();
  }

  Future<void> setReadingMode(ReadingMode mode) async {
    _readingMode = mode;
    final p = await SharedPreferences.getInstance();
    await p.setInt('readingMode', mode.index);
    notifyListeners();
  }

  Future<void> toggleKeepScreenOn() async {
    _keepScreenOn = !_keepScreenOn;
    final p = await SharedPreferences.getInstance();
    await p.setBool('keepScreenOn', _keepScreenOn);
    notifyListeners();
  }

  // ── Stats tracking ──────────────────────────────────────────────
  Future<void> recordAppOpen() async {
    final p = await SharedPreferences.getInstance();
    final lastOpenStr = p.getString('lastOpenDate');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    if (lastOpenStr == null) {
      _dayStreak = 1;
    } else if (lastOpenStr == todayStr) {
      // Already recorded today, no change
      return;
    } else {
      final lastOpen = DateTime.tryParse(lastOpenStr);
      if (lastOpen != null) {
        final diff = today.difference(lastOpen).inDays;
        if (diff == 1) {
          _dayStreak = (_dayStreak + 1);
        } else {
          _dayStreak = 1;
        }
      } else {
        _dayStreak = 1;
      }
    }

    await p.setString('lastOpenDate', todayStr);
    await p.setInt('dayStreak', _dayStreak);
    notifyListeners();
  }

  Future<void> recordSurahOpened(int surahNumber, String surahName) async {
    _lastSurahNumber = surahNumber;
    _lastSurahName = surahName;
    if (!_readSurahs.contains(surahNumber)) {
      _readSurahs.add(surahNumber);
      _surahsRead = _readSurahs.length;
    }
    final p = await SharedPreferences.getInstance();
    await p.setInt('lastSurahNumber', surahNumber);
    await p.setString('lastSurahName', surahName);
    await p.setStringList('readSurahs', _readSurahs.map((n) => n.toString()).toList());
    await p.setInt('surahsRead', _surahsRead);
    notifyListeners();
  }

  Future<void> recordVerseRead() async {
    _versesRead++;
    final p = await SharedPreferences.getInstance();
    await p.setInt('versesRead', _versesRead);
    notifyListeners();
  }
}
