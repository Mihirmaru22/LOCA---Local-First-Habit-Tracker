import SwiftUI

// MARK: - ExpeditionPassportModal

/// Interactive fullscreen inspection and export studio for Pluto's Expedition Passports.
/// Provides live zooming preview and 1-click vector PDF, 4K PNG, and GPX export actions.
struct ExpeditionPassportModal: View {

    let trek: TrekRecord
    let onDismiss: () -> Void

    @State private var zoomScale: CGFloat = 1.0
    @State private var exportToastMessage: String? = nil

    var body: some View {
        VStack(spacing: 0) {

            // Top Action Toolbar
            toolbarHeader

            Divider()

            // Main Preview Canvas with Zoom & Pan
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack {
                    ExpeditionPassportDocumentView(trek: trek)
                        .scaleEffect(zoomScale)
                        .padding(40)
                        .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(red: 0.10, green: 0.12, blue: 0.16))
        }
        .frame(minWidth: 860, idealWidth: 920, minHeight: 700, idealHeight: 800)
        .overlay(alignment: .bottom) {
            if let msg = exportToastMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text(msg)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 1))
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Toolbar Header

    private var toolbarHeader: some View {
        HStack(spacing: DS.Space.md) {
            HStack(spacing: 8) {
                Image(systemName: "compass.drawing")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 0.78, green: 0.66, blue: 0.48))

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(trek.name.uppercased()) EXPEDITION DOSSIER")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text("Official Himalayan & Alpine Summit Registry")
                        .font(.system(size: 10))
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }

            Spacer()

            // Zoom Controls
            HStack(spacing: 4) {
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        zoomScale = max(0.6, zoomScale - 0.15)
                    }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Text("\(Int(zoomScale * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(width: 44)

                Button {
                    withAnimation(.spring(response: 0.2)) {
                        zoomScale = min(1.8, zoomScale + 0.15)
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Button("Fit") {
                    withAnimation(.spring(response: 0.2)) {
                        zoomScale = 0.85
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 6)
            .frame(height: 32)
            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 8))

            Divider().frame(height: 20)

            // Export Actions
            HStack(spacing: 8) {
                // Copy Image
                Button {
                    let success = ExpeditionPassportPDFGenerator.copyImageToPasteboard(for: trek)
                    if success {
                        showToast("Copied Passport Image to Clipboard")
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("Copy")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Export GPX
                Button {
                    ExpeditionPassportPDFGenerator.exportGPX(for: trek) { success in
                        if success {
                            showToast("GPX Trail Route Exported Successfully")
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "point.topleft.down.to.point.bottomright.filled.curvepath")
                            .font(.system(size: 11))
                        Text("Export GPX")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Export PNG
                Button {
                    ExpeditionPassportPDFGenerator.exportPNG(for: trek) { success in
                        if success {
                            showToast("4K Certificate Image Saved")
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "photo")
                            .font(.system(size: 11))
                        Text("Save PNG")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)

                // Export Vector PDF (Primary)
                Button {
                    ExpeditionPassportPDFGenerator.exportPDF(for: trek) { success in
                        if success {
                            showToast("Vector PDF Document Exported")
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Save PDF")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 14)
                    .frame(height: 32)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.82, green: 0.70, blue: 0.52), Color(red: 0.68, green: 0.56, blue: 0.38)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.90, green: 0.80, blue: 0.65).opacity(0.6), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider().frame(height: 20)

            // Close
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DS.Color.textSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, 10)
        .background(DS.Color.surface)
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            exportToastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                exportToastMessage = nil
            }
        }
    }
}
