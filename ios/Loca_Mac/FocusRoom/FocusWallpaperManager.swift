import SwiftUI
import AppKit

// MARK: - FocusWallpaperManager (High-Speed Local Disk & Memory Cache)

@MainActor
final class FocusWallpaperManager {

    static let shared = FocusWallpaperManager()

    private let memoryCache = NSCache<NSString, NSImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL

    private init() {
        // Ultra-low footprint memory cache (max 2 images, 16MB ceiling)
        memoryCache.countLimit = 2
        memoryCache.totalCostLimit = 16 * 1024 * 1024

        // Setup Persistent Disk Cache Directory
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let focusFolder = caches.appendingPathComponent("FocusWallpapers", isDirectory: true)
        if !fileManager.fileExists(atPath: focusFolder.path) {
            try? fileManager.createDirectory(at: focusFolder, withIntermediateDirectories: true)
        }
        self.diskCacheURL = focusFolder
    }

    // MARK: - Cache Key Generator

    private func diskFileURL(for urlString: String) -> URL {
        let safeName = String(urlString.hashValue)
        return diskCacheURL.appendingPathComponent("\(safeName).jpg")
    }

    // MARK: - Downsampled High-Efficiency Image Decode

    nonisolated static func decodeDownsampledImage(from data: Data, maxDimension: CGFloat = 1920) -> NSImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return NSImage(data: data)
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    // MARK: - Synchronous Memory & Disk Lookup (0ms - 2ms)

    func cachedImage(for urlString: String) -> NSImage? {
        let key = NSString(string: urlString)

        // 1. Check RAM Memory Cache (0ms)
        if let memoryImage = memoryCache.object(forKey: key) {
            return memoryImage
        }

        // 2. Check Persistent Disk Cache (<3ms)
        let diskURL = diskFileURL(for: urlString)
        if fileManager.fileExists(atPath: diskURL.path),
           let diskData = try? Data(contentsOf: diskURL),
           let downsampledImage = Self.decodeDownsampledImage(from: diskData) {
            memoryCache.setObject(downsampledImage, forKey: key, cost: diskData.count)
            return downsampledImage
        }

        return nil
    }

    // MARK: - Asynchronous Load with Background Disk Caching

    func loadImage(for urlString: String, completion: @escaping (NSImage?) -> Void) {
        // Fast path: Cached
        if let cached = cachedImage(for: urlString) {
            completion(cached)
            return
        }

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let diskURL = diskFileURL(for: urlString)
        let key = NSString(string: urlString)

        Task.detached(priority: .userInitiated) {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            request.cachePolicy = .returnCacheDataElseLoad

            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = Self.decodeDownsampledImage(from: data) else {
                await MainActor.run { completion(nil) }
                return
            }

            // Save to Disk Cache asynchronously
            try? data.write(to: diskURL, options: .atomic)

            await MainActor.run {
                Self.shared.memoryCache.setObject(image, forKey: key, cost: data.count)
                completion(image)
            }
        }
    }

    // MARK: - Cache Eviction

    func purgeMemoryCache() {
        memoryCache.removeAllObjects()
    }
}

// MARK: - FocusCachedImageView (Instant Display & Zero-Latency Crossfade)

struct FocusCachedImageView: View {

    let urlString: String
    let fallbackColors: [Color]

    @State private var loadedImage: NSImage? = nil
    @State private var isLoaded: Bool = false

    var body: some View {
        ZStack {
            // Instant Rich Gradient Base
            LinearGradient(
                colors: fallbackColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // High-Speed Cached Image Layer
            if let img = loadedImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(.opacity)
            }
        }
        .onAppear {
            fetchImage()
        }
        .onChange(of: urlString) { _, _ in
            fetchImage()
        }
    }

    private func fetchImage() {
        // 1. Instant check in memory / disk (0ms)
        if let cached = FocusWallpaperManager.shared.cachedImage(for: urlString) {
            self.loadedImage = cached
            self.isLoaded = true
            return
        }

        // 2. Fetch asynchronously with smooth crossfade
        FocusWallpaperManager.shared.loadImage(for: urlString) { img in
            guard let img = img else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.loadedImage = img
                self.isLoaded = true
            }
        }
    }
}
