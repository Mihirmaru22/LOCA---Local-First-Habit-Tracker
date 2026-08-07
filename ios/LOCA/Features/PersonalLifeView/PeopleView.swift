//
//  PeopleView.swift
//  LOCA
//
//  Phase 5 — People in Your Life view
//  Shows recurring people sorted by salience, with context and mood correlation
//

import SwiftUI
import SwiftData

struct PeopleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.salience, order: .reverse) private var people: [Person]

    var body: some View {
        Group {
            if people.isEmpty {
                emptyState
            } else {
                peopleList
            }
        }
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: refreshPeople) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    // MARK: - People List

    private var peopleList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                Text("Recurring people in your calendar and notes")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)

                ForEach(people) { person in
                    PersonCard(person: person)
                        .padding(.horizontal, DS.Space.lg)
                }

                Spacer(minLength: DS.Space.xxxl)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        LifeEmptyState(
            icon: "person.2",
            headline: "No people detected yet",
            message: "LOCA notices people from your calendar and patterns. Once it sees recurring appearances, it connects them to how you feel. This requires calendar access."
        )
    }

    // MARK: - Refresh

    private func refreshPeople() {
        Task {
            try? await PeopleExtractor.shared.extractPeople(modelContext: modelContext)
        }
    }
}

// MARK: - Person Card

struct PersonCard: View {
    let person: Person

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            PersonAvatar(initials: person.initials, context: person.primaryContext)

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                HStack {
                    Text(person.name)
                        .font(DS.Text.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.Color.textPrimary)

                    Spacer()

                    ContextBadge(context: person.primaryContext)
                }

                SalienceBar(salience: person.salience, uncertainty: person.salienceUncertainty)

                Text("\(person.appearanceCount) appearances")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border, lineWidth: 1)
        )
    }
}

// MARK: - Person Avatar

private struct PersonAvatar: View {
    let initials: String
    let context: RelationshipContext

    var body: some View {
        ZStack {
            Circle()
                .frame(width: 44, height: 44)
                .foregroundStyle(context.color.opacity(0.15))

            Text(initials)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(context.color)
        }
    }
}

// MARK: - Context Badge

private struct ContextBadge: View {
    let context: RelationshipContext

    var body: some View {
        if context != .unknown {
            Text(context.displayName)
                .font(.caption2)
                .foregroundStyle(context.color)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(context.color.opacity(0.12), in: Capsule())
        }
    }
}

// MARK: - Salience Bar

private struct SalienceBar: View {
    let salience: Double
    let uncertainty: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .frame(height: 4)
                    .foregroundStyle(DS.Color.surfaceRecessed)

                let haloStart = max(0, salience - uncertainty * 0.5)
                let haloEnd = min(1, salience + uncertainty * 0.5)
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: geo.size.width * (haloEnd - haloStart), height: 4)
                    .offset(x: geo.size.width * haloStart)
                    .foregroundStyle(Color.accentColor.opacity(0.2))

                RoundedRectangle(cornerRadius: 2)
                    .frame(width: geo.size.width * salience, height: 4)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - RelationshipContext Extensions

extension RelationshipContext {
    var displayName: String {
        switch self {
        case .work:      return "Work"
        case .social:    return "Social"
        case .family:    return "Family"
        case .recurring: return "Recurring"
        case .unknown:   return "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .work:      return Color(hex: "#3B82F6")
        case .social:    return Color(hex: "#F59E0B")
        case .family:    return Color(hex: "#10B981")
        case .recurring: return Color(hex: "#8B5CF6")
        case .unknown:   return Color(hex: "#6B7280")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PeopleView()
    }
}
