import SwiftUI
import SwiftData

// MARK: - LifeRow

enum LifeRow: String, CaseIterable, Identifiable {
    case trekAtlas = "Mountain & Trek Atlas"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .trekAtlas: return "mountain.2.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .trekAtlas: return "Conquered peaks & summit atlas"
        }
    }
}

// MARK: - MacLifeContentColumn

/// Middle column for the Life section in macOS layout.
struct MacLifeContentColumn: View {

    @Binding var selectedRow: LifeRow?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("EXPEDITIONS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
                Spacer()
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)

            Divider()

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(LifeRow.allCases) { row in
                        Button {
                            selectedRow = row
                            Haptics.selection()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: row.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24, height: 24)
                                    .background(Color.accentColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(row.rawValue)
                                        .font(DS.Text.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(DS.Color.textPrimary)

                                    Text(row.subtitle)
                                        .font(.system(size: 10))
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Life")
    }
}
