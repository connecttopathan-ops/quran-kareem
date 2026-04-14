import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Quran reading ──────────────────────────────────────────────────────────

  static Future<void> logSurahOpened(int surahNumber, String surahName) =>
      _analytics.logEvent(
        name: 'surah_opened',
        parameters: {'surah_number': surahNumber, 'surah_name': surahName},
      );

  static Future<void> logBookmarkAdded(
          int surahNumber, int verseNumber) =>
      _analytics.logEvent(
        name: 'bookmark_added',
        parameters: {
          'surah_number': surahNumber,
          'verse_number': verseNumber,
        },
      );

  // ── Audio ──────────────────────────────────────────────────────────────────

  static Future<void> logAudioPlayed(int surahNumber, String surahName) =>
      _analytics.logEvent(
        name: 'audio_played',
        parameters: {'surah_number': surahNumber, 'surah_name': surahName},
      );

  // ── Settings / preferences ─────────────────────────────────────────────────

  static Future<void> logLanguageChanged(String langCode) =>
      _analytics.logEvent(
        name: 'language_changed',
        parameters: {'lang_code': langCode},
      );

  static Future<void> logThemeChanged(bool isDark) =>
      _analytics.logEvent(
        name: 'theme_changed',
        parameters: {'theme': isDark ? 'dark' : 'light'},
      );

  // ── Features ───────────────────────────────────────────────────────────────

  static Future<void> logAsmaOpened() =>
      _analytics.logEvent(name: 'asma_ul_husna_opened');

  static Future<void> logBookOpened(String bookName) =>
      _analytics.logEvent(
        name: 'book_opened',
        parameters: {'book_name': bookName},
      );

  static Future<void> logPrayerNotificationTapped(String prayerName) =>
      _analytics.logEvent(
        name: 'prayer_notification_tapped',
        parameters: {'prayer_name': prayerName},
      );

  static Future<void> logDuasOpened() =>
      _analytics.logEvent(name: 'duas_opened');

  static Future<void> logHifzOpened() =>
      _analytics.logEvent(name: 'hifz_opened');
}
