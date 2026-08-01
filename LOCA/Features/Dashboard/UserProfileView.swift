//
//  UserProfileView.swift
//  LOCA
//
//  V2.0B.5 — Lightweight user body profile.
//  Accessed via Settings → Profile. Captures height, weight, goal weight,
//  birth year, sex, and activity level. Derives BMI, TDEE, and a goal
//  projection live from those values. Optional HealthKit sync pulls the
//  latest body-mass and height samples without touching the signal pipeline.
//

import SwiftUI
import SwiftData
import HealthKit

struct UserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    // Local editable state — synced to/from the UserProfile model
    @State private var heightCmText = ""
    @State private var heightFeetText = ""
    @State private var heightInchesText = ""
    @State private var weightText = ""
    @State private var goalWeightText = ""
    @State private var birthYearText = ""
    @State private var sex: BiologicalSex = .unspecified
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var preferKg = true
    @State private var preferCm = true

    @State private var isSyncing = false
    @State private var syncStatus: String? = nil

    private var profile: UserProfile? { profiles.first }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                bodySection
                aboutSection
                numbersSection
                healthKitSection
                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(DS.Space.lg)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { ensureProfile() }
        .onAppear { loadState() }
    }

    // MARK: - Body section

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            SectionHeader("Body")

            // Height
            profileCard {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    fieldLabel("Height")
                    HStack(spacing: DS.Space.sm) {
                        if preferCm {
                            unitTextField($heightCmText, placeholder: "cm", width: 64)
                                .onChange(of: heightCmText) { saveHeight() }
                            Text("cm").font(DS.Text.body).foregroundStyle(DS.Color.textSecondary)
                        } else {
                            unitTextField($heightFeetText, placeholder: "ft", width: 36)
                                .onChange(of: heightFeetText) { saveHeight() }
                            Text("ft").font(DS.Text.body).foregroundStyle(DS.Color.textSecondary)
                            unitTextField($heightInchesText, placeholder: "in", width: 44)
                                .onChange(of: heightInchesText) { saveHeight() }
                            Text("in").font(DS.Text.body).foregroundStyle(DS.Color.textSecondary)
                        }
                        Spacer()
                        unitToggle(left: "cm", right: "ft", leftActive: preferCm) {
                            switchHeightUnit()
                        }
                    }
                }
            }

            // Weight
            profileCard {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    fieldLabel("Weight")
                    HStack(spacing: DS.Space.sm) {
                        unitTextField($weightText, placeholder: preferKg ? "kg" : "lb", width: 72)
                            .onChange(of: weightText) { saveWeight() }
                        Text(preferKg ? "kg" : "lb")
                            .font(DS.Text.body).foregroundStyle(DS.Color.textSecondary)
                        Spacer()
                        unitToggle(left: "kg", right: "lb", leftActive: preferKg) {
                            switchWeightUnit()
                        }
                    }
                }
            }

            // Goal weight
            profileCard {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    fieldLabel("Goal Weight")
                    HStack(spacing: DS.Space.sm) {
                        unitTextField($goalWeightText, placeholder: "optional", width: 72)
                            .onChange(of: goalWeightText) { saveGoalWeight() }
                        Text(preferKg ? "kg" : "lb")
                            .font(DS.Text.body).foregroundStyle(DS.Color.textSecondary)
                        Spacer()
                        if !goalWeightText.isEmpty {
                            Button(action: {
                                goalWeightText = ""
                                profile?.goalWeightKg = nil
                                commit()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            SectionHeader("About You")

            // Birth year
            profileCard {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    fieldLabel("Birth Year")
                    TextField("e.g. 1990", text: $birthYearText)
                        .keyboardType(.numberPad)
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)
                        .onChange(of: birthYearText) { saveBirthYear() }
                }
            }

            // Sex
            profileCard {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    fieldLabel("Biological Sex")
                    Text("Used only for BMR calculation")
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                    Picker("Sex", selection: $sex) {
                        ForEach(BiologicalSex.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: sex) {
                        profile?.sex = sex
                        commit()
                    }
                }
            }

            // Activity level
            profileCard {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    fieldLabel("Activity Level")
                    Picker("Activity", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: activityLevel) {
                        profile?.activityLevel = activityLevel
                        commit()
                    }
                    Text(activityLevel.hint)
                        .font(.caption2)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
        }
    }

    // MARK: - Numbers section

    @ViewBuilder
    private var numbersSection: some View {
        let p = profile
        let bmi = p?.bmi
        let tdee = p?.tdee
        let weeks = p?.weeksToGoal

        if bmi != nil || tdee != nil {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                SectionHeader("Your Numbers")

                HStack(spacing: DS.Space.md) {
                    if let b = bmi, let cat = p?.bmiCategory {
                        numberTile(
                            label: "BMI",
                            value: String(format: "%.1f", b),
                            badge: cat.label,
                            badgeColor: Color(hex: cat.colorHex)
                        )
                    }
                    if let t = tdee {
                        numberTile(
                            label: "TDEE",
                            value: "\(Int(t.rounded()))",
                            badge: "kcal/day",
                            badgeColor: DS.Color.textTertiary
                        )
                    }
                }

                if let w = weeks, let p, p.goalWeightKg != nil {
                    profileCard {
                        HStack {
                            VStack(alignment: .leading, spacing: DS.Space.xs) {
                                Text("Goal Projection")
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textTertiary)
                                    .textCase(.uppercase)
                                Text("~\(w) week\(w == 1 ? "" : "s") at a moderate pace")
                                    .font(DS.Text.body)
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                            Spacer()
                            Image(systemName: p.isLosingWeight ? "arrow.down.circle" : "arrow.up.circle")
                                .font(.title3)
                                .foregroundStyle(.tint)
                        }
                    }
                }

                Text("TDEE uses the Mifflin–St Jeor equation. Projection assumes a 500 kcal/day deficit (≈ 0.45 kg/week). These are estimates — not medical advice.")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - HealthKit section

    @ViewBuilder
    private var healthKitSection: some View {
        if HKHealthStore.isHealthDataAvailable() {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                SectionHeader("Integrations")

                Button(action: syncFromHealthKit) {
                    HStack {
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text(isSyncing ? "Syncing…" : "Sync from Health")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            if let msg = syncStatus {
                                Text(msg)
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textTertiary)
                            } else {
                                Text("Pull latest weight and height from Apple Health")
                                    .font(.caption2)
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                        }
                        Spacer()
                        if isSyncing {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                }
                .buttonStyle(.pressable)
                .disabled(isSyncing)
            }
        }
    }

    // MARK: - HealthKit sync

    private func syncFromHealthKit() {
        isSyncing = true
        syncStatus = nil
        Task {
            let snap = await BodyDataFetcher.fetchLatest()
            if snap.weightKg == nil && snap.heightCm == nil {
                syncStatus = "Nothing found in Health app"
            } else {
                if let w = snap.weightKg {
                    let p = profile
                    p?.weightKg = w
                    p?.updatedAt = Date()
                    weightText = formatWeight(w)
                }
                if let h = snap.heightCm {
                    let p = profile
                    p?.heightCm = h
                    p?.updatedAt = Date()
                    heightCmText = formatCm(h)
                    let (ft, inches) = cmToFtIn(h)
                    heightFeetText = "\(ft)"
                    heightInchesText = String(format: "%.1f", inches)
                }
                commit()
                let parts = [snap.weightKg.map { _ in "weight" }, snap.heightCm.map { _ in "height" }]
                    .compactMap { $0 }
                syncStatus = "Synced \(parts.joined(separator: " & ")) from Health"
            }
            isSyncing = false
        }
    }

    // MARK: - Sub-components

    private func profileCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(DS.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border, lineWidth: 1))
    }

    private func fieldLabel(_ label: String) -> some View {
        Text(label)
            .font(DS.Text.caption)
            .foregroundStyle(DS.Color.textTertiary)
            .textCase(.uppercase)
    }

    private func unitTextField(_ text: Binding<String>, placeholder: String, width: CGFloat) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(.decimalPad)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(DS.Color.textPrimary)
            .frame(width: width)
            .multilineTextAlignment(.trailing)
    }

    private func unitToggle(left: String, right: String, leftActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(left)
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(leftActive ? .white : DS.Color.textTertiary)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(leftActive ? Color.accentColor : Color.clear,
                                in: Capsule())
                Text(right)
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundStyle(!leftActive ? .white : DS.Color.textTertiary)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(!leftActive ? Color.accentColor : Color.clear,
                                in: Capsule())
            }
            .padding(2)
            .background(DS.Color.surfaceRecessed, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func numberTile(label: String, value: String, badge: String, badgeColor: Color) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(label)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .monospacedDigit()
            Text(badge)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(badgeColor)
        }
        .padding(DS.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border, lineWidth: 1))
    }

    // MARK: - Data management

    private func ensureProfile() {
        guard profiles.isEmpty else { return }
        let p = UserProfile()
        modelContext.insert(p)
        try? modelContext.save()
    }

    private func loadState() {
        guard let p = profile else { return }
        preferKg = p.preferKg
        preferCm = p.preferCm
        sex = p.sex
        activityLevel = p.activityLevel

        if let h = p.heightCm {
            heightCmText = formatCm(h)
            let (ft, inches) = cmToFtIn(h)
            heightFeetText = "\(ft)"
            heightInchesText = String(format: "%.1f", inches)
        }
        if let w = p.weightKg {
            weightText = formatWeight(w)
        }
        if let g = p.goalWeightKg {
            goalWeightText = formatWeight(g)
        }
        if let y = p.birthYear {
            birthYearText = "\(y)"
        }
    }

    private func commit() {
        profile?.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Save helpers

    private func saveHeight() {
        guard let p = profile else { return }
        if preferCm {
            p.heightCm = Double(heightCmText.replacingOccurrences(of: ",", with: "."))
        } else {
            let ft = Double(heightFeetText) ?? 0
            let inches = Double(heightInchesText.replacingOccurrences(of: ",", with: ".")) ?? 0
            if ft > 0 || inches > 0 { p.heightCm = ft * 30.48 + inches * 2.54 }
        }
        commit()
    }

    private func saveWeight() {
        guard let p = profile else { return }
        if let v = Double(weightText.replacingOccurrences(of: ",", with: ".")) {
            p.weightKg = preferKg ? v : v / 2.20462
        }
        commit()
    }

    private func saveGoalWeight() {
        guard let p = profile else { return }
        if goalWeightText.isEmpty {
            p.goalWeightKg = nil
        } else if let v = Double(goalWeightText.replacingOccurrences(of: ",", with: ".")) {
            p.goalWeightKg = preferKg ? v : v / 2.20462
        }
        commit()
    }

    private func saveBirthYear() {
        guard let p = profile else { return }
        let year = Int(birthYearText)
        let current = Calendar.current.component(.year, from: Date())
        if let y = year, y > 1900, y < current {
            p.birthYear = y
        } else {
            p.birthYear = nil
        }
        commit()
    }

    // MARK: - Unit switching

    private func switchHeightUnit() {
        preferCm.toggle()
        profile?.preferCm = preferCm
        commit()
        // Re-format display from stored cm value
        if let h = profile?.heightCm {
            if preferCm {
                heightCmText = formatCm(h)
            } else {
                let (ft, inches) = cmToFtIn(h)
                heightFeetText = "\(ft)"
                heightInchesText = String(format: "%.1f", inches)
            }
        }
    }

    private func switchWeightUnit() {
        preferKg.toggle()
        profile?.preferKg = preferKg
        commit()
        if let w = profile?.weightKg {
            weightText = formatWeight(w)
        }
        if let g = profile?.goalWeightKg {
            goalWeightText = formatWeight(g)
        }
    }

    // MARK: - Format helpers

    private func formatCm(_ cm: Double) -> String {
        String(format: cm.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", cm)
    }

    private func formatWeight(_ kg: Double) -> String {
        let v = preferKg ? kg : kg * 2.20462
        return String(format: v.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", v)
    }

    private func cmToFtIn(_ cm: Double) -> (feet: Int, inches: Double) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = totalInches.truncatingRemainder(dividingBy: 12)
        return (feet, inches)
    }
}
