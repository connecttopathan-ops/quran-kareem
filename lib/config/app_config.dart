// No secrets here — this file is safe for public repos.
// All values below are public, unauthenticated API endpoints.
// If you ever add keys that require authentication, inject them via
// environment variables (--dart-define) and DO NOT commit them.

class AppConfig {
  AppConfig._();

  // Quran text & translation APIs (public, no auth required)
  static const String alquranCloudBaseUrl = 'https://api.alquran.cloud/v1';
  static const String quranCdnBaseUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1';

  // Audio CDN base (public, no auth required) — append /{bitrate}/{edition}/{verse}.mp3
  static const String audioCdnBaseUrl =
      'https://cdn.islamic.network/quran/audio';

  // Geocoding (public, no auth required — respect usage policy)
  static const String nominatimBaseUrl =
      'https://nominatim.openstreetmap.org';

  // App website
  static const String appWebsiteUrl = 'https://getquran.co';
}
