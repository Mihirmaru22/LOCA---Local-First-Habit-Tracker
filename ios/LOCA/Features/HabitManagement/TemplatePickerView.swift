//
//  TemplatePickerView.swift
//  LOCA
//
//  Phase 2.5 — Template browser for guided habit creation.
//
//  Displays research-backed habit templates organized by category.
//  User selects a template to auto-populate creation form with goal,
//  unit, and reminder time.
//

import SwiftUI

struct TemplatePickerView: View {

    let onSelect: (HabitTemplate) -> Void
    let onDismiss: () -> Void

    private let categories = HabitTemplate.byCategory()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    ForEach(categories.keys.sorted(), id: \.self) { category in
                        categorySection(category, templates: categories[category] ?? [])
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle("Choose a Habit")
            .inlineNavigationTitleDisplay()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func categorySection(_ category: String, templates: [HabitTemplate]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            Text(category)
                .font(DS.Text.body)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.textPrimary)
                .padding(.horizontal, DS.Space.md)

            VStack(spacing: DS.Space.sm) {
                ForEach(templates, id: \.id) { template in
                    Button(action: { onSelect(template) }) {
                        HStack(spacing: DS.Space.md) {
                            Text(template.emoji)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: DS.Space.xs) {
                                Text(template.name)
                                    .font(DS.Text.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(DS.Color.textPrimary)

                                Text(template.description)
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DS.Space.md)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    TemplatePickerView(
        onSelect: { _ in },
        onDismiss: { }
    )
}
