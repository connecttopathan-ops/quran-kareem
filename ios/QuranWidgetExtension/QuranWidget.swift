import WidgetKit
import SwiftUI

// BEGIN GENERATED — from lib/l10n/app_*.arb via gen_widget_strings.py.
// Do not edit by hand; regenerate so the widget cannot drift from the app.
enum WidgetStrings {
    private static let table: [String: [String: String]] = [
        "widget_prayer_times": ["en": "Prayer Times", "fr": "Horaires de prière", "es": "Horarios de oración", "it": "Orari di preghiera", "de": "Gebetszeiten", "pt": "Horários de oração"],
        "widget_next_prayer": ["en": "Next Prayer", "fr": "Prochaine prière", "es": "Próxima oración", "it": "Prossima preghiera", "de": "Nächstes Gebet", "pt": "Próxima oração"],
        "widget_next": ["en": "Next", "fr": "Prochaine", "es": "Siguiente", "it": "Prossima", "de": "Nächstes", "pt": "Próxima"],
        "widget_qibla": ["en": "Qibla", "fr": "Qibla", "es": "Quibla", "it": "Qibla", "de": "Qibla", "pt": "Qibla"],
        "widget_open_app": ["en": "Open app", "fr": "Ouvrir l'app", "es": "Abrir la app", "it": "Apri l'app", "de": "App öffnen", "pt": "Abrir a app"],
        "widget_prayer_fajr": ["en": "Fajr", "fr": "Fajr", "es": "Fajr", "it": "Fajr", "de": "Fajr", "pt": "Fajr"],
        "widget_prayer_dhuhr": ["en": "Dhuhr", "fr": "Dhuhr", "es": "Dhuhr", "it": "Dhuhr", "de": "Dhuhr", "pt": "Dhuhr"],
        "widget_prayer_asr": ["en": "Asr", "fr": "Asr", "es": "Asr", "it": "Asr", "de": "Asr", "pt": "Asr"],
        "widget_prayer_maghrib": ["en": "Maghrib", "fr": "Maghrib", "es": "Maghrib", "it": "Maghrib", "de": "Maghrib", "pt": "Maghrib"],
        "widget_prayer_isha": ["en": "Isha", "fr": "Isha", "es": "Isha", "it": "Iscià", "de": "Ischa", "pt": "Ishá"],
        "widget_hijri_month_1": ["en": "Muharram", "fr": "Mouharram", "es": "Muharram", "it": "Muharram", "de": "Muharram", "pt": "Muharram"],
        "widget_hijri_month_2": ["en": "Safar", "fr": "Safar", "es": "Safar", "it": "Safar", "de": "Safar", "pt": "Safar"],
        "widget_hijri_month_3": ["en": "Rabi' al-Awwal", "fr": "Rabi' al-Awwal", "es": "Rabi' al-Awwal", "it": "Rabi' al-Awwal", "de": "Rabi' al-Awwal", "pt": "Rabi' al-Awwal"],
        "widget_hijri_month_4": ["en": "Rabi' al-Thani", "fr": "Rabi' al-Thani", "es": "Rabi' al-Thani", "it": "Rabi' al-Thani", "de": "Rabi' al-Thani", "pt": "Rabi' al-Thani"],
        "widget_hijri_month_5": ["en": "Jumada al-Awwal", "fr": "Joumada al-Awwal", "es": "Yumada al-Awwal", "it": "Jumada al-Awwal", "de": "Jumada al-Awwal", "pt": "Jumada al-Awwal"],
        "widget_hijri_month_6": ["en": "Jumada al-Thani", "fr": "Joumada al-Thani", "es": "Yumada al-Thani", "it": "Jumada al-Thani", "de": "Jumada al-Thani", "pt": "Jumada al-Thani"],
        "widget_hijri_month_7": ["en": "Rajab", "fr": "Rajab", "es": "Rayab", "it": "Rajab", "de": "Rajab", "pt": "Rajab"],
        "widget_hijri_month_8": ["en": "Sha'ban", "fr": "Cha'ban", "es": "Sha'bán", "it": "Sha'ban", "de": "Scha'ban", "pt": "Sha'ban"],
        "widget_hijri_month_9": ["en": "Ramadan", "fr": "Ramadan", "es": "Ramadán", "it": "Ramadan", "de": "Ramadan", "pt": "Ramadão"],
        "widget_hijri_month_10": ["en": "Shawwal", "fr": "Chawwal", "es": "Shawwal", "it": "Shawwal", "de": "Schawwal", "pt": "Shawwal"],
        "widget_hijri_month_11": ["en": "Dhu al-Qi'dah", "fr": "Dhou al-Qi'dah", "es": "Dhu al-Qi'dah", "it": "Dhu al-Qi'dah", "de": "Dhu al-Qi'dah", "pt": "Dhu al-Qi'dah"],
        "widget_hijri_month_12": ["en": "Dhu al-Hijjah", "fr": "Dhou al-Hijjah", "es": "Dhu al-Hiyyah", "it": "Dhu al-Hijjah", "de": "Dhu al-Hijjah", "pt": "Dhu al-Hijjah"],
        "widget_qibla_title": ["en": "Qibla Direction", "fr": "Direction de la Qibla", "es": "Dirección de la quibla", "it": "Direzione della qibla", "de": "Qibla-Richtung", "pt": "Direção da Qibla"],
        "widget_desc_next": ["en": "Shows the next upcoming prayer time.", "fr": "Affiche la prochaine prière.", "es": "Muestra la próxima oración.", "it": "Mostra la prossima preghiera.", "de": "Zeigt das nächste Gebet.", "pt": "Mostra a próxima oração."],
        "widget_desc_all": ["en": "Shows all 5 daily prayer times.", "fr": "Affiche les 5 prières du jour.", "es": "Muestra las 5 oraciones diarias.", "it": "Mostra le 5 preghiere del giorno.", "de": "Zeigt alle 5 Gebetszeiten.", "pt": "Mostra as 5 orações diárias."],
        "widget_desc_large": ["en": "Shows all 5 daily prayer times with next prayer highlight.", "fr": "Affiche les 5 prières, la suivante mise en avant.", "es": "Muestra las 5 oraciones, destacando la siguiente.", "it": "Mostra le 5 preghiere, evidenziando la prossima.", "de": "Zeigt alle 5 Gebetszeiten, das nächste hervorgehoben.", "pt": "Mostra as 5 orações, destacando a próxima."],
        "widget_desc_qibla": ["en": "Shows the direction to the Kaaba.", "fr": "Indique la direction de la Kaaba.", "es": "Indica la dirección de la Kaaba.", "it": "Indica la direzione della Kaaba.", "de": "Zeigt die Richtung zur Kaaba.", "pt": "Indica a direção da Caaba."],
        "widget_title_large": ["en": "Prayer Times (Large)", "fr": "Horaires de prière (grand)", "es": "Horarios de oración (grande)", "it": "Orari di preghiera (grande)", "de": "Gebetszeiten (groß)", "pt": "Horários de oração (grande)"],
    ]
    private static let dateFormats: [String: String] = ["en": "%1$s %2$s %3$s AH", "fr": "%1$s %2$s %3$s H", "es": "%1$s de %2$s de %3$s H", "it": "%1$s %2$s %3$s H", "de": "%1$s. %2$s %3$s AH", "pt": "%1$s de %2$s de %3$s H"]

    /// Two-letter code of the device language, falling back to English.
    private static var lang: String {
        let first = Locale.preferredLanguages.first ?? "en"
        return String(first.prefix(2)).lowercased()
    }

    static func t(_ key: String) -> String {
        guard let row = table[key] else { return key }
        return row[lang] ?? row["en"] ?? key
    }

    /// Localised name for a prayer, from the English identifier the app
    /// stores. The identifier is sent rather than a translated name because
    /// a widget can be added before the app has ever run.
    static func prayer(_ id: String) -> String {
        switch id {
        case "Fajr":    return t("widget_prayer_fajr")
        case "Dhuhr":   return t("widget_prayer_dhuhr")
        case "Asr":     return t("widget_prayer_asr")
        case "Maghrib": return t("widget_prayer_maghrib")
        case "Isha":    return t("widget_prayer_isha")
        default:        return id
        }
    }

    /// Hijri date built from parts, so each language can order day, month and
    /// year its own way. Falls back to the pre-formatted English string an
    /// older build wrote, so the widget survives an app upgrade.
    static func hijri(day: String, month: String, year: String,
                      fallback: String) -> String {
        guard !day.isEmpty, !year.isEmpty,
              let m = Int(month), (1...12).contains(m) else { return fallback }
        let name = t("widget_hijri_month_\(m)")
        let fmt = dateFormats[lang] ?? dateFormats["en"]!
        return fmt
            .replacingOccurrences(of: "%1$s", with: day)
            .replacingOccurrences(of: "%2$s", with: name)
            .replacingOccurrences(of: "%3$s", with: year)
    }
}
// END GENERATED


// MARK: - iOS 17 containerBackground compatibility

extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}

// MARK: - Shared Data

private let appGroup = "group.co.getquran.app"

struct PrayerData {
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let city: String
    let hijri: String
    let nextPrayer: String

    static func load() -> PrayerData {
        let defaults = UserDefaults(suiteName: appGroup)
        func str(_ key: String, _ fallback: String = "--") -> String {
            defaults?.string(forKey: key) ?? fallback
        }
        return PrayerData(
            fajr:       str("widget_fajr"),
            dhuhr:      str("widget_dhuhr"),
            asr:        str("widget_asr"),
            maghrib:    str("widget_maghrib"),
            isha:       str("widget_isha"),
            city:       str("widget_city", ""),
            // Built here from parts so the date reads in the device's
            // language and order; falls back to the English string an older
            // build wrote, so the widget survives an app upgrade.
            hijri:      WidgetStrings.hijri(
                            day:      str("widget_hijri_day", ""),
                            month:    str("widget_hijri_month", ""),
                            year:     str("widget_hijri_year", ""),
                            fallback: str("widget_hijri", "")),
            nextPrayer: str("widget_next_prayer", "")
        )
    }

    var nextPrayerTime: String {
        switch nextPrayer {
        case "Fajr":    return fajr
        case "Dhuhr":   return dhuhr
        case "Asr":     return asr
        case "Maghrib": return maghrib
        case "Isha":    return isha
        default:        return "--:--"
        }
    }
}

struct QiblaData {
    let degrees: Double?
    let city: String

    static func load() -> QiblaData {
        let defaults = UserDefaults(suiteName: appGroup)
        let deg = defaults?.double(forKey: "widget_qibla_degrees")
        let hasValue = defaults?.object(forKey: "widget_qibla_degrees") != nil
        return QiblaData(
            degrees: hasValue ? deg : nil,
            city: defaults?.string(forKey: "widget_city") ?? ""
        )
    }
}

// MARK: - Colors

extension Color {
    static let widgetGold   = Color(red: 0.788, green: 0.659, blue: 0.298)
    static let widgetBg     = Color(red: 0.110, green: 0.078, blue: 0.027)
    static let widgetDim    = Color(red: 0.604, green: 0.502, blue: 0.376)
    static let widgetCream  = Color(red: 0.961, green: 0.925, blue: 0.843)
}

// MARK: - Timeline Provider

struct PrayerEntry: TimelineEntry {
    let date: Date
    let prayer: PrayerData
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), prayer: PrayerData(
            fajr: "5:23", dhuhr: "12:45", asr: "3:58",
            maghrib: "6:32", isha: "8:01",
            city: WidgetStrings.t("widget_prayer_times"),
            hijri: WidgetStrings.hijri(day: "1", month: "9", year: "1446",
                                       fallback: "1 Ramadan 1446"),
            nextPrayer: "Dhuhr"
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(PrayerEntry(date: Date(), prayer: PrayerData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let entry = PrayerEntry(date: Date(), prayer: PrayerData.load())
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Qibla Timeline Provider

struct QiblaEntry: TimelineEntry {
    let date: Date
    let qibla: QiblaData
}

struct QiblaProvider: TimelineProvider {
    func placeholder(in context: Context) -> QiblaEntry {
        QiblaEntry(date: Date(), qibla: QiblaData(degrees: 45, city: WidgetStrings.t("widget_qibla")))
    }

    func getSnapshot(in context: Context, completion: @escaping (QiblaEntry) -> Void) {
        completion(QiblaEntry(date: Date(), qibla: QiblaData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QiblaEntry>) -> Void) {
        let entry = QiblaEntry(date: Date(), qibla: QiblaData.load())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Small Widget (2×1): Next prayer only

struct PrayerWidgetSmallView: View {
    let prayer: PrayerData

    var body: some View {
        ZStack {
            Color.widgetBg
            VStack(spacing: 2) {
                if !prayer.city.isEmpty {
                    Text(prayer.city)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.widgetDim)
                        .lineLimit(1)
                }
                Text(prayer.nextPrayer.isEmpty
                    ? WidgetStrings.t("widget_next_prayer")
                    : WidgetStrings.prayer(prayer.nextPrayer))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.widgetGold)
                Text(prayer.nextPrayerTime)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.widgetCream)
            }
            .padding(8)
        }
        .widgetBackground(Color.widgetBg)
    }
}

// MARK: - Medium Widget (4×2): All 5 prayers

struct PrayerWidgetMediumView: View {
    let prayer: PrayerData

    var body: some View {
        ZStack {
            Color.widgetBg
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(prayer.city.isEmpty
                        ? WidgetStrings.t("widget_prayer_times")
                        : prayer.city)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.widgetGold)
                    Spacer()
                    Text(prayer.hijri)
                        .font(.system(size: 10))
                        .foregroundColor(.widgetDim)
                        .lineLimit(1)
                }
                Divider().background(Color.widgetDim.opacity(0.4))
                let prayers: [(String, String)] = [
                    (WidgetStrings.t("widget_prayer_fajr"),    prayer.fajr),
                    (WidgetStrings.t("widget_prayer_dhuhr"),   prayer.dhuhr),
                    (WidgetStrings.t("widget_prayer_asr"),     prayer.asr),
                    (WidgetStrings.t("widget_prayer_maghrib"), prayer.maghrib),
                    (WidgetStrings.t("widget_prayer_isha"),    prayer.isha),
                ]
                ForEach(prayers, id: \.0) { name, time in
                    let isCurrent = name == prayer.nextPrayer
                    HStack {
                        Text(name)
                            .font(.system(size: 12, weight: isCurrent ? .semibold : .regular))
                            .foregroundColor(isCurrent ? .widgetGold : .widgetDim)
                        Spacer()
                        Text(time)
                            .font(.system(size: 12, weight: isCurrent ? .semibold : .regular, design: .monospaced))
                            .foregroundColor(isCurrent ? .widgetGold : .widgetCream)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isCurrent ? Color.widgetGold.opacity(0.12) : Color.clear)
                    .cornerRadius(4)
                }
            }
            .padding(10)
        }
        .widgetBackground(Color.widgetBg)
    }
}

// MARK: - Large Widget (4×3 or extra-large): All prayers + next prayer highlight

struct PrayerWidgetLargeView: View {
    let prayer: PrayerData

    var body: some View {
        ZStack {
            Color.widgetBg
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prayer.city.isEmpty
                        ? WidgetStrings.t("widget_prayer_times")
                        : prayer.city)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.widgetGold)
                        Text(prayer.hijri)
                            .font(.system(size: 11))
                            .foregroundColor(.widgetDim)
                    }
                    Spacer()
                    // Next prayer badge
                    if !prayer.nextPrayer.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(WidgetStrings.t("widget_next"))
                                .font(.system(size: 10))
                                .foregroundColor(.widgetDim)
                            Text(prayer.nextPrayer)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.widgetGold)
                            Text(prayer.nextPrayerTime)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.widgetCream)
                        }
                    }
                }
                Divider().background(Color.widgetDim.opacity(0.4))

                let prayers: [(String, String)] = [
                    (WidgetStrings.t("widget_prayer_fajr"),    prayer.fajr),
                    (WidgetStrings.t("widget_prayer_dhuhr"),   prayer.dhuhr),
                    (WidgetStrings.t("widget_prayer_asr"),     prayer.asr),
                    (WidgetStrings.t("widget_prayer_maghrib"), prayer.maghrib),
                    (WidgetStrings.t("widget_prayer_isha"),    prayer.isha),
                ]
                ForEach(prayers, id: \.0) { name, time in
                    let isCurrent = name == prayer.nextPrayer
                    HStack {
                        Text(name)
                            .font(.system(size: 14, weight: isCurrent ? .semibold : .regular))
                            .foregroundColor(isCurrent ? .widgetGold : .widgetDim)
                        Spacer()
                        Text(time)
                            .font(.system(size: 14, weight: isCurrent ? .semibold : .regular, design: .monospaced))
                            .foregroundColor(isCurrent ? .widgetGold : .widgetCream)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isCurrent ? Color.widgetGold.opacity(0.15) : Color.clear)
                    .cornerRadius(6)
                }
            }
            .padding(12)
        }
        .widgetBackground(Color.widgetBg)
    }
}

// MARK: - Qibla Widget

struct QiblaWidgetView: View {
    let qibla: QiblaData

    var body: some View {
        ZStack {
            Color.widgetBg
            VStack(spacing: 4) {
                if let degrees = qibla.degrees {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.widgetGold)
                        .rotationEffect(.degrees(degrees))
                    Text("\(Int(degrees.rounded()))°")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.widgetCream)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.widgetDim)
                    Text(WidgetStrings.t("widget_open_app"))
                        .font(.system(size: 12))
                        .foregroundColor(.widgetDim)
                }
                Text(WidgetStrings.t("widget_qibla"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.widgetGold)
                if !qibla.city.isEmpty {
                    Text(qibla.city)
                        .font(.system(size: 10))
                        .foregroundColor(.widgetDim)
                        .lineLimit(1)
                }
            }
            .padding(8)
        }
        .widgetBackground(Color.widgetBg)
    }
}

// MARK: - Widget Definitions

struct PrayerTimesWidget: Widget {
    let kind = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetSmallView(prayer: entry.prayer)
        }
        .configurationDisplayName(WidgetStrings.t("widget_prayer_times"))
        .description(WidgetStrings.t("widget_desc_next"))
        .supportedFamilies([.systemSmall])
    }
}

struct PrayerTimesMediumWidget: Widget {
    let kind = "PrayerTimesMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetMediumView(prayer: entry.prayer)
        }
        .configurationDisplayName(WidgetStrings.t("widget_prayer_times"))
        .description(WidgetStrings.t("widget_desc_all"))
        .supportedFamilies([.systemMedium])
    }
}

struct PrayerTimesLargeWidget: Widget {
    let kind = "PrayerTimesLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetLargeView(prayer: entry.prayer)
        }
        .configurationDisplayName(WidgetStrings.t("widget_title_large"))
        .description(WidgetStrings.t("widget_desc_large"))
        .supportedFamilies([.systemLarge])
    }
}

struct QiblaWidget: Widget {
    let kind = "QiblaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QiblaProvider()) { entry in
            QiblaWidgetView(qibla: entry.qibla)
        }
        .configurationDisplayName(WidgetStrings.t("widget_qibla_title"))
        .description(WidgetStrings.t("widget_desc_qibla"))
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Widget Bundle

@main
struct QuranWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        PrayerTimesMediumWidget()
        PrayerTimesLargeWidget()
        QiblaWidget()
    }
}
