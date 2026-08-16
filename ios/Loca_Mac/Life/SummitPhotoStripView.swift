import SwiftUI
import AppKit

// MARK: - SummitPhotoStripView

/// Aesthetic horizontal photo carousel embedded on the Summit Detail Card.
/// Provides async cached thumbnail loading, hover QuickLook triggers, and 1-click photo deletion.
struct SummitPhotoStripView: View {

    @Bindable var trek: TrekRecord
    let onOpenQuickLook: (String, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Header with Photo Counter
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.cyan)
                    Text("SUMMIT MEMORIES (\(trek.photoFileNames.count))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                }

                Spacer()

                Button {
                    Task {
                        let files = await TrekPhotoPickerHelper.pickSummitPhotos()
                        guard !files.isEmpty else { return }
                        trek.attachPhotos(fileNames: files)
                        Haptics.notification(.success)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                        Text("Add")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }

            // Horizontal Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(trek.photoFileNames.enumerated()), id: \.element) { index, fileName in
                        SummitThumbnailCard(
                            fileName: fileName,
                            onTap: {
                                onOpenQuickLook(fileName, index)
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    trek.removePhoto(fileName: fileName)
                                }
                                Haptics.impact(.medium)
                            }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - SummitThumbnailCard

struct SummitThumbnailCard: View {
    let fileName: String
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var image: NSImage? = nil
    @State private var isHovered: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                } else {
                    ZStack {
                        Color.white.opacity(0.06)
                        ProgressView()
                            .controlSize(.small)
                    }
                    .frame(width: 80, height: 80)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.cyan.opacity(0.8) : Color.white.opacity(0.12), lineWidth: isHovered ? 1.5 : 1)
            )

            // Hover Controls Overlay
            if isHovered {
                // Dimming gradient
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 80, height: 80)
                    .allowsHitTesting(false)

                // QuickLook Center Icon
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)

                // Delete '✕' Button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.red, Color.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .padding(4)
                .help("Delete Photo")
            }
        }
        .frame(width: 80, height: 80)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
        .task(id: fileName) {
            image = await TrekMediaManager.shared.loadPhotoAsync(fileName: fileName)
        }
    }
}
