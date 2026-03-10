import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../widgets/q_icons.dart';
import '../data/quran_data.dart';
import 'surah_list_screen.dart';
import 'settings_screen.dart';
import 'reader_screen.dart';
import 'language_selection_screen.dart';
import 'qibla_screen.dart';
import 'sponsor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _clockTimer;

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
                  // Qibla compass button
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const QiblaScreen())),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.goldDim.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border),
                      ),
                      child: Center(child: Icon(Icons.explore_outlined,
                          size: 18, color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sponsor button
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SponsorScreen())),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.goldDim.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.border),
                      ),
                      child: Center(child: Icon(Icons.favorite_outline,
                          size: 18, color: AppColors.gold)),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 24),
                children: const [
                  _CalPrayerCard(),
                  SizedBox(height: 12),
                  _ContinueCard(),
                  SizedBox(height: 12),
                  _DailyAyah(),
                  SizedBox(height: 12),
                  _PopularSurahs(),
                  SizedBox(height: 12),
                  _Stats(),
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

  Map<String, int> _toHijri(DateTime d) {
    int jd = _gToJ(d.year, d.month, d.day);
    jd = jd - 1948440 + 10632;
    int n = ((jd - 1) / 10631).floor();
    jd = jd - 10631 * n + 354;
    int j = ((10985 - jd) / 5316).floor() * ((50 * jd) / 17719).floor() +
        (jd / 5670).floor() * ((43 * jd) / 15238).floor();
    jd = jd - ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() + 29;
    int month = (24 * jd / 709).floor();
    int day = jd - (709 * month / 24).floor();
    return {'y': 30 * n + j - 30, 'm': month, 'd': day};
  }

  int _gToJ(int y, int m, int d) {
    if (m <= 2) { y--; m += 12; }
    return d + ((153 * m - 457) / 5).floor() + 365 * y +
        (y / 4).floor() - (y / 100).floor() + (y / 400).floor() + 1721119;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toLocal();
    final h = _toHijri(now);
    const hMonths = ['','Muharram','Safar',"Rabi' Al-Awwal","Rabi' Al-Thani",
        "Jumada Al-Awwal","Jumada Al-Thani",'Rajab',"Sha'ban",
        'Ramadan','Shawwal',"Dhul-Qi'dah",'Dhul-Hijjah'];
    const hMonthsAr = ['','\u0645\u064f\u062d\u064e\u0631\u064e\u0651\u0645','\u0635\u064e\u0641\u064e\u0631','\u0631\u064e\u0628\u0650\u064a\u0639\u064f \u0627\u0644\u0623\u064e\u0648\u064e\u0651\u0644','\u0631\u064e\u0628\u0650\u064a\u0639\u064f \u0627\u0644\u062b\u064e\u0651\u0627\u0646\u0650\u064a',
        '\u062c\u064f\u0645\u064e\u0627\u062f\u064e\u0649 \u0627\u0644\u0623\u064f\u0648\u0644\u064e\u0649','\u062c\u064f\u0645\u064e\u0627\u062f\u064e\u0649 \u0627\u0644\u062b\u064e\u0651\u0627\u0646\u0650\u064a\u064e\u0629','\u0631\u064e\u062c\u064e\u0628','\u0634\u064e\u0639\u0652\u0628\u064e\u0627\u0646',
        '\u0631\u064e\u0645\u064e\u0636\u064e\u0627\u0646','\u0634\u064e\u0648\u064e\u0651\u0627\u0644','\u0630\u064f\u0648 \u0627\u0644\u0652\u0642\u064e\u0639\u0652\u062f\u064e\u0629','\u0630\u064f\u0648 \u0627\u0644\u0652\u062d\u0650\u062c\u064e\u0651\u0629'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const wdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    String toAI(int n) {
      const d = ['\u0660','\u0661','\u0662','\u0663','\u0664','\u0665','\u0666','\u0667','\u0668','\u0669'];
      return n.toString().split('').map((c) => d[int.parse(c)]).join();
    }

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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
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
                  Text('${h['d']}',
                      style: TextStyle(fontFamily: 'serif', fontSize: 34, height: 1,
                          color: context.isDark ? AppColors.warmWhite : const Color(0xFF2a1e08))),
                  Text(hMonths[h['m']!],
                      style: TextStyle(fontFamily: 'serif', fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: context.isDark ? AppColors.gold : AppColors.goldDark)),
                  Text('${h['y']} AH',
                      style: TextStyle(fontSize: 9, fontFamily: 'sans-serif',
                          color: context.isDark ? AppColors.goldDim : const Color(0xFF9a7030))),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(toAI(h['d']!),
                      style: TextStyle(fontFamily: 'Scheherazade', fontSize: 34, height: 1,
                          color: context.isDark ? AppColors.gold : AppColors.goldDark)),
                  Text(hMonthsAr[h['m']!],
                      style: TextStyle(fontFamily: 'Scheherazade', fontSize: 13,
                          color: context.isDark ? AppColors.goldDim : const Color(0xFF9a7030))),
                  Text('${wdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                      style: TextStyle(fontSize: 9, fontFamily: 'sans-serif',
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

class _PrayerGrid extends StatelessWidget {
  final PrayerTimes pt;
  const _PrayerGrid({required this.pt});

  @override
  Widget build(BuildContext context) {
    final prayers = [
      ('Fajr',   pt.fajrStr,   '2S+2F'),
      ('Dhuhr',  pt.dhuhrStr,  '4S+4F\n+2S'),
      ('Asr',    pt.asrStr,    '4S+4F'),
      ('Maghrib',pt.maghribStr,'3F+2S'),
      ('Isha',   pt.ishaStr,   '4F+2S\n+1W'),
    ];
    final next = pt.nextPrayerName;
    final rem = pt.timeUntilNext;
    final countdown = rem.inHours > 0
        ? '${rem.inHours}h ${rem.inMinutes % 60}m'
        : '${rem.inMinutes}m';

    return Column(
      children: [
        Row(
          children: prayers.map((p) {
            final isNext = p.$1 == next;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isNext
                      ? AppColors.goldDim.withOpacity(context.isDark ? 0.18 : 0.12)
                      : context.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isNext ? AppColors.gold : context.border,
                      width: isNext ? 1.2 : 1),
                ),
                child: Column(
                  children: [
                    Text(p.$1,
                        style: TextStyle(fontSize: 7, fontFamily: 'sans-serif',
                            fontWeight: isNext ? FontWeight.w700 : FontWeight.normal,
                            color: isNext
                                ? (context.isDark ? AppColors.gold : AppColors.goldDark)
                                : context.textDim)),
                    const SizedBox(height: 3),
                    Text(p.$2.replaceAll(' AM', '').replaceAll(' PM', ''),
                        style: TextStyle(fontFamily: 'serif', fontSize: 11,
                            color: isNext
                                ? (context.isDark ? AppColors.goldLight : AppColors.goldDark)
                                : context.text)),
                    const SizedBox(height: 2),
                    Text(p.$3,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 6, fontFamily: 'sans-serif',
                            height: 1.3,
                            color: isNext ? AppColors.goldDim : context.textDim.withOpacity(0.6))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 5, height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold)),
          const SizedBox(width: 6),
          Text('Next: ', style: TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: context.textDim)),
          Text(next, style: TextStyle(fontSize: 10, fontFamily: 'sans-serif',
              color: AppColors.gold, fontWeight: FontWeight.w700)),
          Text(' in $countdown', style: TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: context.textDim)),
        ]),
      ],
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
