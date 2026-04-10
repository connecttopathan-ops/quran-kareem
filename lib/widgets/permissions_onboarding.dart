import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Shows the permissions onboarding bottom sheet if any permission needs
/// attention. Safe to call on every launch — silently skips if all are granted.
///
/// Logic:
///  • First launch (flag not set) → always show, non-dismissible
///  • Subsequent launches → show only if notifications still not granted
///  • Battery / exact alarm → shown once (flag set after first display)
Future<void> showPermissionsOnboardingIfNeeded(BuildContext context) async {
  if (!Platform.isAndroid) return;

  final notifGranted = await NotificationService().hasNotificationPermission();
  final batteryExempt =
      (await Permission.ignoreBatteryOptimizations.status).isGranted;

  // Derive Android SDK version for exact-alarm row visibility
  int sdkInt = 0;
  String manufacturer = '';
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    sdkInt = info.version.sdkInt;
    manufacturer = info.manufacturer.toLowerCase();
  } catch (_) {}

  // Exact alarm row: only relevant on Android 12+ when not yet granted
  final exactGranted = await NotificationService().hasExactAlarmPermission();
  final showExactRow = sdkInt >= 31 && !exactGranted;

  // Skip entirely if everything is already good
  if (notifGranted && batteryExempt && !showExactRow) return;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: notifGranted, // lock if notifications not yet granted
    enableDrag: notifGranted,
    backgroundColor: Colors.transparent,
    builder: (_) => _PermissionsSheet(
      initialNotifGranted: notifGranted,
      initialExactGranted: exactGranted,
      initialBatteryExempt: batteryExempt,
      showExactRow: showExactRow,
      manufacturer: manufacturer,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _PermissionsSheet extends StatefulWidget {
  final bool initialNotifGranted;
  final bool initialExactGranted;
  final bool initialBatteryExempt;
  final bool showExactRow;
  final String manufacturer;

  const _PermissionsSheet({
    required this.initialNotifGranted,
    required this.initialExactGranted,
    required this.initialBatteryExempt,
    required this.showExactRow,
    required this.manufacturer,
  });

  @override
  State<_PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<_PermissionsSheet>
    with WidgetsBindingObserver {
  late bool _notifGranted;
  late bool _exactGranted;
  late bool _batteryExempt;
  late bool _showExactRow;

  @override
  void initState() {
    super.initState();
    _notifGranted = widget.initialNotifGranted;
    _exactGranted = widget.initialExactGranted;
    _batteryExempt = widget.initialBatteryExempt;
    _showExactRow = widget.showExactRow;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check all statuses when user returns from system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheck();
  }

  Future<void> _recheck() async {
    final notif = await NotificationService().hasNotificationPermission();
    final exact = await NotificationService().hasExactAlarmPermission();
    final battery =
        (await Permission.ignoreBatteryOptimizations.status).isGranted;
    if (mounted) {
      setState(() {
        _notifGranted = notif;
        _exactGranted = exact;
        _batteryExempt = battery;
        if (exact) _showExactRow = false;
      });
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg =>
      _isDark ? const Color(0xFF1A1408) : const Color(0xFFF9F3E8);
  Color get _titleColor =>
      _isDark ? Colors.white : AppColors.deepText;
  Color get _subtitleColor =>
      _isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF5A4A2A);

  /// Manufacturer-specific extra step shown inside the battery card.
  String? get _batteryTip {
    final m = widget.manufacturer;
    if (m.contains('samsung')) {
      return 'Samsung extra step: Settings → Battery → Never sleeping apps'
          ' → tap + and add Get Quran';
    }
    if (m.contains('xiaomi') ||
        m.contains('redmi') ||
        m.contains('poco')) {
      return 'Xiaomi extra step: Settings → Apps → Manage apps → Get Quran'
          ' → AutoStart → turn On';
    }
    if (m.contains('huawei') || m.contains('honor')) {
      return 'Huawei extra step: Settings → Battery → App launch → Get Quran'
          ' → Manage manually → enable all toggles';
    }
    if (m.contains('oppo') ||
        m.contains('realme') ||
        m.contains('oneplus')) {
      return 'Extra step: Settings → Battery → Battery optimization'
          ' → Get Quran → Don\'t optimize';
    }
    if (m.contains('vivo')) {
      return 'Vivo extra step: Settings → Battery → High background power'
          ' consumption → add Get Quran';
    }
    return null;
  }

  bool get _allCriticalGranted => _notifGranted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.gold.withOpacity(0.35)),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Setup Notifications',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _titleColor)),
                  Text('Never miss a prayer time',
                      style: TextStyle(
                          fontSize: 13, color: _subtitleColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Permission rows ─────────────────────────────────────────────

          // 1. Notifications
          _PermRow(
            icon: Icons.notifications_outlined,
            title: 'Allow Notifications',
            description: 'Required to receive prayer time alerts',
            granted: _notifGranted,
            isDark: _isDark,
            onGrant: () async {
              await Permission.notification.request();
              await _recheck();
            },
          ),

          // 2. Precise timing (Android 12–13 only when not auto-granted)
          if (_showExactRow)
            _PermRow(
              icon: Icons.alarm_outlined,
              title: 'Precise Timing',
              description:
                  'Ensures notifications arrive exactly at prayer time, not minutes late',
              granted: _exactGranted,
              isDark: _isDark,
              onGrant: () async {
                // Opens the Alarms & Reminders system settings page.
                // Re-check happens via didChangeAppLifecycleState on return.
                await NotificationService().openExactAlarmSettings();
              },
            ),

          // 3. Battery optimisation
          _PermRow(
            icon: Icons.battery_saver_outlined,
            title: 'Always Run in Background',
            description:
                'Prevents your phone from blocking prayer alerts when the screen is off',
            granted: _batteryExempt,
            tip: _batteryTip,
            isDark: _isDark,
            onGrant: () async {
              await Permission.ignoreBatteryOptimizations.request();
              await _recheck();
            },
          ),

          const SizedBox(height: 20),

          // ── Continue button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _allCriticalGranted
                  ? () => Navigator.of(context).pop()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.gold.withOpacity(0.35),
                disabledForegroundColor: Colors.white.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _allCriticalGranted ? 'All Set — Continue' : 'Allow Notifications to Continue',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          if (!_notifGranted) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () async {
                  // Open app settings as last resort if permission is permanently denied
                  await openAppSettings();
                },
                child: Text(
                  'Open app settings',
                  style:
                      TextStyle(fontSize: 12, color: _subtitleColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PermRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final bool isDark;
  final VoidCallback onGrant;
  final String? tip;

  const _PermRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.isDark,
    required this.onGrant,
    this.tip,
  });

  Color get _titleColor => isDark ? Colors.white : AppColors.deepText;
  Color get _subColor =>
      isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF5A4A2A);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.gold.withOpacity(0.08)
            : (isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted
              ? AppColors.gold.withOpacity(0.4)
              : (isDark ? AppColors.darkGoldBorder : AppColors.goldBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: granted
                      ? AppColors.gold.withOpacity(0.15)
                      : (isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.05)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  granted ? Icons.check_rounded : icon,
                  color: granted
                      ? AppColors.gold
                      : (isDark
                          ? Colors.white.withOpacity(0.45)
                          : Colors.black.withOpacity(0.35)),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _titleColor)),
                    const SizedBox(height: 3),
                    Text(description,
                        style: TextStyle(
                            fontSize: 12,
                            color: _subColor,
                            height: 1.35)),
                  ],
                ),
              ),
              if (!granted) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onGrant,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gold),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Allow',
                        style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),

          // Manufacturer-specific tip
          if (tip != null && !granted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 13,
                      color: AppColors.gold.withOpacity(0.85)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(tip!,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gold.withOpacity(0.9),
                            height: 1.45)),
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
