import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - TrekGPXPickerHelper

/// Native macOS file picker and Drag-and-Drop handler for GPX trail files in Pluto's Trek Atlas.
enum TrekGPXPickerHelper {

    /// Prompts the user to select a .gpx file via NSOpenPanel.
    @MainActor
    static func pickGPXFile() async -> GPXParseResult? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.prompt = "Import GPX Trail"
        panel.message = "Select a GPS track file (.gpx) from your Garmin, AllTrails, or Apple Watch export"
        panel.allowedContentTypes = [
            UTType(filenameExtension: "gpx") ?? .xml,
            UTType.xml
        ]

        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }

        return try? await TrekGPXEngine.parse(url: url)
    }

    /// Ingests dropped .gpx file providers from Finder.
    @MainActor
    static func processDroppedGPXProviders(_ providers: [NSItemProvider]) async -> GPXParseResult? {
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

                if let url, url.pathExtension.lowercased() == "gpx" {
                    return try? await TrekGPXEngine.parse(url: url)
                }
            }
        }
        return nil
    }
}
