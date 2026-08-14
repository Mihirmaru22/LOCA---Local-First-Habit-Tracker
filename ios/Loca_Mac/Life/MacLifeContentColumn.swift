import SwiftUI
import SwiftData

// MARK: - LifeRow

enum LifeRow: String, CaseIterable, Identifiable {
    case blueprint   = "Blueprint & Principles"
    case bucketList  = "Master Bucket List"
    case chronology  = "Life Eras & Timeline"
    case selfMastery = "Self-Mastery & Audits"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .blueprint:   return "compass.drawing"
        case .bucketList:  return "trophy.fill"
        case .chronology:  return "timeline.selection"
        case .selfMastery: return "sparkles.rectangle.stack.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .blueprint:   return "North star & life rules"
        case .bucketList:  return "Lifetime dream vault"
        case .chronology:  return "90-year horizon & eras"
        case .selfMastery: return "Weekly audits & wisdom"
        }
    }

    var correspondingVariant: LifeDesignVariant {
        switch self {
        case .blueprint:   return .life1
        case .bucketList:  return .life2
        case .chronology:  return .life3
        case .selfMastery: return .life4
        }
    }

    static func from(variant: LifeDesignVariant) -> LifeRow {
        switch variant {
        case .life1: return .blueprint
        case .life2: return .bucketList
        case .life3: return .chronology
        case .life4: return .selfMastery
        }
    }
}

// MARK: - MacLifeContentColumn

/// Middle column for the Life section in macOS 3-pane layout.
struct MacLifeContentColumn: View {

    @Binding var selectedRow: LifeRow?
    @AppStorage("mac_life_layout_v3") private var selectedVariant: LifeDesignVariant = .life1

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LIFE SUITE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
                Spacer()
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)

            Divider()

            // Navigation List with Unified Theme
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(LifeRow.allCases) { row in
                        LifeRowButton(row: row, isSelected: selectedRow == row) {
                            selectedRow = row
                            Haptics.selection()
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Life")
        .onChange(of: selectedRow) { _, newRow in
            if let newRow {
                selectedVariant = newRow.correspondingVariant
            }
        }
        .onChange(of: selectedVariant) { _, newVar in
            selectedRow = LifeRow.from(variant: newVar)
        }
        .onAppear {
            selectedRow = LifeRow.from(variant: selectedVariant)
        }
    }
}

// MARK: - LifeRowButton

private struct LifeRowButton: View {

    let row: LifeRow
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: row.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : DS.Color.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(
                        isSelected ? Color.accentColor.opacity(0.18) : DS.Color.surfaceRecessed,
                        in: RoundedRectangle(cornerRadius: 6)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(row.rawValue)
                        .font(DS.Text.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? DS.Color.textPrimary : (isHovered ? DS.Color.textPrimary : DS.Color.textSecondary))

                    Text(row.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? DS.Color.textSecondary : DS.Color.textTertiary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? DS.Color.surfaceRecessed
                    : (isHovered ? DS.Color.surfaceRecessed.opacity(0.5) : Color.clear),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
