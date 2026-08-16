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

        // 2. https://www.youtube.com/embed/ABC123 or https://www.youtube-nocookie.com/embed/ABC123
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

private func generateYouTubeHTML(videoID: String) -> String {
    """
    <!DOCTYPE html>
    <html>
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      * { margin:0; padding:0; background:#000; box-sizing: border-box; }
      html, body { width:100%; height:100%; overflow:hidden; }
      iframe { position:fixed; top:0; left:0; width:100%; height:100%; border:none; }
    </style>
    </head>
    <body>
    <iframe
      id="yt-player"
      src="https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&loop=1&playlist=\(videoID)&controls=0&disablekb=1&fs=0&iv_load_policy=3&rel=0&modestbranding=1&showinfo=0&autohide=1&playsinline=1&enablejsapi=1"
      allow="autoplay; encrypted-media; fullscreen; picture-in-picture"
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

// MARK: - YouTube Scripts & Configuration Builder

private func makeConfiguredWKWebView() -> (WKWebViewConfiguration, WKUserScript, WKUserScript, WKUserScript) {
    let config = WKWebViewConfiguration()
    config.mediaTypesRequiringUserActionForPlayback = []

    let pagePrefs = WKWebpagePreferences()
    pagePrefs.allowsContentJavaScript = true
    config.defaultWebpagePreferences = pagePrefs
    config.processPool = WKProcessPool()

    #if os(macOS)
    config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    #elseif os(iOS)
    config.allowsInlineMediaPlayback = true
    #endif

    // Script 1: Inject browser API spoof script at document start
    let spoofScript = WKUserScript(
        source: """
            // Spoof Chrome browser environment
            window.chrome = {
                runtime: {
                    connect: function() {},
                    sendMessage: function() {}
                },
                loadTimes: function() { return {}; },
                csi: function() { return {}; }
            };
            
            // Spoof googletag (ad platform YouTube checks for)
            window.googletag = window.googletag || {};
            window.googletag.cmd = window.googletag.cmd || [];
            
            // Override WebView detection
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            });
            
            // Spoof plugins array
            Object.defineProperty(navigator, 'plugins', {
                get: () => [1, 2, 3, 4, 5]
            });
            
            // Spoof languages
            Object.defineProperty(navigator, 'languages', {
                get: () => ['en-US', 'en']
            });
        """,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(spoofScript)

    // Script 2: Force-hide all YouTube chrome, controls, titles, watermarks & gradients
    let hideControlsScript = WKUserScript(
        source: """
            var style = document.createElement('style');
            style.textContent = `
                /* Hide ALL YouTube player UI chrome */
                .ytp-chrome-top,
                .ytp-chrome-bottom,
                .ytp-gradient-top,
                .ytp-gradient-bottom,
                .ytp-watermark,
                .ytp-show-cards-title,
                .ytp-pause-overlay,
                .ytp-endscreen-content,
                .ytp-cards-teaser,
                .ytp-ce-element,
                .ytp-title,
                .ytp-title-channel,
                .ytp-share-button,
                .ytp-watch-later-button,
                .iv-branding,
                .ytp-spinner,
                .annotation,
                .video-annotations,
                .ytp-contextmenu,
                .ytp-overflow-panel,
                .branding-img,
                .ytp-youtube-button,
                .ytp-cued-thumbnail-overlay {
                    display: none !important;
                    opacity: 0 !important;
                    visibility: hidden !important;
                    pointer-events: none !important;
                }
                
                /* Ensure video fills frame with no gaps */
                video, .html5-main-video {
                    width: 100% !important;
                    height: 100% !important;
                    object-fit: cover !important;
                }
                
                /* Remove click-to-pause overlay that reveals controls */
                .html5-video-container {
                    pointer-events: none !important;
                }
            `;
            document.head.appendChild(style);

            // Re-run periodically because YouTube re-injects UI after interactions
            setInterval(function() {
                var elements = document.querySelectorAll(
                    '.ytp-chrome-top, .ytp-chrome-bottom, .ytp-watermark, ' +
                    '.ytp-pause-overlay, .ytp-endscreen-content, .ytp-title, .ytp-gradient-top, .ytp-gradient-bottom'
                );
                elements.forEach(function(el) {
                    el.style.setProperty('display', 'none', 'important');
                    el.style.setProperty('opacity', '0', 'important');
                    el.style.setProperty('visibility', 'hidden', 'important');
                });
            }, 2500);
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(hideControlsScript)

    // Script 3: Error detection user script polling for YouTube error state
    let errorDetectScript = WKUserScript(
        source: """
            setInterval(function() {
                var errorScreen = document.querySelector('.ytp-error');
                if (errorScreen && errorScreen.style.display !== 'none') {
                    window.webkit.messageHandlers.youtubeError.postMessage(
                        errorScreen.innerText || 'playback_error'
                    );
                }
            }, 2000);
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(errorDetectScript)

    return (config, spoofScript, hideControlsScript, errorDetectScript)
}

// MARK: - YouTubeWebView (Main SwiftUI Container with Fallback UI)

struct YouTubeWebView: View {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    @State private var showFallback: Bool = false

    var body: some View {
        ZStack {
            YouTubeWebViewRepresentable(videoID: videoID, volume: volume, showFallback: $showFallback)

            if showFallback {
                VStack(spacing: 12) {
                    Image(systemName: "play.slash.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("YouTube playback restricted")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text("This video does not allow in-app embedding.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))

                    Button {
                        #if os(macOS)
                        if let url = URL(string: "https://youtu.be/\(videoID)") {
                            NSWorkspace.shared.open(url)
                        }
                        #else
                        if let url = URL(string: "https://youtu.be/\(videoID)") {
                            UIApplication.shared.open(url)
                        }
                        #endif
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "safari.fill")
                            Text("Open in Safari")
                        }
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Representables per Platform

#if os(macOS)
struct YouTubeWebViewRepresentable: NSViewRepresentable {
    let videoID: String
    var volume: Double
    @Binding var showFallback: Bool

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: YouTubeWebViewRepresentable
        var currentVideoID: String = ""

        init(_ parent: YouTubeWebViewRepresentable) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "youtubeError" {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.parent.showFallback = true
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WKWebView provisional load failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView navigation failed: \(error.localizedDescription)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let (config, _, _, _) = makeConfiguredWKWebView()
        config.userContentController.add(context.coordinator, name: "youtubeError")

        let webView = WKWebView(frame: .zero, configuration: config)

        // Real macOS Safari User Agent
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator

        let html = generateYouTubeHTML(videoID: videoID)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.currentVideoID != videoID && !videoID.isEmpty {
            context.coordinator.currentVideoID = videoID
            DispatchQueue.main.async {
                self.showFallback = false
                let html = generateYouTubeHTML(videoID: self.videoID)
                nsView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
            }
        }

        let js = "if (typeof setVolume === 'function') { setVolume(\(volume)); };"
        nsView.evaluateJavaScript(js, completionHandler: nil)
    }
}
#else
struct YouTubeWebViewRepresentable: UIViewRepresentable {
    let videoID: String
    var volume: Double
    @Binding var showFallback: Bool

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: YouTubeWebViewRepresentable
        var currentVideoID: String = ""

        init(_ parent: YouTubeWebViewRepresentable) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "youtubeError" {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.parent.showFallback = true
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WKWebView provisional load failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView navigation failed: \(error.localizedDescription)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let (config, _, _, _) = makeConfiguredWKWebView()
        config.userContentController.add(context.coordinator, name: "youtubeError")

        let webView = WKWebView(frame: .zero, configuration: config)

        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.navigationDelegate = context.coordinator

        let html = generateYouTubeHTML(videoID: videoID)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.currentVideoID != videoID && !videoID.isEmpty {
            context.coordinator.currentVideoID = videoID
            DispatchQueue.main.async {
                self.showFallback = false
                let html = generateYouTubeHTML(videoID: self.videoID)
                uiView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
            }
        }

        let js = "if (typeof setVolume === 'function') { setVolume(\(volume)); };"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }
}
#endif
