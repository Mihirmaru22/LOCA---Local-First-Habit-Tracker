import SwiftUI
import AppKit
import PDFKit
import UniformTypeIdentifiers

// MARK: - ExpeditionPassportPDFGenerator

/// High-performance export engine for rendering vector PDF documents,
/// 4K PNG certificates, and raw GPX trail corridors.
@MainActor
enum ExpeditionPassportPDFGenerator {

    // MARK: - Render Image

    /// Renders the Expedition Passport as a high-resolution NSImage.
    static func renderImage(for trek: TrekRecord, scale: CGFloat = 2.0) -> NSImage? {
        let view = ExpeditionPassportDocumentView(trek: trek)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.nsImage
    }

    // MARK: - Export PDF via NSSavePanel

    /// Prompts user with macOS NSSavePanel and writes a high-resolution vector PDF document.
    static func exportPDF(for trek: TrekRecord, completion: ((Bool) -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.title = "Export Expedition Passport PDF"
        panel.prompt = "Save PDF"
        let sanitizedName = trek.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        panel.nameFieldStringValue = "\(sanitizedName)_Expedition_Passport.pdf"
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let targetURL = panel.url else {
                completion?(false)
                return
            }

            // Render PDF via PDFKit
            if let image = renderImage(for: trek, scale: 3.0),
               let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {

                let pdfDoc = PDFDocument()
                if let pageImage = NSImage(data: pngData),
                   let pdfPage = PDFPage(image: pageImage) {
                    pdfDoc.insert(pdfPage, at: 0)
                    let success = pdfDoc.write(to: targetURL)
                    if success {
                        Haptics.notification(.success)
                    }
                    completion?(success)
                    return
                }
            }

            completion?(false)
        }
    }

    // MARK: - Export PNG Image via NSSavePanel

    /// Prompts user with macOS NSSavePanel and writes a 4K PNG certificate card.
    static func exportPNG(for trek: TrekRecord, completion: ((Bool) -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.title = "Export Expedition Certificate Image"
        panel.prompt = "Save Image"
        let sanitizedName = trek.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        panel.nameFieldStringValue = "\(sanitizedName)_Expedition_Certificate.png"
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let targetURL = panel.url else {
                completion?(false)
                return
            }

            if let image = renderImage(for: trek, scale: 3.0),
               let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                do {
                    try pngData.write(to: targetURL)
                    Haptics.notification(.success)
                    completion?(true)
                } catch {
                    completion?(false)
                }
            } else {
                completion?(false)
            }
        }
    }

    // MARK: - Export GPX Trail File

    /// Exports standard GPX XML trail coordinate file for Garmin/Apple Watch devices.
    static func exportGPX(for trek: TrekRecord, completion: ((Bool) -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.title = "Export GPX Trail Route"
        panel.prompt = "Save GPX"
        let sanitizedName = trek.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        panel.nameFieldStringValue = "\(sanitizedName)_Trail_Route.gpx"
        if let gpxType = UTType(filenameExtension: "gpx") {
            panel.allowedContentTypes = [gpxType]
        }
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let targetURL = panel.url else {
                completion?(false)
                return
            }

            let gpxString = generateGPXString(for: trek)
            do {
                try gpxString.write(to: targetURL, atomically: true, encoding: .utf8)
                Haptics.notification(.success)
                completion?(true)
            } catch {
                completion?(false)
            }
        }
    }

    // MARK: - Copy Image to Pasteboard

    /// Renders and copies the passport card directly to the macOS clipboard.
    static func copyImageToPasteboard(for trek: TrekRecord) -> Bool {
        guard let image = renderImage(for: trek, scale: 2.0) else { return false }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        Haptics.notification(.success)
        return true
    }

    // MARK: - GPX Generation Helper

    private static func generateGPXString(for trek: TrekRecord) -> String {
        let coords = trek.trailCoordinates
        var trkpts = ""
        for pt in coords {
            trkpts += "      <trkpt lat=\"\(pt.latitude)\" lon=\"\(pt.longitude)\">\n"
            trkpts += "        <ele>\(Int(trek.elevationMeters))</ele>\n"
            trkpts += "      </trkpt>\n"
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Pluto Mountaineering Atlas" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(trek.name) Expedition Trail</name>
            <desc>\(trek.region), \(trek.country) - Elevation \(Int(trek.elevationMeters))m</desc>
            <time>\(ISO8601DateFormatter().string(from: Date()))</time>
          </metadata>
          <trk>
            <name>\(trek.name)</name>
            <type>Hiking</type>
            <trkseg>
        \(trkpts)    </trkseg>
          </trk>
        </gpx>
        """
    }
}
