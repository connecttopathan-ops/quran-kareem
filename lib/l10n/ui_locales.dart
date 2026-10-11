import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

/// The languages the app's own interface is translated into.
///
/// Deliberately separate from `kLanguages` in `models/language.dart`, which
/// lists the 46 languages a *Quran translation* is available in. The two are
/// independent settings: someone may well read an Urdu translation with an
/// English interface.
class UiLocale {
  final String code;

  /// Shown in the picker, in the language itself — a French speaker scanning
  /// the list looks for "Français", not "French".
  final String nativeName;

  /// Shown underneath, in English, so the list stays navigable to someone who
  /// picked the wrong language by accident and needs to find their way back.
  final String englishName;

  const UiLocale(this.code, this.nativeName, this.englishName);
}

/// Only languages with a translation bundle belong here.
///
/// `supportedLocales` is generated from whichever `app_*.arb` files exist, so
/// listing a language without one lets the user pick it and then silently get
/// English — a worse outcome than not offering it, because nothing on screen
/// explains why their choice did nothing.
///
/// Chinese and Japanese are deferred: re-add a line here when `app_zh.arb` and
/// `app_ja.arb` land. Until then `resolveUiLocale` maps those devices to
/// English, which is the honest fallback.
const List<UiLocale> kUiLocales = [
  UiLocale('en', 'English', 'English'),
  UiLocale('fr', 'Français', 'French'),
  UiLocale('es', 'Español', 'Spanish'),
  UiLocale('it', 'Italiano', 'Italian'),
  UiLocale('de', 'Deutsch', 'German'),
  UiLocale('pt', 'Português', 'Portuguese'),
];

const String kDefaultUiLocale = 'en';

/// Stored in place of a language code to mean "whatever the phone is set to".
///
/// Kept as a stored value rather than an absent key so that following the
/// device stays a deliberate choice: someone who travels, or who switches their
/// phone to another language, gets the app to follow along without having to
/// remember they once picked a fixed language here.
const String kSystemUiLocale = 'system';

/// True when [code] is one of the interface languages we ship.
bool isSupportedUiLocale(String code) =>
    kUiLocales.any((l) => l.code == code);

/// Picks the interface language from the device's own locale.
///
/// Only used the first time the app runs; once the user has chosen explicitly,
/// their choice is read from SharedPreferences and this is not consulted again.
///
/// Script and region subtags are ignored on purpose: `pt-BR` and `pt-PT` both
/// map to `pt`, `zh-Hans` and `zh-Hant` both to `zh`. Shipping regional
/// variants is a later decision, and until then the base language is a far
/// better guess than falling through to English.
///
/// Anything we do not translate falls back to English rather than to the
/// nearest neighbour — a half-familiar language is more disorienting than a
/// lingua franca.
/// Reads `PlatformDispatcher.instance` rather than
/// `WidgetsBinding.instance.platformDispatcher`: the former needs no binding,
/// so this is also safe to call from services that run before — or outside —
/// the widget tree.
String detectUiLocale() {
  return resolveUiLocale(PlatformDispatcher.instance.locale.languageCode);
}

/// The [detectUiLocale] mapping, split out so it can be unit tested without a
/// binding and reused anywhere a raw language code needs resolving.
@visibleForTesting
String resolveUiLocale(String languageCode) {
  final lang = languageCode.toLowerCase();

  if (isSupportedUiLocale(lang)) return lang;

  // Legacy and alias codes some devices still report.
  switch (lang) {
    case 'in': // pre-1989 Indonesian code — not one of ours, but seen in the wild
      return kDefaultUiLocale;
    case 'iw': // pre-1989 Hebrew code
      return kDefaultUiLocale;
    // 'cmn' (Mandarin) and 'yue' (Cantonese) mapped to 'zh' here until Chinese
    // is translated. Restore that mapping alongside app_zh.arb; routing them
    // to an unshipped locale now would only take the English fallback by a
    // longer road.
    case 'gl': // Galician — mutually intelligible with Portuguese
      return 'pt';
    default:
      return kDefaultUiLocale;
  }
}
