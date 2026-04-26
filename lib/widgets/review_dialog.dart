import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';

/// Shows the 2-step review funnel:
///   Step 1 — sentiment gate ("Enjoying Get Quran?")
///   Step 2a — happy path: native OS review sheet
///   Step 2b — unhappy path: text feedback → Google Sheets
Future<void> showReviewDialog(BuildContext context, int streak) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReviewDialog(streak: streak),
  );
}

enum _Step { greeting, feedback, done }

class _ReviewDialog extends StatefulWidget {
  final int streak;
  const _ReviewDialog({required this.streak});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  _Step _step = _Step.greeting;
  final _feedbackController = TextEditingController();
  bool _submitting = false;
  bool _submitFailed = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _isDark ? const Color(0xFF1A1408) : const Color(0xFFF9F3E8);
  Color get _titleColor => _isDark ? Colors.white : AppColors.deepText;
  Color get _subtitleColor =>
      _isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF5A4A2A);
  Color get _dimColor =>
      _isDark ? Colors.white.withOpacity(0.35) : const Color(0xFF9A8060);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (_step) {
            _Step.greeting => _buildGreeting(),
            _Step.feedback => _buildFeedback(),
            _Step.done     => _buildDone(),
          },
        ),
      ),
    );
  }

  // ── Step 1: Sentiment gate ─────────────────────────────────────────────────

  Widget _buildGreeting() {
    return Column(
      key: const ValueKey('greeting'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoldCircleIcon(icon: Icons.auto_awesome_rounded),
        const SizedBox(height: 14),
        Text(
          '${widget.streak}-Day Streak! ✨',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Scheherazade',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Are you enjoying Get Quran?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your feedback helps Muslims around the world discover this app.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: _subtitleColor),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: '⭐  Yes, I love it!',
          onTap: _onLoveIt,
        ),
        const SizedBox(height: 10),
        _SecondaryButton(
          label: '💬  Not really…',
          onTap: () => setState(() => _step = _Step.feedback),
          color: _subtitleColor,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _onLater,
          child: Text(
            'Remind me later',
            style: TextStyle(fontSize: 13, color: _dimColor),
          ),
        ),
      ],
    );
  }

  Future<void> _onLoveIt() async {
    Navigator.of(context).pop();
    await ReviewService.openStorePage();
    await ReviewService.markCompleted();
  }

  Future<void> _onLater() async {
    Navigator.of(context).pop();
    await ReviewService.snooze();
  }

  // ── Step 2: Feedback form ──────────────────────────────────────────────────

  Widget _buildFeedback() {
    return Column(
      key: const ValueKey('feedback'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoldCircleIcon(icon: Icons.mail_outline_rounded),
        const SizedBox(height: 14),
        Text(
          "We're listening 💌",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'What could be better? (optional)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _subtitleColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _feedbackController,
          maxLines: 4,
          maxLength: 500,
          autofocus: true,
          style: TextStyle(fontSize: 14, color: _titleColor),
          decoration: InputDecoration(
            hintText: 'Type your feedback here…',
            hintStyle: TextStyle(color: _dimColor, fontSize: 14),
            filled: true,
            fillColor: _isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _isDark
                    ? AppColors.darkGoldBorder
                    : AppColors.goldBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _isDark
                    ? AppColors.darkGoldBorder
                    : AppColors.goldBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.gold, width: 1.5),
            ),
            counterStyle: TextStyle(color: _dimColor, fontSize: 11),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (_submitFailed) ...[
          const SizedBox(height: 6),
          Text(
            'Could not send — check your connection.',
            style: TextStyle(color: Colors.red.shade400, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        _PrimaryButton(
          label: _submitting ? 'Sending…' : 'Send Feedback',
          onTap: _submitting ? null : _onSend,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'No thanks',
            style: TextStyle(fontSize: 13, color: _dimColor),
          ),
        ),
      ],
    );
  }

  Future<void> _onSend() async {
    setState(() { _submitting = true; _submitFailed = false; });
    final text = _feedbackController.text.trim();
    final ok = await ReviewService.submitFeedback(text, widget.streak);
    if (!mounted) return;
    if (ok || text.isEmpty) {
      // Empty submission still counts as "done" — user engaged with the form.
      await ReviewService.markCompleted();
      setState(() => _step = _Step.done);
    } else {
      setState(() { _submitting = false; _submitFailed = true; });
    }
  }

  // ── Step 3: Thank-you ──────────────────────────────────────────────────────

  Widget _buildDone() {
    // Auto-dismiss after 2 seconds.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });

    return Column(
      key: const ValueKey('done'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        _GoldCircleIcon(icon: Icons.check_rounded),
        const SizedBox(height: 16),
        Text(
          'JazakAllah Khair 🤍',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your feedback helps us improve the app for the entire community.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: _subtitleColor),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────────

class _GoldCircleIcon extends StatelessWidget {
  final IconData icon;
  const _GoldCircleIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Icon(icon, color: AppColors.gold, size: 26),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _SecondaryButton(
      {required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
