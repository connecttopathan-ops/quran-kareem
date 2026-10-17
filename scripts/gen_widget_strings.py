"""Generate Android widget string resources from the ARB files.

The widget cannot read the generated L class, so its text has to live in
Android string resources. Generating them from the ARB rather than
translating separately means the widget and the app cannot drift — a
correction to a prayer name or a Hijri month lands in both.

Re-run this after changing any of the source keys.
"""
import json
import os
import xml.sax.saxutils as sx

ARB = '/home/user/quran-kareem/lib/l10n'
RES = '/home/user/quran-kareem/android/app/src/main/res'
LANGS = ['en', 'fr', 'es', 'it', 'de', 'pt']

# widget string name -> ARB key
FROM_ARB = {
    'widget_prayer_times': 'prayerTimes',
    'widget_next_prayer': 'widgetNextPrayer',
    'widget_next': 'widgetNext',
    'widget_qibla': 'quickQibla',
    'widget_open_app': 'widgetOpenApp',
    'widget_prayer_fajr': 'prayerFajr',
    'widget_prayer_dhuhr': 'prayerDhuhr',
    'widget_prayer_asr': 'prayerAsr',
    'widget_prayer_maghrib': 'prayerMaghrib',
    'widget_prayer_isha': 'prayerIsha',
}
HIJRI = ['hijriMonthMuharram', 'hijriMonthSafar', 'hijriMonthRabiAlAwwal',
         'hijriMonthRabiAlThani', 'hijriMonthJumadaAlAwwal',
         'hijriMonthJumadaAlThani', 'hijriMonthRajab', 'hijriMonthShaban',
         'hijriMonthRamadan', 'hijriMonthShawwal', 'hijriMonthDhuAlQidah',
         'hijriMonthDhuAlHijjah']
for i, k in enumerate(HIJRI, start=1):
    FROM_ARB[f'widget_hijri_month_{i}'] = k

# Date order differs by language, so the pattern is translated too rather
# than hardcoded as "day month year".
HIJRI_DATE = {
    'en': '%1$s %2$s %3$s AH',
    'fr': '%1$s %2$s %3$s H',
    'es': '%1$s de %2$s de %3$s H',
    'it': '%1$s %2$s %3$s H',
    'de': '%1$s. %2$s %3$s AH',
    'pt': '%1$s de %2$s de %3$s H',
}

arb = {l: json.load(open(f'{ARB}/app_{l}.arb')) for l in LANGS}
missing = [(l, k) for l in LANGS for k in FROM_ARB.values() if k not in arb[l]]
if missing:
    raise SystemExit(f'missing ARB keys: {missing[:5]}')

for lang in LANGS:
    folder = 'values' if lang == 'en' else f'values-{lang}'
    path = f'{RES}/{folder}'
    os.makedirs(path, exist_ok=True)
    lines = [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<!-- GENERATED from lib/l10n/app_*.arb — do not edit by hand.',
        '     Regenerate with scratchpad/gen_widget_strings.py so the',
        '     home-screen widget cannot drift from the app. -->',
        '<resources>',
    ]
    for name, key in FROM_ARB.items():
        # Apostrophes must be escaped in Android resources or the build fails.
        value = sx.escape(arb[lang][key]).replace("'", r"\'")
        lines.append(f'    <string name="{name}">{value}</string>')
    lines.append(f'    <string name="widget_hijri_date">'
                 f'{HIJRI_DATE[lang]}</string>')
    lines.append('</resources>')
    out = f'{path}/widget_strings.xml'
    open(out, 'w').write('\n'.join(lines) + '\n')
    print(f'  {folder}/widget_strings.xml  '
          f'({len(FROM_ARB) + 1} strings)')

# ── iOS ─────────────────────────────────────────────────────────────────────
# Emitted into QuranWidget.swift between markers rather than as a
# Localizable.strings file: adding a resource to the widget extension means
# editing project.pbxproj, and the iOS build cannot be verified from here.
# Migrating to .strings is a tidy-up for whoever next has Xcode open.
SWIFT = '/home/user/quran-kareem/ios/QuranWidgetExtension/QuranWidget.swift'
IOS_KEYS = dict(FROM_ARB)
IOS_KEYS.update({
    'widget_qibla_title': 'qiblaTitle',
    'widget_desc_next': 'widgetDescNext',
    'widget_desc_all': 'widgetDescAll',
    'widget_desc_large': 'widgetDescLarge',
    'widget_desc_qibla': 'widgetDescQibla',
    'widget_title_large': 'widgetTitleLarge',
})


def swift_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


rows = []
for name, key in IOS_KEYS.items():
    if any(key not in arb[l] for l in LANGS):
        continue
    pairs = ', '.join(f'{swift_str(l)}: {swift_str(arb[l][key])}'
                      for l in LANGS)
    rows.append(f'        {swift_str(name)}: [{pairs}],')
for lang in LANGS:
    pass
date_rows = ', '.join(f'{swift_str(l)}: {swift_str(HIJRI_DATE[l])}'
                      for l in LANGS)

block = f'''// BEGIN GENERATED — from lib/l10n/app_*.arb via gen_widget_strings.py.
// Do not edit by hand; regenerate so the widget cannot drift from the app.
enum WidgetStrings {{
    private static let table: [String: [String: String]] = [
{chr(10).join(rows)}
    ]
    private static let dateFormats: [String: String] = [{date_rows}]

    /// Two-letter code of the device language, falling back to English.
    private static var lang: String {{
        let first = Locale.preferredLanguages.first ?? "en"
        return String(first.prefix(2)).lowercased()
    }}

    static func t(_ key: String) -> String {{
        guard let row = table[key] else {{ return key }}
        return row[lang] ?? row["en"] ?? key
    }}

    /// Localised name for a prayer, from the English identifier the app
    /// stores. The identifier is sent rather than a translated name because
    /// a widget can be added before the app has ever run.
    static func prayer(_ id: String) -> String {{
        switch id {{
        case "Fajr":    return t("widget_prayer_fajr")
        case "Dhuhr":   return t("widget_prayer_dhuhr")
        case "Asr":     return t("widget_prayer_asr")
        case "Maghrib": return t("widget_prayer_maghrib")
        case "Isha":    return t("widget_prayer_isha")
        default:        return id
        }}
    }}

    /// Hijri date built from parts, so each language can order day, month and
    /// year its own way. Falls back to the pre-formatted English string an
    /// older build wrote, so the widget survives an app upgrade.
    static func hijri(day: String, month: String, year: String,
                      fallback: String) -> String {{
        guard !day.isEmpty, !year.isEmpty,
              let m = Int(month), (1...12).contains(m) else {{ return fallback }}
        let name = t("widget_hijri_month_\\(m)")
        let fmt = dateFormats[lang] ?? dateFormats["en"]!
        return fmt
            .replacingOccurrences(of: "%1$s", with: day)
            .replacingOccurrences(of: "%2$s", with: name)
            .replacingOccurrences(of: "%3$s", with: year)
    }}
}}
// END GENERATED
'''

src = open(SWIFT).read()
if 'BEGIN GENERATED' in src:
    a = src.index('// BEGIN GENERATED')
    b = src.index('// END GENERATED') + len('// END GENERATED\n')
    src = src[:a] + block + src[b:]
else:
    # Insert after the import block.
    m = max(i for i, l in enumerate(src.split('\n')[:30])
            if l.startswith('import '))
    lines = src.split('\n')
    lines.insert(m + 1, '\n' + block)
    src = '\n'.join(lines)
open(SWIFT, 'w').write(src)
print(f'\n  QuranWidget.swift: WidgetStrings table '
      f'({len(rows)} keys x {len(LANGS)} languages)')
