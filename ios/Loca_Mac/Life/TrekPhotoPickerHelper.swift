import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - TrekPhotoPickerHelper

/// Native macOS OpenPanel and Drag-and-Drop photo ingestion helper for Pluto's Trek Atlas.
enum TrekPhotoPickerHelper {

    /// Prompts the user to pick one or more summit photos via NSOpenPanel.
    @MainActor
    static func pickSummitPhotos() async -> [String] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.prompt = "Attach Summit Photos"
        panel.message = "Choose photos taken at this summit or along the trail"
        panel.allowedContentTypes = [
            .jpeg,
            .png,
            .heic,
            .tiff,
            .webP,
            UTType(filenameExtension: "jpg") ?? .jpeg
        ]

        let response = panel.runModal()
        guard response == .OK, !panel.urls.isEmpty else { return [] }

        return await TrekMediaManager.shared.savePhotos(from: panel.urls)
    }

    /// Ingests dropped image file URLs from Finder / Photos app.
    @MainActor
    static func processDroppedProviders(_ providers: [NSItemProvider]) async -> [String] {
        var fileURLs: [URL] = []

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                let url: URL? = await withCheckedContinuation { continuation in
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        if let data = item as? Data, let path = URL(dataRepresentation: data, relativeTo: nil) {
                            continuation.resume(returning: path)
                        } else if let url = item as? URL {
                            continuation.resume(returning: url)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }

                if let url, isImageURL(url) {
                    fileURLs.append(url)
                }
            }
        }

        guard !fileURLs.isEmpty else { return [] }
        return await TrekMediaManager.shared.savePhotos(from: fileURLs)
    }

    private static func isImageURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "heic", "tiff", "webp"].contains(ext)
    }
}
