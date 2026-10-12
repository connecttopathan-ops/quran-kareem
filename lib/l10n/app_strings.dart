import 'dart:ui' show Locale;

import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'ui_locales.dart';

/// Resolves the app's localisations without a `BuildContext`.
///
/// Services sit outside the widget tree, so `L.of(context)` is unavailable to
/// them. This loads the same bundle from the stored interface-language
/// preference instead.
///
/// Worth knowing about notification copy specifically: a scheduled
/// notification's title and body are fixed when `zonedSchedule` is called, not
/// when it fires. So this runs on the main isolate at scheduling time, and the
/// text a user eventually sees is in whatever language was active when it was
/// scheduled. HomeScreen reschedules on every launch and resume, so a language
/// change catches up almost immediately — but a notification already sitting in
/// the OS queue keeps its old language until then.
Future<L> loadAppStrings() async {
  // `L.delegate.load` rather than the generated lookup function: the delegate
  // is the same object MaterialApp already uses, so this cannot drift from
  // what the widget tree resolves.
  return L.delegate.load(Locale(await currentLanguageCode()));
}

/// The interface language code currently in force, resolved the same way
/// [loadAppStrings] resolves it.
///
/// Services need this separately because some content — the curated ayahs,
/// the Names, the duas — keeps its own per-language maps rather than living
/// in the generated localisations, so a bare `L` is not enough to read it.
Future<String> currentLanguageCode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('uiLangCode') ?? kSystemUiLocale;
  return (stored == kSystemUiLocale || !isSupportedUiLocale(stored))
      ? detectUiLocale()
      : stored;
}

/// Turns an internal prayer identifier into its display name.
///
/// Prayer names do double duty in this app: they key the prayer-time maps and
/// drive scheduling logic, *and* they are shown to the user. Translating them
/// in place would break the lookups, so the English identifier stays and this
/// converts it only at the point of display.
///
/// [identifier] is one of Fajr, Dhuhr, Asr, Maghrib, Isha or Jumu'ah. Anything
/// unrecognised is returned unchanged, so a new prayer key shows up in English
/// rather than as an empty label.
String prayerDisplayName(L l, String identifier) {
  switch (identifier) {
    case 'Fajr':
      return l.prayerFajr;
    case 'Dhuhr':
      return l.prayerDhuhr;
    case 'Asr':
      return l.prayerAsr;
    case 'Maghrib':
      return l.prayerMaghrib;
    case 'Isha':
      return l.prayerIsha;
    case "Jumu'ah":
      return l.prayerJumuah;
    default:
      return identifier;
  }
}

/// Display name for a prayer-time calculation method, by its stored id.
///
/// The ids are persisted in SharedPreferences and passed to the adhan library,
/// so they must stay exactly as they are; only the label moves.
String calcMethodName(L l, String id) {
  switch (id) {
    case 'MWL':
      return l.calcMethodMwl;
    case 'ISNA':
      return l.calcMethodIsna;
    case 'Egyptian':
      return l.calcMethodEgyptian;
    case 'Karachi':
      return l.calcMethodKarachi;
    case 'UmmAlQura':
      return l.calcMethodUmmAlQura;
    case 'Dubai':
      return l.calcMethodDubai;
    case 'Kuwait':
      return l.calcMethodKuwait;
    case 'Qatar':
      return l.calcMethodQatar;
    case 'Singapore':
      return l.calcMethodSingapore;
    case 'Tehran':
      return l.calcMethodTehran;
    default:
      return id;
  }
}
