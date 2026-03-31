import WidgetKit
import SwiftUI

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
            hijri:      str("widget_hijri", ""),
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
            city: "Makkah", hijri: "1 Ramadan 1446",
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
        QiblaEntry(date: Date(), qibla: QiblaData(degrees: 45, city: "Makkah"))
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
                Text(prayer.nextPrayer.isEmpty ? "Prayer" : prayer.nextPrayer)
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
                    Text(prayer.city.isEmpty ? "Prayer Times" : prayer.city)
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
                    ("Fajr",    prayer.fajr),
                    ("Dhuhr",   prayer.dhuhr),
                    ("Asr",     prayer.asr),
                    ("Maghrib", prayer.maghrib),
                    ("Isha",    prayer.isha),
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
                        Text(prayer.city.isEmpty ? "Prayer Times" : prayer.city)
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
                            Text("Next")
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
                    ("Fajr",    prayer.fajr),
                    ("Dhuhr",   prayer.dhuhr),
                    ("Asr",     prayer.asr),
                    ("Maghrib", prayer.maghrib),
                    ("Isha",    prayer.isha),
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
                    Text("Open app")
                        .font(.system(size: 12))
                        .foregroundColor(.widgetDim)
                }
                Text("Qibla")
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
        .configurationDisplayName("Prayer Times")
        .description("Shows the next upcoming prayer time.")
        .supportedFamilies([.systemSmall])
    }
}

struct PrayerTimesMediumWidget: Widget {
    let kind = "PrayerTimesMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetMediumView(prayer: entry.prayer)
        }
        .configurationDisplayName("Prayer Times")
        .description("Shows all 5 daily prayer times.")
        .supportedFamilies([.systemMedium])
    }
}

struct PrayerTimesLargeWidget: Widget {
    let kind = "PrayerTimesLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetLargeView(prayer: entry.prayer)
        }
        .configurationDisplayName("Prayer Times (Large)")
        .description("Shows all 5 daily prayer times with next prayer highlight.")
        .supportedFamilies([.systemLarge])
    }
}

struct QiblaWidget: Widget {
    let kind = "QiblaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QiblaProvider()) { entry in
            QiblaWidgetView(qibla: entry.qibla)
        }
        .configurationDisplayName("Qibla Direction")
        .description("Shows the direction to the Kaaba.")
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
