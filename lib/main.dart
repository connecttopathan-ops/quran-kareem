import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'models/app_state.dart';
import 'services/location_service.dart';
import 'services/audio_service.dart';
import 'services/quran_service.dart';
import 'services/translation_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/duas_screen.dart';
import 'screens/prayer_notification_settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'co.getquran.app.audio',
      androidNotificationChannelName: 'Quran Recitation',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground error: $e');
  }
  await NotificationService().init();
  await AndroidAlarmManager.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => AudioService()),
        ChangeNotifierProvider(create: (_) => QuranService()),
        ChangeNotifierProvider(create: (_) => TranslationService()),
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
            },
          );
        },
      ),
    );
  }
}
