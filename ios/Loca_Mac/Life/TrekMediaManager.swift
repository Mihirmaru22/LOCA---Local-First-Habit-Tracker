import Foundation
import AppKit

// MARK: - TrekMediaManager

/// High-performance local-first media manager for Pluto's Trek & Mountain Atlas.
/// Manages asynchronous downscaling, atomic file storage in Application Support,
/// memory caching, and physical file cleanup for summit photos.
final class TrekMediaManager: @unchecked Sendable {

    static let shared = TrekMediaManager()

    // MARK: - Memory Cache

    private let memoryCache = NSCache<NSString, NSImage>()

    private init() {
        memoryCache.countLimit = 60 // Keep up to 60 summit images in RAM
        memoryCache.totalCostLimit = 120 * 1024 * 1024 // 120 MB max cache cost
    }

    // MARK: - Sandboxed Directory

    var mediaDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("Pluto/JournalMedia", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }

    func fileURL(for filename: String) -> URL {
        mediaDirectory.appendingPathComponent(filename)
    }

    // MARK: - Ingestion & Downscaling Pipeline

    /// Imports and optimizes a photo from a source file URL on a background queue.
    func savePhoto(from sourceURL: URL) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = NSImage(contentsOf: sourceURL) else {
                    continuation.resume(returning: nil)
                    return
                }

                let filename = self.processAndWrite(image: image)
                continuation.resume(returning: filename)
            }
        }
    }

    /// Imports multiple photos in parallel.
    func savePhotos(from urls: [URL]) async -> [String] {
        await withTaskGroup(of: String?.self) { group in
            for url in urls {
                group.addTask {
                    await self.savePhoto(from: url)
                }
            }

            var results: [String] = []
            for await filename in group {
                if let filename {
                    results.append(filename)
                }
            }
            return results
        }
    }

    /// Imports a photo directly from raw Data.
    func savePhoto(from data: Data) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = NSImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }

                let filename = self.processAndWrite(image: image)
                continuation.resume(returning: filename)
            }
        }
    }

    // MARK: - Internal Processing & Atomic Write

    private func processAndWrite(image: NSImage) -> String? {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "summit_photo_\(UUID().uuidString.prefix(8))_\(timestamp).jpg"
        let targetURL = mediaDirectory.appendingPathComponent(filename)

        // Downscale image if larger than 2560px for 4K crispness with minimal disk footprint
        let resizedImage = downscaleImageIfNeeded(image, maxDimension: 2560)

        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            return nil
        }

        do {
            try jpegData.write(to: targetURL, options: .atomic)

            // Prime the memory cache
            memoryCache.setObject(resizedImage, forKey: filename as NSString, cost: jpegData.count)
            return filename
        } catch {
            return nil
        }
    }

    private func downscaleImageIfNeeded(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let aspectRatio = size.width / size.height
        var newSize: NSSize
        if aspectRatio > 1.0 {
            newSize = NSSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = NSSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    // MARK: - Fast Retrieval & Memory Caching

    /// Synchronously retrieves a photo from memory cache or disk.
    func loadPhoto(fileName: String) -> NSImage? {
        let key = fileName as NSString
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        let url = fileURL(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path),
              let diskImage = NSImage(contentsOf: url) else {
            return nil
        }

        memoryCache.setObject(diskImage, forKey: key)
        return diskImage
    }

    /// Asynchronously loads a photo without blocking the main actor.
    func loadPhotoAsync(fileName: String) async -> NSImage? {
        let key = fileName as NSString
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let url = self.fileURL(for: fileName)
                guard FileManager.default.fileExists(atPath: url.path),
                      let diskImage = NSImage(contentsOf: url) else {
                    continuation.resume(returning: nil)
                    return
                }

                self.memoryCache.setObject(diskImage, forKey: key)
                continuation.resume(returning: diskImage)
            }
        }
    }

    // MARK: - File Cleanup & Garbage Collection

    /// Permanently deletes a single photo file from disk and cache.
    func deletePhoto(fileName: String) {
        memoryCache.removeObject(forKey: fileName as NSString)
        let url = fileURL(for: fileName)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Permanently deletes multiple photo files.
    func deletePhotos(fileNames: [String]) {
        for name in fileNames {
            deletePhoto(fileName: name)
        }
    }
}
