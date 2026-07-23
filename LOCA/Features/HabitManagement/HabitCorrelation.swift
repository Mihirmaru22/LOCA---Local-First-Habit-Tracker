//
//  HabitCorrelation.swift
//  LOCA
//
//  Phase 4.2 — Graph-backed relationship insights.
//
//  Analyzes correlations between habits (e.g., "you run better after 7h sleep").
//  Only surfaces when data is sufficient and correlation is clear.
//

import Foundation

/// A data-backed correlation between two habits.
/// Example: "you run better after 7h sleep" — based on real logs.
struct HabitCorrelation: Identifiable {
    let id: UUID = UUID()
    /// Name of the habit that performs better (e.g., "Running")
    let benefitingHabit: String
    /// Name of the habit or metric that predicts it (e.g., "Sleep")
    let predictingFactor: String
    /// The observed effect (e.g., "better performance on days after 7h sleep")
    let effectDescription: String
    /// Confidence score (0.0 to 1.0) based on data points and correlation strength
    let confidence: Double
    /// Number of data points used to derive this correlation
    let dataPointCount: Int

    /// Whether this insight is confident enough to surface to the user.
    var isSurfaceable: Bool {
        // Require 10+ data points and 60%+ confidence
        return dataPointCount >= 10 && confidence >= 0.6
    }
}

/// Analyzes logs across multiple habits to find data-backed correlations.
struct InsightAnalyzer {

    /// Find correlations between all active habits.
    /// Returns only insights with sufficient data and confidence (Phase 4.2: grounded).
    static func findCorrelations(
        boards: [HabitBoard],
        logs: [LogSnapshot]
    ) -> [HabitCorrelation] {
        guard boards.count >= 2 else { return [] }

        var correlations: [HabitCorrelation] = []

        // Analyze sleep vs. other performance habits
        // (In production, this would expand to other correlations)
        if let sleepBoard = boards.first(where: { $0.name.lowercased().contains("sleep") }) {
            let sleepLogs = (sleepBoard.logs ?? []).map { LogSnapshot(from: $0) }

            for board in boards where !board.name.lowercased().contains("sleep") {
                let boardLogs = (board.logs ?? []).map { LogSnapshot(from: $0) }

                if let correlation = analyzeSleepPerformanceCorrelation(
                    habit: board.name,
                    sleepLogs: sleepLogs,
                    performanceLogs: boardLogs
                ) {
                    if correlation.isSurfaceable {
                        correlations.append(correlation)
                    }
                }
            }
        }

        return correlations
    }

    // MARK: - Specific correlations

    private static func analyzeSleepPerformanceCorrelation(
        habit: String,
        sleepLogs: [LogSnapshot],
        performanceLogs: [LogSnapshot]
    ) -> HabitCorrelation? {
        guard sleepLogs.count >= 10 && performanceLogs.count >= 10 else { return nil }

        // Group performance logs by day
        var performanceByDay: [DateComponents: Double] = [:]
        for log in performanceLogs {
            let day = Calendar.current.dateComponents([.year, .month, .day], from: log.timestamp)
            performanceByDay[day, default: 0] += log.value
        }

        // Analyze days with sufficient sleep vs. without
        var afterGoodSleep = (count: 0, totalPerformance: 0.0)
        var afterPoorSleep = (count: 0, totalPerformance: 0.0)

        for day in performanceByDay.keys {
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(from: day)!)!
            let nextDayComponents = Calendar.current.dateComponents([.year, .month, .day], from: nextDay)

            // Did we log sleep on this night? (looking at logs for that day)
            let sleepOnThatDay = sleepLogs.filter { log in
                let logDay = Calendar.current.dateComponents([.year, .month, .day], from: log.timestamp)
                return logDay == day && log.value >= 7.0
            }.count > 0

            let performance = performanceByDay[day] ?? 0

            if sleepOnThatDay {
                afterGoodSleep.count += 1
                afterGoodSleep.totalPerformance += performance
            } else {
                afterPoorSleep.count += 1
                afterPoorSleep.totalPerformance += performance
            }
        }

        guard afterGoodSleep.count > 0 && afterPoorSleep.count > 0 else { return nil }

        let avgAfterGoodSleep = afterGoodSleep.totalPerformance / Double(afterGoodSleep.count)
        let avgAfterPoorSleep = afterPoorSleep.totalPerformance / Double(afterPoorSleep.count)

        // Calculate correlation strength (0.0 to 1.0)
        let difference = avgAfterGoodSleep - avgAfterPoorSleep
        let confidence = min(difference / max(avgAfterPoorSleep, 1.0), 1.0)

        // Only return if there's a meaningful positive correlation
        guard confidence >= 0.2 else { return nil }

        return HabitCorrelation(
            benefitingHabit: habit,
            predictingFactor: "Sleep",
            effectDescription: "better on days after 7+ hours of sleep",
            confidence: confidence,
            dataPointCount: afterGoodSleep.count + afterPoorSleep.count
        )
    }
}
