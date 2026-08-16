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
      src="https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&loop=1&playlist=\(videoID)&controls=0&cc_load_policy=0&cc_lang_pref=off&disablekb=1&fs=0&iv_load_policy=3&rel=0&modestbranding=1&showinfo=0&autohide=1&playsinline=1&enablejsapi=1"
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

private func makeConfiguredWKWebView() -> (WKWebViewConfiguration, WKUserScript, WKUserScript, WKUserScript, WKUserScript) {
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
                /* Center playback controls */
                .ytp-cued-thumbnail-overlay,
                .ytp-cued-thumbnail-overlay-image,
                .ytp-large-play-button,
                .ytp-play-button,
                .ytp-button,
                .ytp-prev-button,
                .ytp-next-button,
                .html5-video-player .ytp-chrome-controls { 
                    display: none !important; 
                }

                /* Subtitles and captions */
                .ytp-caption-window-container,
                .captions-text,
                .caption-window,
                .ytp-subtitles-button,
                .ytp-caption-segment,
                div.ytp-caption-window-rollup,
                span.ytp-caption-segment { 
                    display: none !important; 
                }

                /* Bottom "More videos" / YouTube branding bar */
                .ytp-youtube-button,
                .ytp-wordmark-text,
                .branding-img-container,
                .ytp-share-button-visible,
                .html5-endscreen,
                .ytp-upnext,
                .ytp-upnext-autoplay,
                .ytp-scroll-min,
                .iv-drawer,
                .ytp-more-videos-view { 
                    display: none !important; 
                }

                /* Thumbnail card preview bottom right */
                .ytp-videowall-still,
                .ytp-endscreen-element,
                .ytp-ce-element,
                .ytp-ce-covering-overlay,
                .ytp-ce-expanding-overlay,
                .ytp-ce-covering-image,
                .ytp-ce-expanding-image { 
                    display: none !important; 
                }

                /* General Chrome & Watermarks */
                .ytp-chrome-top,
                .ytp-chrome-bottom,
                .ytp-gradient-top,
                .ytp-gradient-bottom,
                .ytp-watermark,
                .ytp-show-cards-title,
                .ytp-pause-overlay,
                .ytp-endscreen-content,
                .ytp-cards-teaser,
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
                .branding-img {
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

                /* Force hardware compositing on video and iframe */
                iframe, video, .html5-main-video, .html5-video-container {
                    -webkit-transform: translateZ(0) !important;
                    transform: translateZ(0) !important;
                    -webkit-backface-visibility: hidden !important;
                    will-change: transform !important;
                }
            `;
            document.head.appendChild(style);

            // Re-run periodically because YouTube re-injects UI after interactions
            setInterval(function() {
                var elements = document.querySelectorAll(
                    '.ytp-chrome-top, .ytp-chrome-bottom, .ytp-watermark, ' +
                    '.ytp-pause-overlay, .ytp-endscreen-content, .ytp-title, .ytp-gradient-top, .ytp-gradient-bottom, ' +
                    '.ytp-caption-window-container, .captions-text, .caption-window, .ytp-large-play-button, .ytp-cued-thumbnail-overlay'
                );
                elements.forEach(function(el) {
                    el.style.setProperty('display', 'none', 'important');
                    el.style.setProperty('opacity', '0', 'important');
                    el.style.setProperty('visibility', 'hidden', 'important');
                });
            }, 2000);
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(hideControlsScript)

    // Script 3: Late UI hiding script to fight late YouTube injections
    let lateHideScript = WKUserScript(
        source: """
            setTimeout(function() {
                var style = document.createElement('style');
                style.textContent = `
                    .ytp-chrome-top, .ytp-chrome-bottom,
                    .ytp-gradient-top, .ytp-gradient-bottom,
                    .ytp-watermark, .ytp-title,
                    .ytp-pause-overlay, .ytp-endscreen-content,
                    .ytp-cued-thumbnail-overlay,
                    .ytp-large-play-button,
                    .ytp-youtube-button, .branding-img,
                    .ytp-caption-window-container,
                    .captions-text, .ytp-caption-segment {
                        display: none !important;
                        opacity: 0 !important;
                    }
                `;
                document.head.appendChild(style);
            }, 1500);

            setInterval(function() {
                ['.ytp-chrome-top','.ytp-chrome-bottom',
                 '.ytp-watermark','.ytp-title',
                 '.ytp-caption-window-container',
                 '.captions-text'].forEach(function(sel) {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.style.cssText += 'display:none!important;opacity:0!important;';
                    });
                });
            }, 1000);
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(lateHideScript)

    // Script 4: Error detection user script polling for YouTube error state
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

    return (config, spoofScript, hideControlsScript, lateHideScript, errorDetectScript)
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
        let (config, _, _, _, _) = makeConfiguredWKWebView()
        config.userContentController.add(context.coordinator, name: "youtubeError")

        // Fix 1: Real non-zero initial frame
        let webView = WKWebView(
            frame: NSRect(x: 0, y: 0, width: 1280, height: 720),
            configuration: config
        )

        // Fix 2: Force video compositor onto correct layer
        webView.setValue(false, forKey: "drawsBackground")
        webView.layer?.backgroundColor = NSColor.black.cgColor
        webView.wantsLayer = true

        // Real macOS Safari User Agent
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator

        let html = generateYouTubeHTML(videoID: videoID)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
        context.coordinator.currentVideoID = videoID

        // Fix 3: Reload once the view has been placed in the window and has real bounds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !webView.bounds.isEmpty {
                let html = generateYouTubeHTML(videoID: self.videoID)
                webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com")!)
            }
        }

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
        let (config, _, _, _, _) = makeConfiguredWKWebView()
        config.userContentController.add(context.coordinator, name: "youtubeError")

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1280, height: 720), configuration: config)

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
