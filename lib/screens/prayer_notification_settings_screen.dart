import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class PrayerNotificationSettingsScreen extends StatefulWidget {
  const PrayerNotificationSettingsScreen({super.key});

  @override
  State<PrayerNotificationSettingsScreen> createState() =>
      _PrayerNotificationSettingsScreenState();
}

class _PrayerNotificationSettingsScreenState
    extends State<PrayerNotificationSettingsScreen>
    with WidgetsBindingObserver {
  PrayerNotificationMode _mode = PrayerNotificationMode.off;
  AdhanType _adhanType = AdhanType.makkah;
  AudioPlayer? _audioPlayer;
  String? _playingId; // 'makkah' | 'madinah' | null
  bool _pendingSave = false;

  bool _jumuahEnabled = false;
  int _jumuahHour = 13;
  int _jumuahMinute = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _audioPlayer!.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && mounted) {
        setState(() => _playingId = null);
      }
    });
    _loadPrefs();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingSave) {
      _pendingSave = false;
      _save();
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('prayer_notification_mode');
    final adhanStr = prefs.getString('adhan_type') ?? 'makkah';
    if (!mounted) return;
    setState(() {
      _jumuahEnabled = prefs.getBool('jumuah_custom_enabled') ?? false;
      _jumuahHour = prefs.getInt('jumuah_hour') ?? 13;
      _jumuahMinute = prefs.getInt('jumuah_minute') ?? 15;
      // Default to singleVibration on first launch (not off)
      _mode = modeStr == null
          ? PrayerNotificationMode.singleVibration
          : PrayerNotificationMode.values.firstWhere(
              (e) => e.name == modeStr,
              orElse: () => PrayerNotificationMode.singleVibration,
            );
      _adhanType = AdhanType.values.firstWhere(
        (e) => e.name == adhanStr,
        orElse: () => AdhanType.makkah,
      );
    });
  }

  Future<void> _togglePreview(String id, String assetPath) async {
    if (_playingId == id) {
      await _audioPlayer!.stop();
      setState(() => _playingId = null);
      return;
    }
    await _audioPlayer!.stop();
    try {
      await _audioPlayer!.setAudioSource(
        AudioSource.asset(
          assetPath,
          tag: MediaItem(
            id: id,
            title: id == 'makkah' ? 'Makkah Adhan' : 'Madinah Adhan',
            album: 'Adhan Preview',
          ),
        ),
      );
      await _audioPlayer!.play();
      setState(() => _playingId = id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play preview: $e')),
        );
        setState(() => _playingId = null);
      }
    }
  }

  Future<void> _sendTest() async {
    await NotificationService().sendTestNotification(_mode, _adhanType);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent')),
      );
    }
  }


  Future<void> _save() async {
    // Check exact alarm permission before scheduling (Android 12+)
    if (_mode != PrayerNotificationMode.off) {
      final svc = NotificationService();
      final hasExact = await svc.hasExactAlarmPermission();
      if (!hasExact && mounted) {
        final result = await _showExactAlarmRationale();
        if (result == _ExactAlarmResult.allow) {
          _pendingSave = true;
          await svc.openExactAlarmSettings();
          return; // will resume via didChangeAppLifecycleState
        }
        // 'notNow' → continue, notifications may be slightly late
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('prayer_notification_mode', _mode.name);
      await prefs.setString('adhan_type', _adhanType.name);
      await prefs.setBool('jumuah_custom_enabled', _jumuahEnabled);
      await prefs.setInt('jumuah_hour', _jumuahHour);
      await prefs.setInt('jumuah_minute', _jumuahMinute);

      if (_mode == PrayerNotificationMode.off) {
        await NotificationService().cancelPrayerNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications turned off')));
        }
        return;
      }

      // Ensure notification permission — request if not yet granted
      final hasPermission = await NotificationService().hasNotificationPermission();
      if (!hasPermission) {
        if (!mounted) return;
        await Permission.notification.request();
        // Continue even if denied — Android will silently not show notifications
      }

      final pt = context.read<LocationService>().prayerTimes;
      if (pt != null) {
        await NotificationService()
            .scheduleAllPrayers(pt.lat, pt.lng, pt.calcMethod, _mode, adhanType: _adhanType);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Notifications scheduled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<_ExactAlarmResult> _showExactAlarmRationale() async {
    final result = await showDialog<_ExactAlarmResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1608) : const Color(0xFFF9F3E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.gold, size: 28),
                ),
                const SizedBox(height: 16),
                Text('Accurate Prayer Times',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2A1E08),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'To notify you of exact prayer times, Get Quran needs permission to schedule precise alarms.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'sans-serif', fontSize: 13, height: 1.5,
                    color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF5A4A2A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Without this, adhan notifications may arrive a few minutes late.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'sans-serif', fontSize: 11,
                    color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF9A8060),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx, _ExactAlarmResult.allow),
                    child: const Text('Allow Precise Times',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, _ExactAlarmResult.notNow),
                  child: Text('Not Now',
                    style: TextStyle(
                      fontSize: 13, fontFamily: 'sans-serif',
                      color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF9A8060),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? _ExactAlarmResult.notNow;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.border)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios,
                        size: 18, color: context.textDim),
                  ),
                  const SizedBox(width: 10),
                  Text('Prayer Notifications',
                      style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 20,
                          color: context.text)),
                ],
              ),
            ),
            // Body
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                children: [
                  _SectionHeader('ALERT TYPE'),
                  _buildAlertTypeSection(),
                  // Adhan selector (animated reveal)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: _mode == PrayerNotificationMode.adhan ? null : 0,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _SectionHeader('CHOOSE ADHAN'),
                        _buildAdhanSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionHeader('FRIDAY JUMU\'AH'),
                  _buildJumuahSection(),
                  const SizedBox(height: 8),
                  _SectionHeader('TEST'),
                  _buildTestSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _save,
                  child: const Text('Save & Schedule Notifications',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypeSection() {
    final options = [
      (PrayerNotificationMode.adhan, Icons.volume_up, 'Adhan',
          'Full adhan audio at prayer time'),
      (PrayerNotificationMode.vibration, Icons.vibration, 'Vibration',
          'Repeating vibration, no sound'),
      (PrayerNotificationMode.singleVibration, Icons.phone_in_talk, 'Single pulse',
          'One short vibration'),
      (PrayerNotificationMode.off, Icons.notifications_off, 'Off', 'No alerts'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          return Column(
            children: [
              RadioListTile<PrayerNotificationMode>(
                value: opt.$1,
                groupValue: _mode,
                onChanged: (v) => setState(() => _mode = v!),
                activeColor: AppColors.gold,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                title: Row(
                  children: [
                    Icon(opt.$2, size: 16, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Text(opt.$3,
                        style: TextStyle(fontSize: 14, color: context.text)),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(opt.$4,
                      style: TextStyle(
                          fontSize: 11,
                          color: context.textDim,
                          fontFamily: 'sans-serif')),
                ),
              ),
              if (i < options.length - 1)
                Divider(height: 1, color: context.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdhanSection() {
    final options = [
      (
        AdhanType.makkah,
        'makkah',
        Icons.mosque,
        'Makkah',
        'Masjid al-Haram · Sheikh Mishary Rashid Alafasy',
        'assets/audio/adhan_makkah.mp3',
      ),
      (
        AdhanType.madinah,
        'madinah',
        Icons.mosque_outlined,
        'Madinah',
        'Masjid an-Nabawi · Sheikh Ahmad al-Nafees',
        'assets/audio/adhan_madinah.mp3',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.border),
          ),
          child: Column(
            children: options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              final isPlaying = _playingId == opt.$2;
              return Column(
                children: [
                  RadioListTile<AdhanType>(
                    value: opt.$1,
                    groupValue: _adhanType,
                    onChanged: (v) => setState(() => _adhanType = v!),
                    activeColor: AppColors.gold,
                    contentPadding:
                        const EdgeInsets.only(left: 12, right: 8, top: 0),
                    title: Row(
                      children: [
                        Icon(opt.$3, size: 16, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Text(opt.$4,
                            style:
                                TextStyle(fontSize: 14, color: context.text)),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(opt.$5,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textDim,
                              fontFamily: 'sans-serif')),
                    ),
                    secondary: GestureDetector(
                      onTap: () => _togglePreview(opt.$2, opt.$6),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.4)),
                        ),
                        child: Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          size: 18,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                  if (i < options.length - 1)
                    Divider(height: 1, color: context.border),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Fajr info card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.gold, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Fajr will always use the special Fajr adhan with 'As-salatu khayrun minan nawm' regardless of selection.",
                  style: TextStyle(
                      fontSize: 11,
                      color: context.textDim,
                      fontFamily: 'sans-serif'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJumuahSection() {
    final h = _jumuahHour.toString().padLeft(2, '0');
    final m = _jumuahMinute.toString().padLeft(2, '0');
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _jumuahEnabled,
            onChanged: (v) => setState(() => _jumuahEnabled = v),
            activeColor: AppColors.gold,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text('Custom Jumu\'ah time',
                style: TextStyle(fontSize: 14, color: context.text)),
            subtitle: Text(
              'Override the Friday Dhuhr alarm for your mosque\'s Jumu\'ah',
              style: TextStyle(
                  fontSize: 11,
                  color: context.textDim,
                  fontFamily: 'sans-serif'),
            ),
          ),
          if (_jumuahEnabled) ...[
            Divider(height: 1, color: context.border),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text('Jumu\'ah notification time',
                  style: TextStyle(fontSize: 14, color: context.text)),
              trailing: GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: _jumuahHour, minute: _jumuahMinute),
                  );
                  if (picked != null) {
                    setState(() {
                      _jumuahHour = picked.hour;
                      _jumuahMinute = picked.minute;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Text('$h:$m',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          fontFamily: 'sans-serif')),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: BorderSide(color: context.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _sendTest,
        child: Text('Send Test Notification',
            style: TextStyle(fontSize: 14, color: context.text)),
      ),
    );
  }
}

enum _ExactAlarmResult { allow, notNow }

// Section header widget (matching settings_screen.dart style)
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2,
          color: context.textDim,
          fontFamily: 'sans-serif',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
