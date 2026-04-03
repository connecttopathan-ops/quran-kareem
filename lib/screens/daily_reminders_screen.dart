import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class DailyRemindersScreen extends StatefulWidget {
  const DailyRemindersScreen({super.key});

  @override
  State<DailyRemindersScreen> createState() => _DailyRemindersScreenState();
}

class _DailyRemindersScreenState extends State<DailyRemindersScreen> {
  // Morning reminder
  bool _morningEnabled = false;
  TimeOfDay _morningTime = const TimeOfDay(hour: 6, minute: 0);

  // Evening reminder
  bool _eveningEnabled = false;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  // Ayah of the day
  bool _ayahEnabled = false;
  TimeOfDay _ayahTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _morningEnabled = prefs.getBool('reminder_morning_enabled') ?? false;
      _morningTime = TimeOfDay(
        hour: prefs.getInt('reminder_morning_hour') ?? 6,
        minute: prefs.getInt('reminder_morning_minute') ?? 0,
      );
      _eveningEnabled = prefs.getBool('reminder_evening_enabled') ?? false;
      _eveningTime = TimeOfDay(
        hour: prefs.getInt('reminder_evening_hour') ?? 20,
        minute: prefs.getInt('reminder_evening_minute') ?? 0,
      );
      _ayahEnabled = prefs.getBool('ayah_notification_enabled') ?? false;
      _ayahTime = TimeOfDay(
        hour: prefs.getInt('ayah_notification_hour') ?? 19,
        minute: prefs.getInt('ayah_notification_minute') ?? 0,
      );
    });
  }

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.gold,
            surface: Theme.of(ctx).scaffoldBackgroundColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reminder_morning_enabled', _morningEnabled);
      await prefs.setInt('reminder_morning_hour', _morningTime.hour);
      await prefs.setInt('reminder_morning_minute', _morningTime.minute);
      await prefs.setBool('reminder_evening_enabled', _eveningEnabled);
      await prefs.setInt('reminder_evening_hour', _eveningTime.hour);
      await prefs.setInt('reminder_evening_minute', _eveningTime.minute);
      await prefs.setBool('ayah_notification_enabled', _ayahEnabled);
      await prefs.setInt('ayah_notification_hour', _ayahTime.hour);
      await prefs.setInt('ayah_notification_minute', _ayahTime.minute);

      final svc = NotificationService();
      await svc.scheduleDailyReminders(
        morningEnabled: _morningEnabled,
        morningHour: _morningTime.hour,
        morningMinute: _morningTime.minute,
        eveningEnabled: _eveningEnabled,
        eveningHour: _eveningTime.hour,
        eveningMinute: _eveningTime.minute,
      );
      await svc.scheduleAyahNotifications(
        enabled: _ayahEnabled,
        hour: _ayahTime.hour,
        minute: _ayahTime.minute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Daily reminders saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
                  Text('Daily Reminders',
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
                  _SectionHeader('QURAN READING REMINDER'),
                  _buildReminderCard(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Morning',
                    subtitle: 'After Fajr — start the day with Quran',
                    enabled: _morningEnabled,
                    time: _morningTime,
                    onToggle: (v) => setState(() => _morningEnabled = v),
                    onTimeTap: () => _pickTime(
                        _morningTime, (t) => setState(() => _morningTime = t)),
                  ),
                  const SizedBox(height: 8),
                  _buildReminderCard(
                    icon: Icons.nightlight_outlined,
                    label: 'Evening',
                    subtitle: 'End the day with the words of Allah',
                    enabled: _eveningEnabled,
                    time: _eveningTime,
                    onToggle: (v) => setState(() => _eveningEnabled = v),
                    onTimeTap: () => _pickTime(
                        _eveningTime, (t) => setState(() => _eveningTime = t)),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('AYAH OF THE DAY'),
                  _buildAyahCard(),
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
                  child: const Text('Save Reminders',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(fontSize: 14, color: context.text)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textDim,
                              fontFamily: 'sans-serif')),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: AppColors.gold,
                ),
              ],
            ),
          ),
          if (enabled) ...[
            Divider(height: 1, color: context.border),
            GestureDetector(
              onTap: onTimeTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: context.textDim),
                    const SizedBox(width: 8),
                    Text('Reminder time',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.textDim,
                            fontFamily: 'sans-serif')),
                    const Spacer(),
                    Text(
                      time.format(context),
                      style: TextStyle(
                          fontSize: 15,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 18, color: context.textDim),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAyahCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ayah of the Day',
                          style: TextStyle(fontSize: 14, color: context.text)),
                      const SizedBox(height: 2),
                      Text('A new ayah with reflection, daily',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textDim,
                              fontFamily: 'sans-serif')),
                    ],
                  ),
                ),
                Switch(
                  value: _ayahEnabled,
                  onChanged: (v) => setState(() => _ayahEnabled = v),
                  activeColor: AppColors.gold,
                ),
              ],
            ),
          ),
          if (_ayahEnabled) ...[
            Divider(height: 1, color: context.border),
            GestureDetector(
              onTap: () => _pickTime(
                  _ayahTime, (t) => setState(() => _ayahTime = t)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: context.textDim),
                    const SizedBox(width: 8),
                    Text('Delivery time',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.textDim,
                            fontFamily: 'sans-serif')),
                    const Spacer(),
                    Text(
                      _ayahTime.format(context),
                      style: TextStyle(
                          fontSize: 15,
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 18, color: context.textDim),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: context.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.gold, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '30 curated ayahs rotate daily with a short reflection. Recommended between Maghrib and Isha.',
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
        ],
      ),
    );
  }
}

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
