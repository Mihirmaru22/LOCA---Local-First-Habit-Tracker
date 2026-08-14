import WidgetKit
import SwiftUI

// MARK: - MementoMoriEntry (Current Year Progress & 365/366 Day Matrix)

struct MementoMoriEntry: TimelineEntry {
    let date: Date
    let currentYear: Int
    let totalDaysInYear: Int
    let dayOfYear: Int
    let daysDone: Int
    let daysLeft: Int
    let percentageElapsed: Double
    let currentAge: Int
    let targetLifespan: Int
}

// MARK: - MementoMoriProvider

struct MementoMoriProvider: TimelineProvider {
    func placeholder(in context: Context) -> MementoMoriEntry {
        MementoMoriEntry(
            date: .now,
            currentYear: 2026,
            totalDaysInYear: 365,
            dayOfYear: 226,
            daysDone: 226,
            daysLeft: 139,
            percentageElapsed: 61.9,
            currentAge: 26,
            targetLifespan: 90
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MementoMoriEntry) -> Void) {
        completion(calculateEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MementoMoriEntry>) -> Void) {
        let entry = calculateEntry()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }

    private func calculateEntry() -> MementoMoriEntry {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let currentYear = cal.component(.year, from: today)

        let dayOfYear = cal.ordinality(of: .day, in: .year, for: today) ?? 1
        let totalDays = cal.range(of: .day, in: .year, for: today)?.count ?? 365
        let daysDone = dayOfYear
        let daysLeft = max(0, totalDays - dayOfYear)
        let pct = (Double(daysDone) / Double(totalDays)) * 100.0

        let birthYear = UserDefaults.standard.integer(forKey: "user_birth_year")
        let actualBirth = birthYear > 1900 ? birthYear : 2000
        let age = max(1, currentYear - actualBirth)

        return MementoMoriEntry(
            date: .now,
            currentYear: currentYear,
            totalDaysInYear: totalDays,
            dayOfYear: dayOfYear,
            daysDone: daysDone,
            daysLeft: daysLeft,
            percentageElapsed: pct,
            currentAge: age,
            targetLifespan: 90
        )
    }
}

// MARK: - MementoMoriWidget

struct MementoMoriWidget: Widget {
    static let kind = "com.mihirmaru.loca.MementoMoriWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: MementoMoriProvider()) { entry in
            MementoMoriWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Memento Mori · Year Progress")
        .description("Current year progress (365/366 days elapsed vs remaining) and lifetime perspective.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - MementoMoriWidgetView

struct MementoMoriWidgetView: View {
    let entry: MementoMoriEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header Row
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 10, weight: .bold))
                    Text("YEAR \(String(entry.currentYear))")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.6)
                }
                .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 3) {
                    Text("\(entry.daysLeft)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("days left")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.12), in: Capsule())
            }

            Divider()

            // Main Metrics
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("Day \(entry.daysDone)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.primary)

                Text("of \(entry.totalDaysInYear) (\(String(format: "%.1f", entry.percentageElapsed))%)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Age \(entry.currentAge) / \(entry.targetLifespan)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Year Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 5)

                    let w = max(4, geo.size.width * CGFloat(entry.percentageElapsed / 100.0))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w, height: 5)
                }
            }
            .frame(height: 5)

            // 52-Week Year Day Dots Grid (365/366 Days Visualized)
            if family == .systemSmall {
                // 12 Months Mini Matrix (12 blocks)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 6), spacing: 3) {
                    ForEach(1...12, id: \.self) { month in
                        let currentMonth = Calendar.current.component(.month, from: .now)
                        let isPast = month < currentMonth
                        let isCurrent = month == currentMonth

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                isCurrent ? Color.green :
                                isPast ? Color.secondary.opacity(0.65) :
                                Color.secondary.opacity(0.2)
                            )
                            .frame(height: 10)
                    }
                }
            } else {
                // Full 52-Week Year Matrix (52 columns x 7 rows = 364/365 days)
                HStack(spacing: 2) {
                    ForEach(1...52, id: \.self) { week in
                        VStack(spacing: 2) {
                            ForEach(1...7, id: \.self) { dayInWeek in
                                let dayIndex = (week - 1) * 7 + dayInWeek
                                if dayIndex <= entry.totalDaysInYear {
                                    let isPast = dayIndex < entry.dayOfYear
                                    let isToday = dayIndex == entry.dayOfYear

                                    RoundedRectangle(cornerRadius: 0.8)
                                        .fill(
                                            isToday ? Color.green :
                                            isPast ? Color.secondary.opacity(0.6) :
                                            Color.secondary.opacity(0.18)
                                        )
                                        .frame(height: 3.5)
                                }
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Text("Time is non-renewable. Live today with total intent.")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(4)
    }
}
