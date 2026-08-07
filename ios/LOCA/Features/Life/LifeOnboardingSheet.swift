//
//  LifeOnboardingSheet.swift
//  LOCA
//
//  P1B — First-run onboarding for the Life tab.
//  Three cards explaining what Life is, what it isn't, and how to read it.
//  Shown once; @AppStorage("life.onboardingSeen") gates it.
//

import SwiftUI

struct LifeOnboardingSheet: View {
    let onDone: () -> Void

    @State private var page = 0

    private let cards: [(icon: String, title: String, body: String)] = [
        (
            icon: "binoculars",
            title: "Your life, not our model",
            body: "LOCA builds a personal picture from the signals you generate — check-ins, rhythms, patterns over time. It doesn't impose a framework or compare you to anyone else."
        ),
        (
            icon: "waveform.path.ecg",
            title: "Honest about what it doesn't know",
            body: "Where data is thin or signals conflict, LOCA says so. Observations are soft where uncertain. Nothing is invented to fill a gap."
        ),
        (
            icon: "hand.tap",
            title: "Teach it how you feel",
            body: "After logging a habit, you can check in on your energy and mood. The more you do, the sharper the patterns become. LOCA learns from what you say, not just what you track."
        ),
        (
            icon: "binoculars",
            title: "Browse at your own pace",
            body: "Chapters, events, people, patterns — explore any thread or none. Ask a question and LOCA shows you the answer as something to read and conclude from, not a verdict."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(cards.indices, id: \.self) { i in
                    cardView(cards[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(action: {
                if page < cards.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onDone()
                }
            }) {
                Text(page < cards.count - 1 ? "Next" : "Get started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(DS.Space.md)
                    .background(.tint, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.bottom, DS.Space.xxxl)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func cardView(_ card: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: DS.Space.lg) {
            Image(systemName: card.icon)
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .padding(.top, DS.Space.xxl)

            VStack(spacing: DS.Space.sm) {
                Text(card.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(card.body)
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, DS.Space.xl)

            Spacer()
        }
    }
}

#Preview {
    LifeOnboardingSheet { }
}
