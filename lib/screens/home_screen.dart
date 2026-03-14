import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../widgets/q_icons.dart';
import '../data/quran_data.dart';
import 'surah_list_screen.dart';
import 'settings_screen.dart';
import 'reader_screen.dart';
import 'language_selection_screen.dart';
import 'qibla_screen.dart';
import 'sponsor_screen.dart';
import 'duas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _clockTimer;
  LocationService? _locationService;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    // Record app open for streak tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().recordAppOpen();
        _checkFirstLaunchLocation();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ls = context.read<LocationService>();
    if (_locationService != ls) {
      _locationService?.removeListener(_onPrayerTimesUpdated);
      _locationService = ls;
      _locationService!.addListener(_onPrayerTimesUpdated);
    }
  }

  void _onPrayerTimesUpdated() {
    final pt = _locationService?.prayerTimes;
    if (pt != null) _scheduleNotifications(pt);
  }

  Future<void> _scheduleNotifications(PrayerTimes pt) async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('prayer_notification_mode') ?? 'off';
    final adhanStr = prefs.getString('adhan_type') ?? 'makkah';
    final mode = PrayerNotificationMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => PrayerNotificationMode.off,
    );
    final adhanType = AdhanType.values.firstWhere(
      (e) => e.name == adhanStr,
      orElse: () => AdhanType.makkah,
    );
    final times = {
      'Fajr': pt.fajrStr,
      'Dhuhr': pt.dhuhrStr,
      'Asr': pt.asrStr,
      'Maghrib': pt.maghribStr,
      'Isha': pt.ishaStr,
    };
    await NotificationService()
        .scheduleAllPrayers(times, mode, adhanType: adhanType);
  }

  Future<void> _checkFirstLaunchLocation() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Location permission (first launch)
    final locationAsked = prefs.getBool('locationPermissionAsked') ?? false;
    if (!locationAsked && mounted) {
      await prefs.setBool('locationPermissionAsked', true);
      await _showLocationPermissionDialog();
    }

    // 2. Language selection screen (first launch, after location)
    final langSelected = prefs.getBool('language_selected') ?? false;
    if (!langSelected && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const LanguageSelectionScreen(),
            fullscreenDialog: true),
      );
    }
  }

  Future<void> _showLocationPermissionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Prayer Times', style: TextStyle(color: context.text, fontFamily: 'serif')),
        content: Text(
          'Allow Get Quran to access your location to automatically calculate accurate prayer times for your area.',
          style: TextStyle(color: context.textDim, fontSize: 13, fontFamily: 'sans-serif'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Skip', style: TextStyle(color: context.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LocationService>().fetchLocation();
            },
            child: const Text('Allow Location'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationService?.removeListener(_onPrayerTimesUpdated);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final screens = [
          const _HomeTab(),
          const SurahListScreen(),
          const SettingsScreen(),
        ];
        return Scaffold(
          backgroundColor: context.bg,
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniAudioPlayer(),
              Container(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: context.border))),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  backgroundColor: context.bg,
                  selectedItemColor: AppColors.gold,
                  unselectedItemColor: context.textDim,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  items: [
                    BottomNavigationBarItem(icon: QIcon.home(size: 24), label: 'Home'),
                    BottomNavigationBarItem(icon: QIcon.book(size: 24), label: 'Quran'),
                    BottomNavigationBarItem(icon: QIcon.settings(size: 24), label: 'Settings'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
// MINI AUDIO PLAYER (above bottom nav everywhere)
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audio, _) {
        final np = audio.nowPlaying;
        if (np == null) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(
              top: BorderSide(color: context.border),
              bottom: BorderSide(color: context.border),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              // Surah/verse info
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: AppColors.goldDim.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldDim.withOpacity(0.4)),
                ),
                child: Center(
                  child: audio.isLoading
                      ? SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: AppColors.gold))
                      : Text('${np.verseNumber}',
                          style: TextStyle(fontFamily: 'Playfair Display',
                              fontSize: 12, color: AppColors.gold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(np.surahName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                            color: context.text)),
                    Text('${audio.reciter.name} \u00b7 Verse ${np.verseNumber}/${np.totalVerses}',
                        style: TextStyle(fontSize: 9, fontFamily: 'sans-serif',
                            color: context.textDim)),
                  ],
                ),
              ),
              // Controls
              _MiniBtn(
                icon: QIcon.previousVerse(size: 15, color: context.textDim),
                onTap: audio.previousVerse,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: audio.togglePlayPause,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: audio.isPlaying
                        ? QIcon.pause(size: 14, color: Colors.white)
                        : QIcon.play(size: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MiniBtn(
                icon: QIcon.nextVerse(size: 15, color: context.textDim),
                onTap: audio.nextVerse,
              ),
              const SizedBox(width: 6),
              _MiniBtn(
                icon: QIcon.close(size: 14, color: context.textDim),
                onTap: audio.stop,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _MiniBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 28, height: 28,
          child: Center(child: icon)),
    );
  }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
// HOME TAB
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = now.hour;
    final greeting = h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.border))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting.toUpperCase(),
                            style: TextStyle(fontSize: 9, letterSpacing: 2,
                                color: context.textDim, fontFamily: 'sans-serif')),
                        const SizedBox(height: 2),
                        RichText(text: TextSpan(
                          style: TextStyle(fontFamily: 'serif', fontSize: 18,
                              color: context.text),
                          children: [
                            const TextSpan(text: 'Assalamu '),
                            TextSpan(text: 'Alaikum',
                                style: TextStyle(color: AppColors.gold)),
                          ],
                        )),
                        const SizedBox(height: 2),
                        Text('\u0627\u0644\u0633\u064e\u0651\u0644\u064e\u0627\u0645\u064f \u0639\u064e\u0644\u064e\u064a\u0652\u0643\u064f\u0645\u0652',
                            style: TextStyle(fontFamily: 'Scheherazade', fontSize: 14,
                                color: context.isDark ? AppColors.gold : AppColors.goldDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 24),
                children: [
                  const _CalPrayerCard(),
                  const SizedBox(height: 12),
                  const _QuickActionsCard(),
                  const SizedBox(height: 12),
                  const _ContinueCard(),
                  const SizedBox(height: 12),
                  const _DailyAyah(),
                  const SizedBox(height: 12),
                  const _PopularSurahs(),
                  const SizedBox(height: 12),
                  const _Stats(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
// CALENDAR + PRAYER CARD
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _CalPrayerCard extends StatelessWidget {
  const _CalPrayerCard();

  Map<String, int> _toHijri(DateTime date) {
    int y = date.year;
    int m = date.month;
    int d = date.day;

    int jd = (1461 * (y + 4800 + (m - 14) ~/ 12)) ~/ 4 +
        (367 * (m - 2 - 12 * ((m - 14) ~/ 12))) ~/ 12 -
        (3 * ((y + 4900 + (m - 14) ~/ 12) ~/ 100)) ~/ 4 +
        d - 32075;

    int l = jd - 1948440 + 10632;
    int n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    int j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    int hYear = 30 * n + j - 30;
    int hMonth = (24 * l) ~/ 709;
    int hDay = l - (709 * hMonth) ~/ 24;

    return {'day': hDay, 'month': hMonth, 'year': hYear};
  }

  @override
  Widget build(BuildContext context) {
    const hMonths = ['Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
        "Jumada al-Awwal", "Jumada al-Thani", 'Rajab', "Sha'ban",
        'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah'];
    const hMonthsAr = ['\u0645\u064f\u062d\u064e\u0631\u064e\u0651\u0645', '\u0635\u064e\u0641\u064e\u0631', '\u0631\u064e\u0628\u0650\u064a\u0639\u064f \u0627\u0644\u0623\u064e\u0648\u064e\u0651\u0644', '\u0631\u064e\u0628\u0650\u064a\u0639\u064f \u0627\u0644\u062b\u064e\u0651\u0627\u0646\u0650\u064a',
        '\u062c\u064f\u0645\u064e\u0627\u062f\u064e\u0649 \u0627\u0644\u0623\u064f\u0648\u0644\u064e\u0649', '\u062c\u064f\u0645\u064e\u0627\u062f\u064e\u0649 \u0627\u0644\u062b\u064e\u0651\u0627\u0646\u0650\u064a\u064e\u0629', '\u0631\u064e\u062c\u064e\u0628', '\u0634\u064e\u0639\u0652\u0628\u064e\u0627\u0646',
        '\u0631\u064e\u0645\u064e\u0636\u064e\u0627\u0646', '\u0634\u064e\u0648\u064e\u0651\u0627\u0644', '\u0630\u064f\u0648 \u0627\u0644\u0652\u0642\u064e\u0639\u0652\u062f\u064e\u0629', '\u0630\u064f\u0648 \u0627\u0644\u0652\u062d\u0650\u062c\u064e\u0651\u0629'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const wdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    String toAI(int n) {
      const d = ['\u0660','\u0661','\u0662','\u0663','\u0664','\u0665','\u0666','\u0667','\u0668','\u0669'];
      return n.toString().split('').map((c) => d[int.parse(c)]).join();
    }

    return Consumer<LocationService>(
      builder: (context, loc, _) {
        // Always use device local time — the device timezone is more accurate
        // than a longitude-based approximation.
        final now = DateTime.now();
        final h = _toHijri(now);

        return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: context.isDark ? const Color(0xFF3a2e10) : const Color(0xFFceb060)),
      ),
      child: Column(
        children: [
          // Calendar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDark
                    ? [const Color(0xFF1c1608), const Color(0xFF130f04)]
                    : [const Color(0xFFf5e8c4), const Color(0xFFedd99e)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Islamic Date'.toUpperCase(),
                      style: TextStyle(fontSize: 7, letterSpacing: 2, fontFamily: 'sans-serif',
                          color: context.isDark ? AppColors.goldDim : AppColors.goldDark)),
                  const SizedBox(height: 1),
                  Text('${h['day']}',
                      style: TextStyle(fontFamily: 'serif', fontSize: 32, height: 1,
                          color: context.isDark ? AppColors.warmWhite : const Color(0xFF2a1e08))),
                  Text(hMonths[h['month']! - 1],
                      style: TextStyle(fontFamily: 'serif', fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: context.isDark ? AppColors.gold : AppColors.goldDark)),
                  Text('${h['year']} AH',
                      style: TextStyle(fontSize: 11, fontFamily: 'sans-serif',
                          color: context.isDark ? AppColors.goldDim : const Color(0xFF9a7030))),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(toAI(h['day']!),
                      style: TextStyle(fontFamily: 'Scheherazade', fontSize: 30, height: 1,
                          color: context.isDark ? AppColors.gold : AppColors.goldDark)),
                  Text(hMonthsAr[h['month']! - 1],
                      style: TextStyle(fontFamily: 'Scheherazade', fontSize: 15,
                          color: context.isDark ? AppColors.goldDim : const Color(0xFF9a7030))),
                  Text('${wdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                      style: TextStyle(fontSize: 11, fontFamily: 'sans-serif',
                          color: context.isDark ? const Color(0xFF5a5040) : const Color(0xFF9a7030))),
                ]),
              ],
            ),
          ),
          Container(height: 1,
              color: context.isDark ? const Color(0xFF3a2e10) : const Color(0xFFceb060).withOpacity(0.4)),
          // Prayer times
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF0c0902) : Colors.white.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
            child: const _PrayerSection(),
          ),
        ],
      ),
      );
    },
  );
  }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
// PRAYER SECTION
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _PrayerSection extends StatelessWidget {
  const _PrayerSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (ctx, loc, _) {
        final pt = loc.prayerTimes;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Prayer Times'.toUpperCase(),
                    style: TextStyle(fontSize: 7, letterSpacing: 2,
                        color: context.isDark ? AppColors.goldDim : AppColors.goldDark,
                        fontFamily: 'sans-serif')),
                const Spacer(),
                // Location chip
                GestureDetector(
                  onTap: () => _showLocationSheet(context, loc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldDim.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QIcon.locationPin(size: 10,
                            color: context.isDark ? AppColors.gold : AppColors.goldDark),
                        const SizedBox(width: 4),
                        Text(
                          loc.loading ? 'Locating...'
                              : pt != null && pt.cityName.isNotEmpty
                                  ? (pt.cityName.length > 20
                                      ? '${pt.cityName.substring(0, 18)}\u2026'
                                      : pt.cityName)
                                  : 'Set Location',
                          style: TextStyle(fontSize: 9, fontFamily: 'sans-serif',
                              color: context.isDark ? AppColors.gold : AppColors.goldDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            if (loc.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.gold)),
                    const SizedBox(width: 9),
                    Text('Fetching location...',
                        style: TextStyle(fontSize: 11, color: context.textDim,
                            fontFamily: 'sans-serif')),
                  ],
                ),
              )
            else if (pt == null)
              GestureDetector(
                onTap: () => _showLocationSheet(context, loc),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: context.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border)),
                  child: Row(
                    children: [
                      QIcon.locationPin(size: 13, color: context.textDim),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                          loc.error ?? 'Tap to set location for prayer times',
                          style: TextStyle(fontSize: 11, color: context.textDim,
                              fontFamily: 'sans-serif'))),
                      Text('Set', style: TextStyle(fontSize: 11, color: AppColors.gold,
                          fontFamily: 'sans-serif')),
                    ],
                  ),
                ),
              )
            else
              _PrayerGrid(pt: pt),
          ],
        );
      },
    );
  }

  void _showLocationSheet(BuildContext ctx, LocationService loc) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
          value: loc, child: const _LocationSheet()),
    );
  }
}

// Rakah breakdown data
const _kRakahRows = {
  'Fajr':    [('Sunnah', 2), ('Fard', 2)],
  'Dhuhr':   [('Sunnah', 4), ('Fard', 4), ('Sunnah', 2)],
  'Asr':     [('Sunnah', 4), ('Fard', 4)],
  'Maghrib': [('Fard', 3), ('Sunnah', 2)],
  'Isha':    [('Sunnah', 4), ('Fard', 4), ('Sunnah', 2), ('Witr', 3)],
};
const _kRakahTotal = {
  'Fajr': 4, 'Dhuhr': 10, 'Asr': 8, 'Maghrib': 5, 'Isha': 13,
};

class _PrayerGrid extends StatefulWidget {
  final PrayerTimes pt;
  const _PrayerGrid({required this.pt});

  @override
  State<_PrayerGrid> createState() => _PrayerGridState();
}

class _PrayerGridState extends State<_PrayerGrid>
    with SingleTickerProviderStateMixin {
  int? _tappedIndex;
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;
  Timer? _countdownTimer;
  late DateTime _targetTime;

  @override
  void initState() {
    super.initState();
    _targetTime = DateTime.now().add(widget.pt.timeUntilNext);

    _blinkCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _blinkAnim = Tween<double>(begin: 1.0, end: 0.15).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
    _blinkCtrl.repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(_PrayerGrid old) {
    super.didUpdateWidget(old);
    if (old.pt != widget.pt) {
      _targetTime = DateTime.now().add(widget.pt.timeUntilNext);
    }
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getCurrentPrayer(Map<String, String> times) {
    final now = TimeOfDay.now();
    const prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    String current = 'Isha';
    for (int i = 0; i < prayers.length; i++) {
      final t = _parseTime(times[prayers[i]]!);
      if (_timeToMinutes(now) >= _timeToMinutes(t)) {
        current = prayers[i];
      }
    }
    return current;
  }

  TimeOfDay _parseTime(String timeStr) {
    final cleaned = timeStr.trim();
    final upper = cleaned.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) {
      final parts = cleaned.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final isPm = parts[1].toUpperCase() == 'PM';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } else {
      final parts = cleaned.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Widget _buildPopup(BuildContext context, String prayerName) {
    final rows = _kRakahRows[prayerName] ?? [];
    final total = _kRakahTotal[prayerName] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(prayerName.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: AppColors.gold,
                  fontFamily: 'sans-serif',
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1,
                        style: TextStyle(
                            fontSize: 11,
                            color: context.textDim,
                            fontFamily: 'sans-serif')),
                    Text('${r.$2}',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.text,
                            fontFamily: 'sans-serif')),
                  ],
                ),
              )),
          Divider(height: 14, color: context.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gold,
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.w700)),
              Text('$total',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gold,
                      fontFamily: 'sans-serif',
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayers = [
      ('Fajr',    widget.pt.fajrStr,    4),
      ('Dhuhr',   widget.pt.dhuhrStr,   10),
      ('Asr',     widget.pt.asrStr,     8),
      ('Maghrib', widget.pt.maghribStr, 5),
      ('Isha',    widget.pt.ishaStr,    13),
    ];
    final next = widget.pt.nextPrayerName;
    final currentPrayer = _getCurrentPrayer({
      'Fajr': widget.pt.fajrStr,
      'Dhuhr': widget.pt.dhuhrStr,
      'Asr': widget.pt.asrStr,
      'Maghrib': widget.pt.maghribStr,
      'Isha': widget.pt.ishaStr,
    });

    final rem = _targetTime.difference(DateTime.now());
    final remClamped = rem.isNegative ? Duration.zero : rem;
    final h = remClamped.inHours;
    final m = remClamped.inMinutes % 60;
    final s = remClamped.inSeconds % 60;
    final countdown = '${h}h ${m}m ${s}s';

    return GestureDetector(
      onTap: () {
        if (_tappedIndex != null) setState(() => _tappedIndex = null);
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          // Popup shown above prayer row
          if (_tappedIndex != null) ...[
            _buildPopup(context, prayers[_tappedIndex!].$1),
            const SizedBox(height: 6),
          ],
          // Prayer cards row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(5, (i) {
                final p = prayers[i];
                final isCurrent = p.$1 == currentPrayer;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _tappedIndex = _tappedIndex == i ? null : i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: AppColors.gold, width: 2)
                            : Border.all(color: context.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.$1,
                              style: TextStyle(
                                  fontSize: 7,
                                  fontFamily: 'sans-serif',
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isCurrent
                                      ? AppColors.gold
                                      : context.textDim)),
                          const SizedBox(height: 3),
                          Text(
                              p.$2
                                  .replaceAll(' AM', '')
                                  .replaceAll(' PM', ''),
                              style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent
                                      ? AppColors.gold
                                      : context.text)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.gold.withOpacity(0.15)
                                  : context.textDim.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${p.$3} rak.',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'sans-serif',
                                    color: isCurrent
                                        ? AppColors.gold
                                        : context.textDim)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          // Hint text
          Text(
            '✦ Tap a prayer to see full rakah breakdown ✦',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9,
                fontFamily: 'sans-serif',
                color: context.textDim.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          // Next prayer row with blinking dot
          Row(children: [
            FadeTransition(
              opacity: _blinkAnim,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.gold),
              ),
            ),
            const SizedBox(width: 6),
            Text('Next: ',
                style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'sans-serif',
                    color: context.textDim)),
            Text(next,
                style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'sans-serif',
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700)),
            Text(' in $countdown',
                style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'sans-serif',
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
// LOCATION SHEET
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _LocationSheet extends StatefulWidget {
  const _LocationSheet();
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _ctrl = TextEditingController();
  List<Location> _results = [];
  bool _searching = false;
  String? _searchErr;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() { _searching = true; _searchErr = null; });
    try {
      _results = await locationFromAddress(q);
      setState(() { _searching = false; });
    } catch (_) {
      setState(() { _searchErr = 'City not found. Try a different spelling.'; _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationService>();
    final pt = loc.prayerTimes;

    return Container(
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: context.border)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 3,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(color: context.border,
                    borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
              child: Row(
                children: [
                  Text('Prayer Times Location',
                      style: TextStyle(fontFamily: 'serif', fontSize: 17, color: context.text)),
                  const Spacer(),
                  IconButton(
                    icon: QIcon.close(size: 16, color: context.textDim),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Current location display
            if (pt != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldDim.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.goldDim.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      QIcon.locationPin(size: 14, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(pt.cityName,
                              style: TextStyle(fontSize: 13, color: context.text)),
                          Text('${pt.lat.toStringAsFixed(3)}, ${pt.lng.toStringAsFixed(3)}',
                              style: TextStyle(fontSize: 9, fontFamily: 'sans-serif', color: context.textDim)),
                        ]),
                      ),
                      TextButton(
                        onPressed: () { Navigator.pop(context); loc.fetchLocation(); },
                        child: Text('Re-detect',
                            style: TextStyle(fontSize: 11, color: AppColors.gold)),
                      ),
                    ],
                  ),
                ),
              ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: context.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search city or country...',
                  hintStyle: TextStyle(color: context.textDim),
                  prefixIcon: Padding(padding: const EdgeInsets.all(11),
                      child: QIcon.search(size: 17, color: context.textDim)),
                  suffixIcon: _searching
                      ? Padding(padding: const EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.gold)))
                      : null,
                  filled: true, fillColor: context.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.gold)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: _search,
                textInputAction: TextInputAction.search,
              ),
            ),
            if (_searchErr != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(_searchErr!, style: TextStyle(fontSize: 11,
                    color: Colors.red.shade400, fontFamily: 'sans-serif')),
              ),
            if (_results.isNotEmpty)
              ...List.generate(_results.length, (i) {
                final r = _results[i];
                return ListTile(
                  dense: true,
                  leading: QIcon.locationPin(size: 14, color: context.textDim),
                  title: Text(_ctrl.text,
                      style: TextStyle(fontSize: 13, color: context.text)),
                  subtitle: Text(
                      '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 10, color: context.textDim, fontFamily: 'sans-serif')),
                  onTap: () async {
                    Navigator.pop(context);
                    await loc.setManualLocation(r.latitude, r.longitude, _ctrl.text.trim());
                  },
                );
              }),
            // Calc method
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calculation Method'.toUpperCase(),
                      style: TextStyle(fontSize: 8, letterSpacing: 2, color: context.textDim,
                          fontFamily: 'sans-serif')),
                  const SizedBox(height: 8),
                  ...CalcMethod.all.map((m) {
                    final sel = loc.calcMethodId == m.id;
                    return GestureDetector(
                      onTap: () => loc.setCalcMethod(m.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.goldDim.withOpacity(0.1) : context.surface2,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: sel ? AppColors.gold : context.border,
                              width: sel ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(m.name,
                                style: TextStyle(fontSize: 12,
                                    color: sel ? AppColors.gold : context.text))),
                            if (sel) QIcon.check(size: 14, color: AppColors.gold),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
// CONTINUE READING
// \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
class _ContinueCard extends StatelessWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final surahNumber = state.lastSurahNumber;
      final surahName = state.lastSurahName;
      final surah = kSurahs.firstWhere(
        (s) => s.number == surahNumber,
        orElse: () => kSurahs.first,
      );
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Continue Reading'.toUpperCase(),
            style: TextStyle(fontSize: 8, letterSpacing: 2.5,
                color: context.textDim, fontFamily: 'sans-serif')),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ReaderScreen(surah: surah),
          )),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(color: context.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border)),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.goldDim.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: context.border)),
                child: Center(child: QIcon.book(size: 16, color: AppColors.gold))),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(surahName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.text)),
                Text('Surah ${surah.number} · ${surah.verses} verses',
                    style: TextStyle(fontSize: 10, color: context.textDim, fontFamily: 'sans-serif')),
              ])),
              Icon(Icons.chevron_right, size: 18, color: context.textDim),
            ]),
          ),
        ),
      ]);
    });
  }
}
class _DailyAyah extends StatelessWidget {
  const _DailyAyah();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: context.isDark
            ? [const Color(0xFF0e0b04), const Color(0xFF1a1508)]
            : [const Color(0xFFf5e8cc), const Color(0xFFefdba8)]),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.isDark
            ? const Color(0xFF3a2e10) : const Color(0xFFd4b870)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('✦  Ayah of the Day  ✦'.toUpperCase(),
            style: TextStyle(fontSize: 7, letterSpacing: 2,
                color: context.isDark ? AppColors.goldDim : AppColors.goldDark,
                fontFamily: 'sans-serif')),
        const SizedBox(height: 8),
        Text('وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Scheherazade', fontSize: 18, height: 2,
                color: context.isDark ? AppColors.goldLight : const Color(0xFF2a1e08))),
        Divider(color: AppColors.goldDim.withOpacity(0.25)),
        Text("Wa man yatawakkal 'alal-laahi fahuwa hasbuh",
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                color: context.isDark ? const Color(0xFF888888) : const Color(0xFF806840))),
        const SizedBox(height: 6),
        // English translation
        Text(
          '"And whoever relies upon Allah — then He is sufficient for him."',
          style: TextStyle(fontSize: 12, fontFamily: 'sans-serif',
              color: context.isDark ? const Color(0xFFb0a080) : const Color(0xFF5a4020)),
        ),
        const SizedBox(height: 4),
        // Urdu translation
        Text(
          'اور جو شخص اللہ پر بھروسہ کرے، وہ اس کے لیے کافی ہے۔',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Scheherazade', fontSize: 14, height: 1.8,
              color: context.isDark ? const Color(0xFF908070) : const Color(0xFF4A3A20)),
        ),
        const SizedBox(height: 6),
        Text('Surah At-Talaq · 65:3',
            style: TextStyle(fontSize: 9, fontFamily: 'sans-serif',
                color: context.isDark ? AppColors.goldDim : AppColors.goldDark)),
      ]),
    );
  }
}
class _PopularSurahs extends StatelessWidget {
  const _PopularSurahs();

  @override
  Widget build(BuildContext context) {
    final surahs = [1, 36, 55, 67]
        .map((n) => kSurahs.firstWhere((s) => s.number == n))
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Popular Surahs'.toUpperCase(),
          style: TextStyle(fontSize: 8, letterSpacing: 2.5,
              color: context.textDim, fontFamily: 'sans-serif')),
      const SizedBox(height: 6),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
        children: surahs.map((s) => GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ReaderScreen(surah: s),
          )),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(color: context.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.border)),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Surah ${s.number}',
                      style: TextStyle(fontSize: 7, fontFamily: 'sans-serif', color: context.textDim)),
                  Text(s.nameTransliteration,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.text)),
                  Text('${s.verses} verses',
                      style: TextStyle(fontSize: 8, fontFamily: 'sans-serif', color: context.textDim)),
                ],
              )),
              Text(s.nameArabic,
                  style: TextStyle(fontFamily: 'Scheherazade', fontSize: 16,
                      color: context.isDark ? AppColors.gold : AppColors.goldDark)),
            ]),
          ),
        )).toList(),
      ),
    ]);
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icon(Icons.explore_outlined, size: 26, color: AppColors.gold),
        label: 'Qibla',
        subtitle: 'Find direction',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
      ),
      (
        icon: Icon(Icons.menu_book_outlined, size: 26, color: AppColors.gold),
        label: 'Duas',
        subtitle: 'Daily supplications',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DuasScreen())),
      ),
      (
        icon: Icon(Icons.volunteer_activism, size: 26, color: AppColors.gold),
        label: 'Sponsor Quran',
        subtitle: 'Free Quran distribution',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SponsorScreen())),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions.map((a) {
            return Expanded(
              child: GestureDetector(
                onTap: a.onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      a.icon,
                      const SizedBox(height: 4),
                      Text(a.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.text),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      Text(a.subtitle,
                          style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'sans-serif',
                              color: context.textDim),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your Progress'.toUpperCase(),
            style: TextStyle(fontSize: 8, letterSpacing: 2.5,
                color: context.textDim, fontFamily: 'sans-serif')),
        const SizedBox(height: 6),
        Row(children: [
          _Stat(context, '${state.dayStreak}', 'Day Streak'),
          const SizedBox(width: 7),
          _Stat(context, '${state.surahsRead}', 'Surahs'),
          const SizedBox(width: 7),
          _Stat(context, '${state.versesRead}', 'Verses'),
        ]),
      ]);
    });
  }

  Widget _Stat(BuildContext ctx, String v, String l) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: ctx.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ctx.border)),
      child: Column(children: [
        Text(v, style: TextStyle(fontFamily: 'serif', fontSize: 18,
            color: ctx.isDark ? AppColors.gold : AppColors.goldDark)),
        Text(l, style: TextStyle(fontSize: 8, fontFamily: 'sans-serif', color: ctx.textDim)),
      ]),
    ),
  );
}
