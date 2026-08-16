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

// MARK: - YouTube HTML Generator

private func generateYouTubeHTML(videoID: String, volume: Double) -> String {
    """
    <!DOCTYPE html>
    <html>
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
        background: #000;
      }
      html, body {
        width: 100%;
        height: 100%;
        overflow: hidden;
      }
      iframe {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        border: none;
      }
    </style>
    </head>
    <body>
    <iframe
      id="yt-player"
      src="https://www.youtube.com/embed/\(videoID)?autoplay=1&playsinline=1&loop=1&playlist=\(videoID)&controls=1&rel=0&modestbranding=1&enablejsapi=1"
      allow="autoplay; encrypted-media; fullscreen"
      allowfullscreen>
    </iframe>
    <script>
      function setVolume(vol) {
        var iframe = document.getElementById('yt-player');
        if (iframe && iframe.contentWindow) {
          iframe.contentWindow.postMessage(JSON.stringify({
            "event": "command",
            "func": "setVolume",
            "args": [vol * 100]
          }), "*");
        }
        var v = document.querySelector('video');
        if (v) { v.volume = vol; }
      }
    </script>
    </body>
    </html>
    """
}

// MARK: - YouTubeWebView for macOS

#if os(macOS)
struct YouTubeWebView: NSViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    class Coordinator: NSObject, WKNavigationDelegate {
        var currentVideoID: String = ""

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WKWebView provisional load failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView navigation failed: \(error.localizedDescription)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        // Fix 2: WKWebViewConfiguration with process pool & JIT/page preferences
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []

        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        config.processPool = WKProcessPool()

        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Init WKWebView with configured settings
        let webView = WKWebView(frame: .zero, configuration: config)

        // Fix 1: Custom User Agent (macOS Safari)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"

        // Fix 4: Assign navigation delegate
        webView.navigationDelegate = context.coordinator

        // Fix 1: Load HTML string with youtube.com origin
        let html = generateYouTubeHTML(videoID: videoID, volume: volume)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com")!)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only reload if the videoID has actually changed
        if context.coordinator.currentVideoID != videoID && !videoID.isEmpty {
            context.coordinator.currentVideoID = videoID
            DispatchQueue.main.async {
                let html = generateYouTubeHTML(videoID: videoID, volume: volume)
                nsView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com")!)
            }
        }

        // Update volume without resetting playback
        let js = "if (typeof setVolume === 'function') { setVolume(\(volume)); };"
        nsView.evaluateJavaScript(js, completionHandler: nil)
    }
}
#else
// MARK: - YouTubeWebView for iOS

struct YouTubeWebView: UIViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    class Coordinator: NSObject, WKNavigationDelegate {
        var currentVideoID: String = ""

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WKWebView provisional load failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView navigation failed: \(error.localizedDescription)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        config.processPool = WKProcessPool()

        let webView = WKWebView(frame: .zero, configuration: config)

        // Fix 1: Custom User Agent (iOS Safari)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        webView.navigationDelegate = context.coordinator

        let html = generateYouTubeHTML(videoID: videoID, volume: volume)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com")!)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentVideoID != videoID && !videoID.isEmpty {
            context.coordinator.currentVideoID = videoID
            DispatchQueue.main.async {
                let html = generateYouTubeHTML(videoID: videoID, volume: volume)
                uiView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com")!)
            }
        }

        let js = "if (typeof setVolume === 'function') { setVolume(\(volume)); };"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }
}
#endif
