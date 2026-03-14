import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
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
    extends State<PrayerNotificationSettingsScreen> {
  PrayerNotificationMode _mode = PrayerNotificationMode.off;
  AdhanType _adhanType = AdhanType.makkah;
  AudioPlayer? _audioPlayer;
  String? _playingId; // 'makkah' | 'madinah' | null

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('prayer_notification_mode') ?? 'off';
    final adhanStr = prefs.getString('adhan_type') ?? 'makkah';
    if (!mounted) return;
    setState(() {
      _mode = PrayerNotificationMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => PrayerNotificationMode.off,
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
      await _audioPlayer!.play(AssetSource(assetPath));
      setState(() => _playingId = id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file not yet installed')),
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayer_notification_mode', _mode.name);
    await prefs.setString('adhan_type', _adhanType.name);

    final pt = context.read<LocationService>().prayerTimes;
    if (pt != null) {
      final times = {
        'Fajr': pt.fajrStr,
        'Dhuhr': pt.dhuhrStr,
        'Asr': pt.asrStr,
        'Maghrib': pt.maghribStr,
        'Isha': pt.ishaStr,
      };
      await NotificationService()
          .scheduleAllPrayers(times, _mode, adhanType: _adhanType);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("✓ Notifications scheduled for today's prayers")),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
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
      (PrayerNotificationMode.adhan, '🔊', 'Adhan',
          'Full adhan audio at prayer time'),
      (PrayerNotificationMode.vibration, '📳', 'Vibration',
          'Repeating vibration, no sound'),
      (PrayerNotificationMode.singleVibration, '📳', 'Single pulse',
          'One short vibration'),
      (PrayerNotificationMode.off, '🔕', 'Off', 'No alerts'),
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
                    Text(opt.$2, style: const TextStyle(fontSize: 16)),
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
        '🕋',
        'Makkah',
        'Masjid al-Haram · Sheikh Mishary Rashid Alafasy',
        'audio/adhan_makkah.mp3',
      ),
      (
        AdhanType.madinah,
        'madinah',
        '🕌',
        'Madinah',
        'Masjid an-Nabawi · Sheikh Ahmad al-Nafees',
        'audio/adhan_madinah.mp3',
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
                        Text(opt.$3, style: const TextStyle(fontSize: 16)),
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
