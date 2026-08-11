import SwiftUI

// MARK: - TodoIcon   (T7 — per-task icon catalog)

/// Curated SF Symbol catalog for day-planner task blocks.
///
/// Symbols are chosen to read legibly at 14 pt inside a 36 pt filled bubble.
/// Prefer filled variants so the icon has visual weight against the accent circle.
enum TodoIcon {

    struct Entry: Identifiable {
        let id: String      // SF Symbol name stored in TodoItem.iconName
        let label: String   // Accessibility / tooltip label
    }

    struct Category: Identifiable {
        let id: String
        let name: String
        let icons: [Entry]
    }

    // MARK: Catalog

    static let categories: [Category] = [
        Category(id: "general", name: "General", icons: [
            Entry(id: "checkmark",           label: "Task"),
            Entry(id: "star.fill",           label: "Star"),
            Entry(id: "bolt.fill",           label: "Energy"),
            Entry(id: "flame.fill",          label: "Focus"),
            Entry(id: "bell.fill",           label: "Reminder"),
            Entry(id: "flag.fill",           label: "Flagged"),
        ]),
        Category(id: "work", name: "Work", icons: [
            Entry(id: "briefcase.fill",      label: "Work"),
            Entry(id: "laptopcomputer",      label: "Computer"),
            Entry(id: "envelope.fill",       label: "Email"),
            Entry(id: "phone.fill",          label: "Call"),
            Entry(id: "video.fill",          label: "Meeting"),
            Entry(id: "doc.fill",            label: "Document"),
        ]),
        Category(id: "personal", name: "Personal", icons: [
            Entry(id: "house.fill",          label: "Home"),
            Entry(id: "cart.fill",           label: "Shopping"),
            Entry(id: "fork.knife",          label: "Meal"),
            Entry(id: "cup.and.saucer.fill", label: "Coffee"),
            Entry(id: "car.fill",            label: "Travel"),
            Entry(id: "airplane",            label: "Flight"),
        ]),
        Category(id: "health", name: "Health", icons: [
            Entry(id: "heart.fill",          label: "Health"),
            Entry(id: "figure.walk",         label: "Walk"),
            Entry(id: "dumbbell.fill",       label: "Gym"),
            Entry(id: "drop.fill",           label: "Hydration"),
            Entry(id: "pills.fill",          label: "Medication"),
            Entry(id: "bed.double.fill",     label: "Sleep"),
        ]),
        Category(id: "creative", name: "Creative", icons: [
            Entry(id: "pencil",              label: "Write"),
            Entry(id: "paintbrush.fill",     label: "Art"),
            Entry(id: "music.note",          label: "Music"),
            Entry(id: "book.fill",           label: "Read"),
            Entry(id: "camera.fill",         label: "Photo"),
            Entry(id: "mic.fill",            label: "Record"),
        ]),
    ]

    // MARK: Lookup

    /// Human-readable label for a given SF Symbol name, or the symbol name itself
    /// if it isn't in the catalog.
    static func label(for symbolName: String) -> String {
        for cat in categories {
            if let entry = cat.icons.first(where: { $0.id == symbolName }) {
                return entry.label
            }
        }
        return symbolName
    }
}

// MARK: - IconPickerPopover

/// A fixed-size popover grid for choosing a task block icon.
///
/// Tapping the current icon deselects it (sets `selected` to `nil`, falling back
/// to the default "checkmark" glyph). Tapping any other icon selects it and the
/// caller's binding is responsible for dismissing the popover.
struct IconPickerPopover: View {

    @Binding var selected: String?

    private let columns = Array(repeating: GridItem(.fixed(44), spacing: DS.Space.sm), count: 5)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                ForEach(TodoIcon.categories) { category in
                    Text(category.name.uppercased())
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.5)
                        .padding(.top, DS.Space.sm)

                    LazyVGrid(columns: columns, spacing: DS.Space.sm) {
                        ForEach(category.icons) { icon in
                            let isActive = selected == icon.id
                            Button {
                                selected = isActive ? nil : icon.id
                            } label: {
                                Image(systemName: icon.id)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(isActive ? Color.white : DS.Color.textPrimary)
                                    .frame(width: 36, height: 36)
                                    .background {
                                        Circle()
                                            .fill(isActive ? Color.accentColor : DS.Color.surface)
                                            .overlay {
                                                if isActive {
                                                    Circle().fill(
                                                        LinearGradient(
                                                            colors: [Color.white.opacity(0.28), Color.clear],
                                                            startPoint: .topLeading,
                                                            endPoint: .center
                                                        )
                                                    )
                                                }
                                            }
                                    }
                            }
                            .buttonStyle(.plain)
                            .help(icon.label)
                        }
                    }
                }
            }
            .padding(DS.Space.md)
        }
        .frame(width: 284, height: 320)
    }
}
