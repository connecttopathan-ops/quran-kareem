import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewService {
  ReviewService._();

  // ── Configuration ────────────────────────────────────────────────────────────
  // Paste your deployed Google Apps Script URL here.
  // Extensions → Apps Script → Deploy → New deployment → Web app → Anyone.
  static const String _sheetUrl =
      'https://script.google.com/macros/s/AKfycbxMnAIZBcB2iEI9SkqacgoDUdw-M9LQbFioE_XtXn8hMNWf-zVbxC_Ui3hUqMaYzCN0/exec';

  static const String _appStoreId = 'YOUR_APP_STORE_ID';
  static const String _androidPackage = 'co.getquran.app';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=$_androidPackage';

  /// True when an App Store ID has actually been configured.
  /// While unset, iOS skips any `openStoreListing` call (which would throw
  /// with the placeholder) and relies on the native review sheet only.
  static bool get _hasAppStoreId =>
      _appStoreId.isNotEmpty && _appStoreId != 'YOUR_APP_STORE_ID';

  // Day-streak milestones that trigger a review prompt.
  static const int _firstMilestone = 2;
  static const int _secondMilestone = 14;

  // ── Trigger logic ────────────────────────────────────────────────────────────

  /// Returns true if the review prompt should be shown for [currentStreak].
  static Future<bool> shouldPrompt(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();

    // Never show again once the user has rated or submitted feedback.
    if (prefs.getBool('review_completed') ?? false) return false;

    // Respect "Remind me later" snooze.
    final snoozedUntil = prefs.getString('review_snoozed_until');
    if (snoozedUntil != null) {
      final until = DateTime.tryParse(snoozedUntil);
      if (until != null && DateTime.now().isBefore(until)) return false;
    }

    // Check milestones — each fires once.
    final shown2 = prefs.getBool('review_shown_$_firstMilestone') ?? false;
    final shown14 = prefs.getBool('review_shown_$_secondMilestone') ?? false;

    if (currentStreak >= _secondMilestone && !shown14) return true;
    if (currentStreak >= _firstMilestone && !shown2) return true;

    return false;
  }

  /// Records that the prompt was shown for [streak] so it won't show again.
  static Future<void> markShown(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    if (streak >= _secondMilestone) {
      await prefs.setBool('review_shown_$_secondMilestone', true);
    } else if (streak >= _firstMilestone) {
      await prefs.setBool('review_shown_$_firstMilestone', true);
    }
  }

  /// Marks the review flow as permanently done (user rated or sent feedback).
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('review_completed', true);
  }

  /// Snoozes the prompt for 7 days.
  static Future<void> snooze() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'review_snoozed_until',
      DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  /// Opens the store listing directly — always works for user-initiated taps.
  /// Use this from Settings; use requestNativeReview() for automatic prompts.
  static Future<void> openStorePage() async {
    if (Platform.isAndroid) {
      await launchUrl(Uri.parse(_playStoreUrl),
          mode: LaunchMode.externalApplication);
      return;
    }
    // iOS: only attempt openStoreListing when we have a real App Store ID.
    // With the placeholder it throws — fall through to the native review sheet
    // which can still nudge the user.
    if (_hasAppStoreId) {
      await InAppReview.instance.openStoreListing(appStoreId: _appStoreId);
      return;
    }
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    }
  }

  /// Triggers the native Play Store / App Store review sheet.
  /// Falls back to openStoreListing, then a direct URL open as last resort.
  static Future<void> requestNativeReview() async {
    final review = InAppReview.instance;
    bool handled = false;

    try {
      if (await review.isAvailable()) {
        await review.requestReview();
        handled = true;
      }
    } catch (e) {
      debugPrint('[ReviewService] requestReview failed: $e');
    }

    if (!handled) {
      // openStoreListing on iOS requires a real App Store ID; with the
      // placeholder it throws. Skip it on iOS until the ID is set.
      if (Platform.isAndroid || _hasAppStoreId) {
        try {
          await review.openStoreListing(appStoreId: _appStoreId);
          handled = true;
        } catch (e) {
          debugPrint('[ReviewService] openStoreListing failed: $e');
        }
      }
    }

    if (!handled && Platform.isAndroid) {
      await launchUrl(Uri.parse(_playStoreUrl),
          mode: LaunchMode.externalApplication);
    }

    await markCompleted();
  }

  /// POSTs [feedback] to the Google Sheets Apps Script endpoint.
  /// Returns true on success, false on failure (no throw).
  static Future<bool> submitFeedback(String feedback, int streak) async {
    if (_sheetUrl == 'YOUR_APPS_SCRIPT_URL') {
      debugPrint('[ReviewService] sheet URL not configured — feedback not sent');
      return false;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('cityName') ?? '';
      final language = prefs.getString('langCode') ?? 'en';

      final response = await http
          .post(
            Uri.parse(_sheetUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'feedback': feedback,
              'streak': streak,
              'platform': Platform.isAndroid ? 'android' : 'ios',
              'date': DateTime.now().toIso8601String(),
              'city': city,
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final ok = response.statusCode >= 200 && response.statusCode < 400;
      if (!ok) {
        debugPrint('[ReviewService] sheet POST returned ${response.statusCode}');
      }
      return ok;
    } catch (e) {
      debugPrint('[ReviewService] feedback submission failed: $e');
      return false;
    }
  }
}
