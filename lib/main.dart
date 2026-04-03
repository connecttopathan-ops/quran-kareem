import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'models/app_state.dart';
import 'services/location_service.dart';
import 'services/audio_service.dart';
import 'services/audio_handler.dart';
import 'services/quran_service.dart';
import 'services/translation_service.dart';
import 'services/notification_service.dart';
import 'services/book_download_service.dart';
import 'services/audio_download_service.dart';
import 'screens/home_screen.dart';
import 'screens/duas_screen.dart';
import 'screens/prayer_notification_settings_screen.dart';
import 'screens/islamic_books_screen.dart';
import 'screens/daily_reminders_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService().init();
  } catch (_) {}
  await AudioDownloadService().init();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await AndroidAlarmManager.initialize();
  }
  // JustAudioBackground registers the app as a media player with iOS
  // (needed for Control Center / lock screen Now Playing widget to appear).
  // Our native NowPlayingPlugin re-registers MPRemoteCommandCenter handlers
  // on every setNowPlaying call so they always override just_audio_background's.
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'co.getquran.app.audio',
      androidNotificationChannelName: 'Quran Audio',
      preloadArtwork: true,
    );
    print('[QuranAudio] JustAudioBackground.init succeeded');
  } catch (e) {
    print('[QuranAudio] JustAudioBackground.init FAILED: $e');
  }
  // just_audio_background manages the audio session and lock screen widget;
  // no AudioService.init needed — create the handler directly.
  final handler = QuranAudioHandler();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(QuranApp(handler: handler));
}

class QuranApp extends StatelessWidget {
  final QuranAudioHandler handler;
  const QuranApp({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => AudioService(handler)),
        ChangeNotifierProvider(create: (_) => QuranService()),
        ChangeNotifierProvider(create: (_) => TranslationService()),
        ChangeNotifierProvider(create: (_) => BookDownloadService()),
        ChangeNotifierProvider(create: (_) => AudioDownloadService()),
      ],
      child: Consumer<AppState>(
        builder: (context, state, _) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarIconBrightness:
                state.isDarkMode ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                state.isDarkMode ? Brightness.dark : Brightness.light,
          ));
          return MaterialApp(
            title: 'Get Quran',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            home: const HomeScreen(),
            routes: {
              '/duas': (context) => const DuasScreen(),
              '/prayer-notifications': (context) =>
                  const PrayerNotificationSettingsScreen(),
              '/islamic-books': (context) => const IslamicBooksScreen(),
              '/daily-reminders': (context) => const DailyRemindersScreen(),
            },
          );
        },
      ),
    );
  }
}
