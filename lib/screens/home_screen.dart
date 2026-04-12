import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_foreground_service.dart';
import '../widgets/q_icons.dart';
import '../data/quran_data.dart';
import 'surah_list_screen.dart';
import 'settings_screen.dart';
import 'reader_screen.dart';
import 'language_selection_screen.dart';
import 'reading_mode_picker_screen.dart';
import 'qibla_screen.dart';
import 'sponsor_screen.dart';
import 'duas_screen.dart';
import 'islamic_books_screen.dart';
import 'book_detail_screen.dart';
import 'book_language_screen.dart';
import '../models/islamic_book.dart';
import '../services/book_download_service.dart';
import '../services/review_service.dart';
import '../data/curated_ayahs.dart';
import '../widgets/permissions_onboarding.dart';
import '../widgets/review_dialog.dart';
import 'hifz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _clockTimer;
  LocationService? _locationService;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ayahKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    NotificationService.notificationPayload.addListener(_onNotificationTap);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().recordAppOpen();
        _checkFirstLaunchLocation();
        // Handle tap if app was launched from notification
        _onNotificationTap();
        // Unified permissions onboarding — runs after a short delay so
        // the location dialog (first-launch only) appears first.
        // Handles: POST_NOTIFICATIONS, exact alarm, battery optimisation.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _runPermissionsOnboarding();
        });
        // Review prompt — fires 3 s after launch so permissions sheet
        // has had time to appear first.
        Future.delayed(const Duration(milliseconds: 3000), () async {
          if (!mounted) return;
          final streak = context.read<AppState>().dayStreak;
          if (await ReviewService.shouldPrompt(streak)) {
            await ReviewService.markShown(streak);
            if (mounted) await showReviewDialog(context, streak);
          }
        });
      }
    });
  }

  /// Shows the unified permissions onboarding sheet (notifications, precise
  /// timing, battery optimisation) and seeds the default notification mode.
  /// Safe to call on every launch — the sheet self-skips when all grants
  /// are already in place.
  Future<void> _runPermissionsOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    // Seed singleVibration as default so new users get prayer reminders
    // without visiting settings first.
    if (prefs.getString('prayer_notification_mode') == null) {
      await prefs.setString(
          'prayer_notification_mode', PrayerNotificationMode.singleVibration.name);
    }

    if (!mounted) return;
    await showPermissionsOnboardingIfNeeded(context);

    // Reschedule after permissions may have changed.
    if (!mounted) return;
    final pt = _locationService?.prayerTimes;
    if (pt != null) await _scheduleNotifications(pt);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reschedule on every resume so clock/timezone changes and day
      // boundaries are handled without needing a cold app restart.
      final pt = _locationService?.prayerTimes;
      if (pt != null) _scheduleNotifications(pt);
    }
  }

  void _onNotificationTap() {
    final payload = NotificationService.notificationPayload.value;
    if (payload == 'ayah_of_the_day') {
      NotificationService.notificationPayload.value = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _ayahKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut);
        }
      });
    } else if (payload == 'read_quran') {
      NotificationService.notificationPayload.value = null;
      // Switch to the Quran tab (index 1 = SurahListScreen).
      setState(() => _currentIndex = 1);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.notificationPayload.removeListener(_onNotificationTap);
    _scrollController.dispose();
    _locationService?.removeListener(_onPrayerTimesUpdated);
    _clockTimer?.cancel();
    super.dispose();
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
    try {
      final prefs = await SharedPreferences.getInstance();
      // Inline default: on a fresh install, treat missing mode as
      // singleVibration (matches the UI default in the settings screen
      // and _bootstrapFirstLaunch). Persist it so subsequent reads agree.
      var modeStr = prefs.getString('prayer_notification_mode');
      if (modeStr == null) {
        modeStr = PrayerNotificationMode.singleVibration.name;
        await prefs.setString('prayer_notification_mode', modeStr);
      }
      final adhanStr = prefs.getString('adhan_type') ?? 'makkah';
      final mode = PrayerNotificationMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => PrayerNotificationMode.singleVibration,
      );
      final adhanType = AdhanType.values.firstWhere(
        (e) => e.name == adhanStr,
        orElse: () => AdhanType.makkah,
      );
      // Start (or restart) the persistent foreground service — provides the
      // live countdown status-bar notification. AlarmManager (scheduleAllPrayers)
      // runs independently for the actual prayer-time alarm pop-ups.
      if (mode != PrayerNotificationMode.off) {
        await PrayerForegroundService.start();
      } else {
        await PrayerForegroundService.stop();
      }

      await NotificationService()
          .scheduleAllPrayers(pt.lat, pt.lng, pt.calcMethod, mode, adhanType: adhanType);

      // Refresh ayah of the day (30-day window — renew on each app open)
      final ayahEnabled = prefs.getBool('ayah_notification_enabled') ?? true;
      await NotificationService().scheduleAyahNotifications(
        enabled: ayahEnabled,
        hour: prefs.getInt('ayah_notification_hour') ?? 11,
        minute: prefs.getInt('ayah_notification_minute') ?? 0,
      );

      // Refresh daily reading reminders
      await NotificationService().scheduleDailyReminders(
        morningEnabled: prefs.getBool('reminder_morning_enabled') ?? true,
        morningHour: prefs.getInt('reminder_morning_hour') ?? 6,
        morningMinute: prefs.getInt('reminder_morning_minute') ?? 0,
        eveningEnabled: prefs.getBool('reminder_evening_enabled') ?? true,
        eveningHour: prefs.getInt('reminder_evening_hour') ?? 20,
        eveningMinute: prefs.getInt('reminder_evening_minute') ?? 0,
      );
    } catch (e, stack) {
      // Never let a scheduling failure crash the UI. Typical cause is a
      // SecurityException when exact alarms aren't granted on Android 12+;
      // individual scheduleXxx methods already fall back to inexact alarms,
      // so this catch is just a last-resort safety net.
      debugPrint('[HomeScreen] _scheduleNotifications failed: $e\n$stack');
    }
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

    // 3. Reading mode picker (first launch, after language selection)
    final modeSet = prefs.getBool('reading_mode_set') ?? false;
    if (!modeSet && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const ReadingModePickerScreen(),
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final screens = [
          _HomeTab(scrollController: _scrollController, ayahKey: _ayahKey),
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

        final surah = kSurahs[np.surahNumber - 1];
        void openReader() => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ReaderScreen(surah: surah)));

        return Container(
          decoration: BoxDecoration(
            color: context.surface,
            border: Border(
              top: BorderSide(color: context.border),
              bottom: BorderSide(color: context.border),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                // Verse badge — tap opens reader
                GestureDetector(
                  onTap: openReader,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.goldDim.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldDim.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: audio.isLoading
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: AppColors.gold))
                          : Text('${np.verseNumber}',
                              style: const TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 12, color: AppColors.gold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Info — tap opens reader
                Expanded(
                  child: GestureDetector(
                    onTap: openReader,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(np.surahName,
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.text)),
                        Text('${audio.reciter.name} · Verse ${np.verseNumber}/${np.totalVerses}',
                            style: TextStyle(fontSize: 9,
                                fontFamily: 'sans-serif',
                                color: context.textDim)),
                      ],
                    ),
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
                    decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
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
              ]),
              const SizedBox(height: 5),
              // Playback progress bar
              StreamBuilder<Duration>(
                stream: audio.positionStream,
                builder: (_, posSnap) => StreamBuilder<Duration?>(
                  stream: audio.durationStream,
                  builder: (_, durSnap) {
                    final pos = posSnap.data?.inMilliseconds ?? 0;
                    final dur = durSnap.data?.inMilliseconds ?? 0;
                    final progress =
                        dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: context.border,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      minHeight: 2,
                      borderRadius: BorderRadius.circular(1),
                    );
                  },
                ),
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
  final ScrollController scrollController;
  final GlobalKey ayahKey;
  const _HomeTab({required this.scrollController, required this.ayahKey});

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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        Text('اَلسَّلَامُ عَلَيْكُمْ',
                            style: TextStyle(fontFamily: 'Scheherazade', fontSize: 14,
                                color: context.isDark ? AppColors.gold : AppColors.goldDark)),
                      ],
                    ),
                  ),
                  // Sponsor a Quran — pill chip style
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SponsorScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(
                            context.isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volunteer_activism,
                              size: 13,
                              color: context.isDark
                                  ? AppColors.goldLight
                                  : AppColors.goldDark),
                          const SizedBox(width: 5),
                          Text(
                            'Sponsor a Quran',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'sans-serif',
                              fontWeight: FontWeight.w600,
                              color: context.isDark
                                  ? AppColors.goldLight
                                  : AppColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 24),
                children: [
                  const _CalPrayerCard(),
                  const SizedBox(height: 12),
                  const _QuickActionsCard(),
                  const SizedBox(height: 12),
                  const _ContinueCard(),
                  const SizedBox(height: 12),
                  _DailyAyah(key: ayahKey),
                  const SizedBox(height: 12),
                  const _BooksHomeSection(),
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
            color: context.isDark ? AppColors.darkGoldBorder : AppColors.goldBorder),
        boxShadow: AppShadows.card(context.isDark),
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
                          color: context.isDark ? AppColors.warmWhite : AppColors.deepText)),
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
              color: context.isDark ? AppColors.darkGoldBorder : AppColors.goldBorder.withOpacity(0.4)),
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

  @override
  void initState() {
    super.initState();

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

  /// Computes the next upcoming prayer and the Duration until it, live from
  /// the prayer time strings. Unlike [widget.pt.nextPrayerName] / [widget.pt.timeUntilNext]
  /// (which are frozen at construction time), this always reflects the current clock.
  (String, Duration) _computeNextPrayer() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prayers = [
      ('Fajr', widget.pt.fajrStr),
      ('Dhuhr', widget.pt.dhuhrStr),
      ('Asr', widget.pt.asrStr),
      ('Maghrib', widget.pt.maghribStr),
      ('Isha', widget.pt.ishaStr),
    ];
    for (final (name, timeStr) in prayers) {
      final t = _parseTime(timeStr);
      final dt = DateTime(today.year, today.month, today.day, t.hour, t.minute);
      if (dt.isAfter(now)) return (name, dt.difference(now));
    }
    // All five prayers for today have passed — wrap to Fajr tomorrow.
    final fajr = _parseTime(widget.pt.fajrStr);
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowFajr = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, fajr.hour, fajr.minute);
    return ('Fajr', tomorrowFajr.difference(now));
  }

  Widget _buildNextRow(BuildContext context, String next, String countdown, String currentPrayer) {
    final sunriseTime = widget.pt.sunriseTime;
    final now = DateTime.now();
    final afterFajrWindow = currentPrayer == 'Fajr';
    final beforeSunrise = now.isBefore(sunriseTime);
    final sunriseWindowEnd = sunriseTime.add(const Duration(hours: 1));
    final inSunriseWindow = !beforeSunrise && now.isBefore(sunriseWindowEnd);

    Widget blinkingDot() => FadeTransition(
      opacity: _blinkAnim,
      child: Container(width: 8, height: 8,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold)),
    );

    // State 1: After Fajr, before Sunrise — countdown to sunrise
    if (afterFajrWindow && beforeSunrise) {
      final until = sunriseTime.difference(now);
      final h = until.inHours;
      final m = until.inMinutes % 60;
      final s = until.inSeconds % 60;
      final cd = h > 0 ? '${h}h ${m}m ${s}s' : '${m}m ${s}s';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            blinkingDot(),
            const SizedBox(width: 6),
            Text('Sunrise in ', style: TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: context.textDim)),
            Text(cd, style: const TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: AppColors.gold, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text('at ${widget.pt.sunriseStr}',
              style: TextStyle(fontSize: 8.5, fontFamily: 'sans-serif', color: context.textDim)),
          ),
        ],
      );
    }

    // State 2: 0–60 min after sunrise — show sunrise time + next prayer
    if (afterFajrWindow && inSunriseWindow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            blinkingDot(),
            const SizedBox(width: 6),
            Text('Sunrise was at ', style: TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: context.textDim)),
            Text(widget.pt.sunriseStr, style: const TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: AppColors.gold, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(children: [
              Text('Next: ', style: TextStyle(fontSize: 8.5, fontFamily: 'sans-serif', color: context.textDim)),
              Text(next, style: const TextStyle(fontSize: 8.5, fontFamily: 'sans-serif', color: AppColors.gold, fontWeight: FontWeight.w600)),
              Text(' in $countdown', style: const TextStyle(fontSize: 8.5, fontFamily: 'sans-serif', color: AppColors.gold, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      );
    }

    // Normal: blinking gold dot + next prayer countdown
    return Row(children: [
      blinkingDot(),
      const SizedBox(width: 6),
      Text('Next: ', style: TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: context.textDim)),
      Text(next, style: const TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: AppColors.gold, fontWeight: FontWeight.w700)),
      Text(' in $countdown', style: const TextStyle(fontSize: 10, fontFamily: 'sans-serif', color: AppColors.gold, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildPopup(BuildContext context, String prayerName) {
    final rows = _kRakahRows[prayerName] ?? [];
    final total = _kRakahTotal[prayerName] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: AppShadows.elevated(context.isDark),
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
    final (next, rem) = _computeNextPrayer();
    final currentPrayer = _getCurrentPrayer({
      'Fajr': widget.pt.fajrStr,
      'Dhuhr': widget.pt.dhuhrStr,
      'Asr': widget.pt.asrStr,
      'Maghrib': widget.pt.maghribStr,
      'Isha': widget.pt.ishaStr,
    });

    final h = rem.inHours;
    final m = rem.inMinutes % 60;
    final s = rem.inSeconds % 60;
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
                        color: isCurrent
                            ? (context.isDark ? const Color(0xFF1a1508) : const Color(0xFFf5e8cc))
                            : AppColors.gold.withOpacity(0.08),
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
                                      ? (context.isDark ? AppColors.gold : AppColors.deepText)
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
                                      ? (context.isDark ? AppColors.gold : AppColors.deepText)
                                      : context.text)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? (context.isDark ? AppColors.gold.withOpacity(0.15) : const Color(0x332a1e08))
                                  : context.textDim.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${p.$3} rak.',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'sans-serif',
                                    color: isCurrent
                                        ? const Color(0xFF2C1A00)
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
          // Next prayer row — sunrise-aware 3 states
          _buildNextRow(context, next, countdown, currentPrayer),
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
      if (mounted) setState(() { _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _searchErr = 'City not found. Try a different spelling.'; _searching = false; });
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
                border: Border.all(color: context.border),
                boxShadow: AppShadows.card(context.isDark)),
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
  const _DailyAyah({super.key});

  static CuratedAyah get _todaysAyah {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return curatedAyahs[dayOfYear % curatedAyahs.length];
  }

  @override
  Widget build(BuildContext context) {
    final ayah = _todaysAyah;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: context.isDark
            ? [const Color(0xFF0e0b04), const Color(0xFF1a1508)]
            : [const Color(0xFFf5e8cc), const Color(0xFFefdba8)]),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.isDark
            ? AppColors.darkGoldBorder : AppColors.goldBorder),
        boxShadow: AppShadows.card(context.isDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('✦  Ayah of the Day  ✦'.toUpperCase(),
            style: TextStyle(fontSize: 7, letterSpacing: 2,
                color: context.isDark ? AppColors.goldDim : AppColors.goldDark,
                fontFamily: 'sans-serif')),
        const SizedBox(height: 8),
        Text(ayah.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Scheherazade', fontSize: 18, height: 2,
                color: context.isDark ? AppColors.goldLight : AppColors.deepText)),
        Divider(color: AppColors.goldDim.withOpacity(0.25)),
        const SizedBox(height: 4),
        Text(
          '"${ayah.translation}"',
          style: TextStyle(fontSize: 12, fontFamily: 'sans-serif',
              color: context.isDark ? const Color(0xFFb0a080) : const Color(0xFF5a4020)),
        ),
        const SizedBox(height: 6),
        Text(
          ayah.message,
          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
              color: context.isDark ? const Color(0xFF888888) : const Color(0xFF806840)),
        ),
        const SizedBox(height: 6),
        Text('Surah ${ayah.surahName} · ${ayah.surah}:${ayah.ayah}',
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
    // coming_soon = true means placeholder — tapping shows a snackbar
    final actions = [
      (
        icon: Icons.explore_rounded,
        label: 'Qibla',
        subtitle: 'Find direction',
        comingSoon: false,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
      ),
      (
        icon: Icons.menu_book_rounded,
        label: 'Duas',
        subtitle: 'Daily supplications',
        comingSoon: false,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DuasScreen())),
      ),
      (
        icon: Icons.auto_stories_rounded,
        label: 'Hifz',
        subtitle: 'Memorize Surahs',
        comingSoon: false,
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const HifzScreen())),
      ),
      (
        icon: Icons.format_list_numbered_rounded,
        label: '99 Names',
        subtitle: 'Asma ul Husna',
        comingSoon: true,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('99 Names of Allah — coming soon',
                style: TextStyle(fontFamily: 'sans-serif')),
            backgroundColor: AppColors.goldDark,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        ),
      ),
      (
        icon: Icons.accessibility_new_rounded,
        label: 'Salah',
        subtitle: 'Perform prayer',
        comingSoon: true,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perform Salah — coming soon',
                style: TextStyle(fontFamily: 'sans-serif')),
            backgroundColor: AppColors.goldDark,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        ),
      ),
    ];

    return SizedBox(
      height: 122,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (ctx, i) {
          final a = actions[i];
          final isDimmed = a.comingSoon;
          return GestureDetector(
            onTap: a.onTap,
            child: Container(
              width: 92,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
              decoration: BoxDecoration(
                color: isDimmed
                    ? context.surface.withOpacity(0.6)
                    : context.surface,
                borderRadius: BorderRadius.circular(14),
                // No top border — gold strip serves as the top edge
                border: Border(
                  left: BorderSide(
                    color: isDimmed
                        ? context.border.withOpacity(0.5)
                        : context.border,
                  ),
                  right: BorderSide(
                    color: isDimmed
                        ? context.border.withOpacity(0.5)
                        : context.border,
                  ),
                  bottom: BorderSide(
                    color: isDimmed
                        ? context.border.withOpacity(0.5)
                        : context.border,
                  ),
                ),
                boxShadow: isDimmed ? null : AppShadows.card(context.isDark),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gold accent strip at top
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDimmed
                              ? [
                                  context.border.withOpacity(0.4),
                                  context.border.withOpacity(0.1),
                                ]
                              : [
                                  AppColors.gold.withOpacity(0.6),
                                  AppColors.goldLight.withOpacity(0.3),
                                ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circular icon background
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDimmed
                                  ? context.border.withOpacity(0.15)
                                  : AppColors.gold.withOpacity(
                                      context.isDark ? 0.15 : 0.12),
                              border: Border.all(
                                color: isDimmed
                                    ? context.border.withOpacity(0.3)
                                    : AppColors.gold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(a.icon,
                                  size: 20,
                                  color: isDimmed
                                      ? context.textDim.withOpacity(0.5)
                                      : AppColors.gold),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(a.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDimmed
                                      ? context.textDim.withOpacity(0.5)
                                      : context.text),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 2),
                          Text(
                            isDimmed ? 'Coming soon' : a.subtitle,
                            style: TextStyle(
                                fontSize: 8,
                                fontFamily: 'sans-serif',
                                color: isDimmed
                                    ? context.textDim.withOpacity(0.4)
                                    : context.textDim),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

// ─────────────────────────────────────────────────────────────────────────────
// ISLAMIC BOOKS HOME SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _BooksHomeSection extends StatefulWidget {
  const _BooksHomeSection();

  @override
  State<_BooksHomeSection> createState() => _BooksHomeSectionState();
}

class _BooksHomeSectionState extends State<_BooksHomeSection> {
  String _filter = 'all'; // 'all', 'hadith', 'seerah'

  @override
  void initState() {
    super.initState();
    // Language picker is shown on first open of IslamicBooksScreen, not here
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookDownloadService>(
      builder: (context, svc, _) {
        final allBooks = kIslamicBooks;
        final filtered = _filter == 'hadith'
            ? allBooks.where((b) => b.category == BookCategory.hadith).toList()
            : _filter == 'seerah'
                ? allBooks
                    .where((b) => b.category == BookCategory.seerah)
                    .toList()
                : allBooks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Continue reading a book
            if (svc.mostRecentBook != null) ...[
              _BookContinueCard(svc: svc),
              const SizedBox(height: 12),
            ],
            // Section header
            Row(
              children: [
                Text('Islamic Books'.toUpperCase(),
                    style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2.5,
                        color: context.textDim,
                        fontFamily: 'sans-serif')),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const IslamicBooksScreen()),
                  ),
                  child: const Text('See all',
                      style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'sans-serif',
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Filter chips
            Row(
              children: [
                _FilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 6),
                _FilterChip(
                    label: 'Hadith',
                    selected: _filter == 'hadith',
                    onTap: () => setState(() => _filter = 'hadith')),
                const SizedBox(width: 6),
                _FilterChip(
                    label: 'Seerah',
                    selected: _filter == 'seerah',
                    onTap: () => setState(() => _filter = 'seerah')),
              ],
            ),
            const SizedBox(height: 10),
            // Horizontal book cards
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final book = filtered[i];
                  return _HomeBookCard(
                    book: book,
                    svc: svc,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.goldDim.withOpacity(0.12)
              : context.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.gold : context.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontFamily: 'sans-serif',
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? AppColors.gold : context.textDim)),
      ),
    );
  }
}

class _HomeBookCard extends StatefulWidget {
  final IslamicBook book;
  final BookDownloadService svc;

  const _HomeBookCard({required this.book, required this.svc});

  @override
  State<_HomeBookCard> createState() => _HomeBookCardState();
}

class _HomeBookCardState extends State<_HomeBookCard> {
  double _readingProgress = 0;

  @override
  void initState() {
    super.initState();
    widget.svc.getReadingProgress(widget.book.id).then((p) {
      if (mounted) setState(() => _readingProgress = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.svc.stateFor(widget.book.id);
    final dlProgress = widget.svc.progressFor(widget.book.id);

    String badge;
    switch (state) {
      case BookDownloadState.notDownloaded:
        badge = 'Download to read';
        break;
      case BookDownloadState.downloading:
        badge = 'Downloading ${(dlProgress * 100).toStringAsFixed(0)}%';
        break;
      case BookDownloadState.downloaded:
        badge = _readingProgress > 0 ? 'Continue' : 'Start reading';
        break;
      case BookDownloadState.failed:
        badge = 'Tap to retry';
        break;
    }

    return GestureDetector(
      onTap: () async {
        if (state == BookDownloadState.downloaded) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BookDetailScreen(book: widget.book)),
          );
        } else if (state == BookDownloadState.notDownloaded ||
            state == BookDownloadState.failed) {
          final shown = await widget.svc.wasPromptShown(widget.book.id);
          if (!shown) {
            await widget.svc.markPromptShown(widget.book.id);
            if (context.mounted) {
              await showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) =>
                    BookDownloadSheet(book: widget.book, svc: widget.svc),
              );
            }
          } else {
            widget.svc.startDownload(widget.book);
          }
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spine header
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: widget.book.spineColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Center(
                child: Text(widget.book.spineChar,
                    style: const TextStyle(
                        fontFamily: 'Scheherazade',
                        fontSize: 32,
                        color: AppColors.gold)),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Text(widget.book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.text)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 1, 8, 0),
              child: Text(widget.book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 8,
                      fontFamily: 'sans-serif',
                      color: context.textDim)),
            ),
            // Progress bar
            if (_readingProgress > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _readingProgress,
                    minHeight: 2,
                    backgroundColor: context.border,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ),
            const Spacer(),
            // Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: state == BookDownloadState.downloaded
                      ? AppColors.gold
                      : context.surface2,
                  borderRadius: BorderRadius.circular(6),
                  border: state == BookDownloadState.downloaded
                      ? null
                      : Border.all(color: context.border),
                ),
                child: Text(badge,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 9,
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.w600,
                        color: state == BookDownloadState.downloaded
                            ? Colors.white
                            : context.textDim)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOK CONTINUE READING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _BookContinueCard extends StatefulWidget {
  final BookDownloadService svc;
  const _BookContinueCard({required this.svc});

  @override
  State<_BookContinueCard> createState() => _BookContinueCardState();
}

class _BookContinueCardState extends State<_BookContinueCard> {
  double _progress = 0;
  String _positionLabel = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final book = widget.svc.mostRecentBook;
    if (book == null) return;
    final progress = await widget.svc.getReadingProgress(book.id);
    final pos = await widget.svc.getLastPosition(book.id);
    if (mounted) {
      setState(() {
        _progress = progress;
        if (pos != null) {
          final parts = pos.split(':');
          final chapterNum = parts.isNotEmpty ? parts[0] : '?';
          final hadithNum = parts.length > 1 ? parts[1] : '0';
          _positionLabel = book.category == BookCategory.hadith
              ? 'Book $chapterNum · Hadith $hadithNum'
              : 'Chapter $chapterNum';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.svc.mostRecentBook;
    if (book == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Continue Reading'.toUpperCase(),
            style: TextStyle(
                fontSize: 8,
                letterSpacing: 2.5,
                color: context.textDim,
                fontFamily: 'sans-serif')),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BookDetailScreen(book: book)),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: book.spineColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(book.spineChar,
                          style: const TextStyle(
                              fontFamily: 'Scheherazade',
                              fontSize: 18,
                              color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.text)),
                        if (_positionLabel.isNotEmpty)
                          Text(_positionLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.textDim,
                                  fontFamily: 'sans-serif')),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: context.textDim),
                ]),
                if (_progress > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 3,
                      backgroundColor: context.border,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.gold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
