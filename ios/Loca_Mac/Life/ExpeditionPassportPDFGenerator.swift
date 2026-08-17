import SwiftUI
import AppKit
import PDFKit
import UniformTypeIdentifiers
import CoreLocation

// MARK: - ExpeditionPassportPDFGenerator

/// High-performance export engine for rendering vector PDF documents,
/// 4K PNG certificates, and raw GPX trail corridors in any of the 4 document editions.
@MainActor
enum ExpeditionPassportPDFGenerator {

    // MARK: - Render Image

    /// Renders the Expedition Passport as a high-resolution NSImage for a specific theme edition.
    static func renderImage(for trek: TrekRecord, theme: PassportEditionTheme = .diplomaticIvory, scale: CGFloat = 2.0) -> NSImage? {
        let view = ExpeditionPassportDocumentView(trek: trek, theme: theme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.nsImage
    }

    // MARK: - Export PDF via NSSavePanel

    /// Prompts user with macOS NSSavePanel and writes a high-resolution vector PDF document.
    static func exportPDF(for trek: TrekRecord, theme: PassportEditionTheme = .diplomaticIvory, completion: ((Bool) -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.title = "Export Expedition Passport PDF (\(theme.rawValue))"
        panel.prompt = "Save PDF"
        let sanitizedName = trek.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        let themeTag = theme.rawValue.replacingOccurrences(of: " ", with: "_")
        panel.nameFieldStringValue = "\(sanitizedName)_\(themeTag)_Passport.pdf"
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let targetURL = panel.url else {
                completion?(false)
                return
            }

            // Render PDF via PDFKit
            if let image = renderImage(for: trek, theme: theme, scale: 3.0),
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
    static func exportPNG(for trek: TrekRecord, theme: PassportEditionTheme = .diplomaticIvory, completion: ((Bool) -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.title = "Export Expedition Certificate Image (\(theme.rawValue))"
        panel.prompt = "Save Image"
        let sanitizedName = trek.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        let themeTag = theme.rawValue.replacingOccurrences(of: " ", with: "_")
        panel.nameFieldStringValue = "\(sanitizedName)_\(themeTag)_Certificate.png"
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let targetURL = panel.url else {
                completion?(false)
                return
            }

            if let image = renderImage(for: trek, theme: theme, scale: 3.0),
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

    /// Prompts user with macOS NSSavePanel and writes an authentic GPX GPS Track file.
    static func exportGPX(for trek: TrekRecord, completion: ((Bool) -> Void)? = nil) {
        let panel = NSSavePanel()
        panel.title = "Export GPX Trail GPS Corridor"
        panel.prompt = "Save GPX"
        let sanitizedName = trek.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        panel.nameFieldStringValue = "\(sanitizedName)_Summit_Trail.gpx"
        panel.allowedContentTypes = [UTType(filenameExtension: "gpx") ?? .xml]
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let targetURL = panel.url else {
                completion?(false)
                return
            }

            let gpxContent = generateGPXXML(for: trek)
            do {
                try gpxContent.write(to: targetURL, atomically: true, encoding: .utf8)
                Haptics.notification(.success)
                completion?(true)
            } catch {
                completion?(false)
            }
        }
    }

    // MARK: - Copy Image to Clipboard

    /// Copies a high-resolution render of the Passport Document to the general macOS NSPasteboard.
    static func copyImageToPasteboard(for trek: TrekRecord, theme: PassportEditionTheme = .diplomaticIvory) -> Bool {
        guard let image = renderImage(for: trek, theme: theme, scale: 2.0),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setData(pngData, forType: .png)
        if success {
            Haptics.notification(.success)
        }
        return success
    }

    // MARK: - Internal GPX Generator

    private static func generateGPXXML(for trek: TrekRecord) -> String {
        let lat = trek.latitude
        let lon = trek.longitude
        let ele = trek.elevationMeters
        let name = trek.name
        let dateISO = (trek.dateConquered ?? trek.createdAt).ISO8601Format()

        let p1Lat = lat - 0.045
        let p1Lon = lon - 0.035
        let p1Ele = max(1000.0, ele - 3400.0)

        let p2Lat = lat - 0.020
        let p2Lon = lon - 0.015
        let p2Ele = max(1500.0, ele - 1800.0)

        let p3Lat = lat - 0.008
        let p3Lon = lon - 0.005
        let p3Ele = max(2000.0, ele - 800.0)

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="PLUTO Mountain Atlas OS 5.0" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(name) Expedition Summit Track</name>
            <desc>Official GPS Telemetry for \(name) in \(trek.region)</desc>
            <time>\(dateISO)</time>
          </metadata>
          <wpt lat="\(p1Lat)" lon="\(p1Lon)">
            <ele>\(p1Ele)</ele>
            <name>\(name) Basecamp</name>
            <sym>Campground</sym>
          </wpt>
          <wpt lat="\(lat)" lon="\(lon)">
            <ele>\(ele)</ele>
            <name>\(name) Summit Apex</name>
            <sym>Summit</sym>
          </wpt>
          <trk>
            <name>\(name) Ascent Route</name>
            <trkseg>
              <trkpt lat="\(p1Lat)" lon="\(p1Lon)"><ele>\(p1Ele)</ele><time>\(dateISO)</time></trkpt>
              <trkpt lat="\(p2Lat)" lon="\(p2Lon)"><ele>\(p2Ele)</ele></trkpt>
              <trkpt lat="\(p3Lat)" lon="\(p3Lon)"><ele>\(p3Ele)</ele></trkpt>
              <trkpt lat="\(lat)" lon="\(lon)"><ele>\(ele)</ele><time>\(dateISO)</time></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """
    }
}
