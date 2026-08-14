import SwiftUI

// MARK: - MacJournalDetailColumn

/// Detail column for the Journal section.
///
/// Header:
/// - Left: Section title on top, selected date + navigation controls underneath.
/// - Right: Mode toggle [ Collect | Analyse ] when viewing Today's log.
///
/// Body: `MacJournalCollect`, `MacJournalDailyView`, or `MacJournalAnalyse`.
struct MacJournalDetailColumn: View {

    @Binding var selectedRow: JournalRow?

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var detailMode: JournalDetailMode = .collect
    @State private var showDatePicker = false

    var body: some View {
        VStack(spacing: 0) {
            journalHeader
            Divider()

            switch selectedRow {
            case .analyse:
                MacJournalAnalyse(selectedDate: selectedDate)
            default:
                switch detailMode {
                case .collect:
                    MacJournalCollect(selectedDate: selectedDate)
                case .analyse:
                    MacJournalAnalyse(selectedDate: selectedDate)
                }
            }
        }
        .onChange(of: selectedRow) { _, newRow in
            if let newRow {
                detailMode = newRow.defaultDetailMode
            }
        }
    }

    // MARK: - Header

    private var journalHeader: some View {
        HStack(alignment: .center, spacing: DS.Space.lg) {
            // Left: Title + Date Navigation underneath
            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(DS.Text.title)
                    .fontWeight(.bold)
                    .foregroundStyle(DS.Color.textPrimary)

                if selectedRow != .analyse {
                    dateNavigationRow
                } else {
                    Text("Monthly Insights & Trends")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }

            Spacer(minLength: DS.Space.md)

            // Right: Segmented Mode Toggle (Collect | Analyse) for Today's log
            if selectedRow == .todaysLog || selectedRow == nil {
                Picker("Mode", selection: $detailMode) {
                    ForEach(JournalDetailMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.background)
    }

    // MARK: - Date Navigation Row

    private var dateNavigationRow: some View {
        HStack(spacing: 6) {
            // Previous day
            Button {
                withAnimation(DS.Motion.settle) {
                    if let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                        selectedDate = Calendar.current.startOfDay(for: prev)
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.bold))
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Previous day")

            // Date Picker Popover Button
            Button {
                showDatePicker.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(dateFormattedLabel)
                        .font(DS.Text.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(DS.Color.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .help("Choose date")
            .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                JournalDatePickerPopover(
                    selectedDate: Binding(
                        get: { selectedDate },
                        set: {
                            selectedDate = Calendar.current.startOfDay(for: $0)
                            showDatePicker = false
                        }
                    )
                )
            }

            // Next day (capped at today + 365d)
            Button {
                withAnimation(DS.Motion.settle) {
                    if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                        selectedDate = Calendar.current.startOfDay(for: next)
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Next day")

            // "Jump to Today" shortcut when viewing historical/future date
            if !Calendar.current.isDateInToday(selectedDate) {
                Button {
                    withAnimation(DS.Motion.settle) {
                        selectedDate = Calendar.current.startOfDay(for: .now)
                    }
                } label: {
                    Text("Today")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Jump to today")
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var headerTitle: String {
        switch selectedRow {
        case .analyse:   return "Analyse"
        case .todaysLog: return "Today's log"
        default:         return "Journal"
        }
    }

    private var dateFormattedLabel: String {
        let cal = Calendar.current
        let f = DateFormatter()
        f.dateFormat = "EEEE · MMMM d"
        if cal.isDateInToday(selectedDate) {
            return "Today, \(f.string(from: selectedDate))"
        } else if cal.isDateInYesterday(selectedDate) {
            return "Yesterday, \(f.string(from: selectedDate))"
        } else {
            return f.string(from: selectedDate)
        }
    }
}

// MARK: - JournalDatePickerPopover

private struct JournalDatePickerPopover: View {

    @Binding var selectedDate: Date

    var body: some View {
        VStack(spacing: DS.Space.sm) {
            DatePicker(
                "Journal Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            HStack {
                Button("Today") {
                    selectedDate = Calendar.current.startOfDay(for: .now)
                }
                .buttonStyle(.borderless)
                .font(DS.Text.caption)

                Spacer()

                Button("Yesterday") {
                    if let y = Calendar.current.date(byAdding: .day, value: -1, to: .now) {
                        selectedDate = Calendar.current.startOfDay(for: y)
                    }
                }
                .buttonStyle(.borderless)
                .font(DS.Text.caption)
            }
            .padding(.horizontal, 4)
        }
        .padding(DS.Space.md)
        .frame(width: 280)
    }
}

// MARK: - Placeholder (no row selected)

struct MacJournalDetailPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Row",
            systemImage: "book.closed",
            description: Text("Choose Today's log or Analyse.")
        )
    }
}
