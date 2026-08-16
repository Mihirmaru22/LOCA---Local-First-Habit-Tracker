import SwiftUI
import AppKit

// MARK: - SummitPhotoQuickLookModal

/// Full-screen high-resolution QuickLook modal for summit photos in Pluto's Trek Atlas.
/// Features glassmorphic backdrop blur, keyboard navigation (Left/Right arrows),
/// zoom toggling, and rich mountain telemetry headers.
struct SummitPhotoQuickLookModal: View {

    let trek: TrekRecord
    @Binding var currentPhotoIndex: Int
    let onDismiss: () -> Void

    @State private var loadedImage: NSImage? = nil
    @State private var isZoomed: Bool = false
    @State private var dragOffset: CGSize = .zero

    private var photoFileNames: [String] { trek.photoFileNames }

    private var currentFileName: String? {
        guard currentPhotoIndex >= 0 && currentPhotoIndex < photoFileNames.count else { return nil }
        return photoFileNames[currentPhotoIndex]
    }

    var body: some View {
        ZStack {

            // Background Blur & Dimming
            Color.black.opacity(0.88)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 0) {

                // Top Telemetry Header Bar
                HStack(alignment: .center) {

                    // Mountain Identity & Altitude
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(trek.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            Text("\(Int(trek.elevationMeters).formatted()) m")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                        }

                        Text("\(trek.region), \(trek.country)")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }

                    Spacer()

                    // Photo Counter Pill
                    if photoFileNames.count > 1 {
                        Text("\(currentPhotoIndex + 1) of \(photoFileNames.count)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.12), in: Capsule())
                    }

                    // Zoom 1x / 2x Toggle
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isZoomed.toggle()
                            if !isZoomed { dragOffset = .zero }
                        }
                    } label: {
                        Image(systemName: isZoomed ? "minus.magnifyingglass" : "plus.magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help(isZoomed ? "Reset Zoom (1x)" : "Zoom In (2x)")

                    // Close Button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close (Esc)")
                }
                .padding(.horizontal, DS.Space.xl)
                .padding(.vertical, DS.Space.lg)
                .background(.ultraThinMaterial.opacity(0.8))

                Divider().overlay(Color.white.opacity(0.1))

                // Main High-Res Image Canvas
                ZStack {
                    if let loadedImage {
                        Image(nsImage: loadedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(isZoomed ? 2.0 : 1.0)
                            .offset(dragOffset)
                            .gesture(
                                isZoomed ?
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                    }
                                    .onEnded { _ in
                                        // Keep pan within reason
                                    }
                                : nil
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isZoomed.toggle()
                                    if !isZoomed { dragOffset = .zero }
                                }
                            }
                            .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
                            .padding(DS.Space.xl)
                    } else {
                        VStack(spacing: DS.Space.md) {
                            ProgressView()
                                .controlSize(.large)
                            Text("Loading high-resolution summit photo...")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    // Floating Left Arrow Button
                    if photoFileNames.count > 1 && currentPhotoIndex > 0 {
                        HStack {
                            Button {
                                navigatePrevious()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, DS.Space.xl)

                            Spacer()
                        }
                    }

                    // Floating Right Arrow Button
                    if photoFileNames.count > 1 && currentPhotoIndex < photoFileNames.count - 1 {
                        HStack {
                            Spacer()

                            Button {
                                navigateNext()
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, DS.Space.xl)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: currentPhotoIndex) {
            await loadCurrentImage()
        }
        // Keyboard arrow navigation
        .onKeyPress(.leftArrow) {
            navigatePrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateNext()
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }

    // MARK: - Navigation

    private func navigatePrevious() {
        guard currentPhotoIndex > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPhotoIndex -= 1
            isZoomed = false
            dragOffset = .zero
        }
        Haptics.impact(.light)
    }

    private func navigateNext() {
        guard currentPhotoIndex < photoFileNames.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPhotoIndex += 1
            isZoomed = false
            dragOffset = .zero
        }
        Haptics.impact(.light)
    }

    private func loadCurrentImage() async {
        guard let fileName = currentFileName else { return }
        loadedImage = await TrekMediaManager.shared.loadPhotoAsync(fileName: fileName)
    }
}
