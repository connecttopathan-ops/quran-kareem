import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/language.dart';

// Reading themes
enum ReaderTheme { warm, paper, dark }

// Reading modes
enum ReadingMode { list, page, focus }

class AppState extends ChangeNotifier {
  // \u2500\u2500 Language \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  String _langCode = 'en';

  // \u2500\u2500 Display \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  bool _isDarkMode = false;        // app-level dark mode
  ReaderTheme _readerTheme = ReaderTheme.warm; // reader-specific theme

  // \u2500\u2500 Text sizes \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  double _arabicFontSize   = 24.0; // range 16\u201340
  double _translitFontSize = 13.0; // range 10\u201322
  double _translationFontSize = 14.0; // range 10\u201322

  // \u2500\u2500 Visibility toggles \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  bool _showTranslit    = true;
  bool _showTranslation = true;

  // \u2500\u2500 Reading \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  ReadingMode _readingMode = ReadingMode.list;
  bool _keepScreenOn = true;

  // \u2500\u2500 Getters \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
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
    notifyListeners();
  }

  // \u2500\u2500 Setters \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
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
}
