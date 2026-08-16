import SwiftUI
import WebKit

// MARK: - YouTube Video ID Extraction Helper

public func extractYouTubeID(from urlString: String) -> String? {
    let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    // Direct 11-character video ID
    if trimmed.count == 11 && !trimmed.contains("/") && !trimmed.contains("?") && !trimmed.contains("&") {
        return trimmed
    }

    if let url = URL(string: trimmed) {
        // 1. https://youtu.be/ABC123
        if url.host?.contains("youtu.be") == true {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !path.isEmpty {
                return path.components(separatedBy: "?").first?.components(separatedBy: "&").first
            }
        }

        // 2. https://www.youtube.com/embed/ABC123
        if url.path.contains("/embed/") {
            let components = url.path.components(separatedBy: "/embed/")
            if let last = components.last, !last.isEmpty {
                return last.components(separatedBy: "?").first?.components(separatedBy: "&").first
            }
        }

        // 3. https://www.youtube.com/watch?v=ABC123 or https://m.youtube.com/watch?v=ABC123
        if let components = URLComponents(string: trimmed),
           let queryItems = components.queryItems,
           let vItem = queryItems.first(where: { $0.name == "v" })?.value,
           !vItem.isEmpty {
            return vItem
        }
    }

    // 4. Regex fallback
    let pattern = "(?<=watch\\?v=|/videos/|/embed/|youtu.be/|/v/|/e/|watch\\?feature=player_embedded&v=)[a-zA-Z0-9_-]{11}"
    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
       let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
       let range = Range(match.range, in: trimmed) {
        return String(trimmed[range])
    }

    return nil
}

// MARK: - YouTubeWebView (Cross-Platform iOS & macOS)

#if os(macOS)
struct YouTubeWebView: NSViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    class Coordinator: NSObject {
        var currentVideoID: String = ""
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        // FIX 2: WKWebViewConfiguration before init
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []

        #if os(macOS)
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        #endif

        let webView = WKWebView(frame: .zero, configuration: config)

        // FIX 1: Custom User Agent (macOS Safari)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"

        // FIX 3: Load correct embed URL
        loadEmbedURL(in: webView, for: videoID)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only reload if the videoID has actually changed
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            loadEmbedURL(in: nsView, for: videoID)
        }

        // Update volume without resetting playback
        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
        nsView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadEmbedURL(in webView: WKWebView, for id: String) {
        guard !id.isEmpty else { return }
        let embedURL = "https://www.youtube.com/embed/\(id)?autoplay=1&playsinline=1&loop=1&playlist=\(id)&controls=1&rel=0&modestbranding=1&enablejsapi=1"
        if let url = URL(string: embedURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
#else
struct YouTubeWebView: UIViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    class Coordinator: NSObject {
        var currentVideoID: String = ""
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        // FIX 2: WKWebViewConfiguration before init
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)

        // FIX 1: Custom User Agent (iOS Safari)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // FIX 3: Load correct embed URL
        loadEmbedURL(in: webView, for: videoID)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only reload if the videoID has actually changed
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            loadEmbedURL(in: uiView, for: videoID)
        }

        // Update volume without resetting playback
        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadEmbedURL(in webView: WKWebView, for id: String) {
        guard !id.isEmpty else { return }
        let embedURL = "https://www.youtube.com/embed/\(id)?autoplay=1&playsinline=1&loop=1&playlist=\(id)&controls=1&rel=0&modestbranding=1&enablejsapi=1"
        if let url = URL(string: embedURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
#endif
