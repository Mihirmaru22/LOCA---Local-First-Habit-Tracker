import SwiftUI

// MARK: - QuotePanel

struct QuotePanel: View {

    @Binding var isPresented: Bool
    @State private var quoteIndex: Int = 0

    private static let quotes: [(quote: String, author: String)] = [
        ("We are what we repeatedly do. Excellence, then, is not an act, but a habit.", "Will Durant"),
        ("Deep work is the ability to focus without distraction on a cognitively demanding task.", "Cal Newport"),
        ("Simplicity is the ultimate sophistication.", "Leonardo da Vinci"),
        ("Focus is a muscle. The more you practice it, the stronger it becomes.", "Steve Jobs"),
        ("Action is the foundational key to all success.", "Pablo Picasso"),
        ("It always seems impossible until it is done.", "Nelson Mandela"),
        ("The secret of getting ahead is getting started.", "Mark Twain"),
        ("Do not wait to strike till the iron is hot; but make it hot by striking.", "William Butler Yeats"),
        ("You do not rise to the level of your goals. You fall to the level of your systems.", "James Clear"),
        ("Your time is limited, so don't waste it living someone else's life.", "Steve Jobs"),
        ("Small deeds done are better than great deeds planned.", "Peter Marshall"),
        ("Energy flows where attention goes.", "Tony Robbins"),
        ("The only way to do great work is to love what you do.", "Steve Jobs"),
        ("Discipline equals freedom.", "Jocko Willink"),
        ("He who has a why to live can bear almost any how.", "Friedrich Nietzsche"),
        ("Concentrate all your thoughts upon the work in hand. The sun's rays do not burn until brought to a focus.", "Alexander Graham Bell"),
        ("Quality is not an act, it is a habit.", "Aristotle"),
        ("Rivers know this: there is no hurry. We shall get there some day.", "A.A. Milne"),
        ("The best way out is always through.", "Robert Frost"),
        ("Today's effort is tomorrow's superpower.", "Pluto Focus")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack {
                Label("Inspiration", systemImage: "quote.bubble.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    isPresented = false
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // Quote Body
            VStack(alignment: .leading, spacing: 8) {
                Text("“\(Self.quotes[quoteIndex].quote)”")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.white)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Text("— \(Self.quotes[quoteIndex].author)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

            // Randomize Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    quoteIndex = (quoteIndex + 1) % Self.quotes.count
                }
                PlutoSoundEngine.shared.play(.checkmark)
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                    Text("New quote")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1), in: Capsule())
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 280)
        .background(
            Color.black.opacity(0.72)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
    }
}
