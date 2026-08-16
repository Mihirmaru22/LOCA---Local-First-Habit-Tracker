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

// MARK: - Direct Embed URL Builder

public func buildEmbedURL(videoID: String) -> URL {
    let urlString = "https://www.youtube-nocookie.com/embed/\(videoID)" +
        "?autoplay=1&loop=1&playlist=\(videoID)" +
        "&controls=0&disablekb=1&fs=0" +
        "&iv_load_policy=3&rel=0&modestbranding=1" +
        "&showinfo=0&autohide=1&playsinline=1" +
        "&enablejsapi=1&cc_load_policy=0&cc_lang_pref=off" +
        "&vq=hd720"
    return URL(string: urlString)!
}

// MARK: - Configuration & UserScript Builder

private func buildConfig(coordinator: WKScriptMessageHandler) -> WKWebViewConfiguration {
    let config = WKWebViewConfiguration()
    config.mediaTypesRequiringUserActionForPlayback = []
    config.processPool = WKProcessPool()

    let pagePrefs = WKWebpagePreferences()
    pagePrefs.allowsContentJavaScript = true
    config.defaultWebpagePreferences = pagePrefs

    #if os(macOS)
    config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
    #elseif os(iOS)
    config.allowsInlineMediaPlayback = true
    #endif

    // Script A: Browser API Spoofing (atDocumentStart)
    let spoofScript = WKUserScript(
        source: """
            window.chrome = {
                runtime: { connect(){}, sendMessage(){} },
                loadTimes(){ return {}; },
                csi(){ return {}; }
            };
            window.googletag = window.googletag || { cmd: [] };
            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
            Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
            Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
        """,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(spoofScript)

    // Script B: UI Removal & Direct Main-Frame Video Styler (atDocumentEnd)
    let hideControlsScript = WKUserScript(
        source: """
            var s = document.createElement('style');
            s.textContent = `
                .ytp-chrome-top, .ytp-chrome-bottom,
                .ytp-gradient-top, .ytp-gradient-bottom,
                .ytp-watermark, .ytp-title, .ytp-title-channel,
                .ytp-pause-overlay, .ytp-large-play-button,
                .ytp-cued-thumbnail-overlay,
                .ytp-endscreen-content, .ytp-endscreen-element,
                .ytp-cards-teaser, .ytp-ce-element,
                .ytp-youtube-button, .branding-img,
                .ytp-caption-window-container, .captions-text,
                .ytp-caption-segment, .ytp-share-button,
                .ytp-watch-later-button, .iv-branding,
                .ytp-spinner, .annotation, .video-annotations,
                .ytp-overflow-panel, .ytp-upnext,
                .ytp-more-videos-view, .ytp-button,
                .ytp-prev-button, .ytp-next-button,
                .html5-video-player .ytp-chrome-controls {
                    display: none !important;
                    opacity: 0 !important;
                    visibility: hidden !important;
                    pointer-events: none !important;
                }

                /* Nuclear option for center overlay controls */
                .ytp-cued-thumbnail-overlay,
                .ytp-cued-thumbnail-overlay-image,
                .ytp-large-play-button,
                .ytp-large-play-button-bg,
                .ytp-pause-overlay,
                .ytp-pause-overlay-container,
                .ytp-chrome-controls,
                .ytp-prev-button,
                .ytp-next-button,
                .ytp-play-button,
                .ytp-youtube-button,
                .ytp-wordmark-text,
                .ytp-watermark,
                #movie_player .ytp-chrome-bottom,
                #movie_player .ytp-chrome-top {
                    display: none !important;
                    opacity: 0 !important;
                    visibility: hidden !important;
                    pointer-events: none !important;
                    width: 0 !important;
                    height: 0 !important;
                }
                
                /* Force video to fill frame — no iframe compositing issues now */
                video, .html5-main-video {
                    width: 100vw !important;
                    height: 100vh !important;
                    object-fit: cover !important;
                    position: fixed !important;
                    top: 0 !important; left: 0 !important;
                    -webkit-transform: translateZ(0) !important;
                    will-change: transform !important;
                }
                
                body, html, .html5-video-container {
                    background: #000 !important;
                    overflow: hidden !important;
                }
                
                /* Remove click area that shows controls on hover */
                .html5-video-container {
                    pointer-events: none !important;
                }
            `;
            document.head.appendChild(s);

            // Instant MutationObserver for 0ms DOM insertion suppression
            var observer = new MutationObserver(function(mutations) {
                ['.ytp-chrome-top','.ytp-chrome-bottom','.ytp-large-play-button',
                 '.ytp-pause-overlay','.ytp-pause-overlay-container',
                 '.ytp-chrome-controls','.ytp-button','.ytp-watermark',
                 '.ytp-youtube-button','.ytp-gradient-top','.ytp-gradient-bottom',
                 '.ytp-play-button','.ytp-prev-button','.ytp-next-button'
                ].forEach(function(sel) {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.style.cssText += 
                            'display:none!important;opacity:0!important;visibility:hidden!important;width:0!important;height:0!important;';
                    });
                });
            });

            if (document.body) {
                observer.observe(document.body, { 
                    childList: true, 
                    subtree: true 
                });
            }
            
            // Continuous fast sweep — YouTube re-injects UI after events
            setInterval(function() {
                ['.ytp-chrome-top',
                 '.ytp-chrome-bottom',
                 '.ytp-watermark',
                 '.ytp-title',
                 '.ytp-title-text',
                 '.ytp-large-play-button',
                 '.ytp-large-play-button-bg',
                 '.ytp-pause-overlay',
                 '.ytp-pause-overlay-container',
                 '.ytp-caption-window-container',
                 '.captions-text',
                 '.ytp-endscreen-content',
                 '.ytp-gradient-bottom',
                 '.ytp-gradient-top',
                 '.ytp-upnext',
                 '.ytp-button',
                 '.ytp-prev-button',
                 '.ytp-next-button',
                 '.ytp-play-button',
                 '.ytp-chrome-controls',
                 '.ytp-youtube-button',
                 '.ytp-wordmark-text',
                 '.ytp-watermark',
                 '.html5-endscreen',
                 '.ytp-ce-element',
                 '.ytp-endscreen-element'].forEach(function(sel) {
                    document.querySelectorAll(sel).forEach(function(el) {
                        el.style.cssText += 
                            'display:none!important;opacity:0!important;visibility:hidden!important;width:0!important;height:0!important;';
                    });
                });
            }, 200);
        """,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false
    )
    config.userContentController.addUserScript(hideControlsScript)

    // Script C: Error State Listener
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
    config.userContentController.add(coordinator, name: "youtubeError")

    return config
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
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.parent.showFallback = true
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.parent.showFallback = true
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = buildConfig(coordinator: context.coordinator)

        let webView = WKWebView(
            frame: NSRect(x: 0, y: 0, width: 1280, height: 720),
            configuration: config
        )

        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        webView.setValue(false, forKey: "drawsBackground")
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.black.cgColor
        webView.navigationDelegate = context.coordinator

        // Direct main-frame URL load with Referer and Origin headers
        var request = URLRequest(url: buildEmbedURL(videoID: videoID))
        request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Referer")
        request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Origin")
        webView.load(request)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.currentVideoID != videoID && !videoID.isEmpty {
            context.coordinator.currentVideoID = videoID
            DispatchQueue.main.async {
                self.showFallback = false
                var request = URLRequest(url: buildEmbedURL(videoID: self.videoID))
                request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Referer")
                request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Origin")
                nsView.load(request)
            }
        }

        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
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
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.parent.showFallback = true
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WKWebView navigation failed: \(error.localizedDescription)")
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.parent.showFallback = true
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = buildConfig(coordinator: context.coordinator)

        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 1280, height: 720),
            configuration: config
        )

        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.navigationDelegate = context.coordinator

        var request = URLRequest(url: buildEmbedURL(videoID: videoID))
        request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Referer")
        request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Origin")
        webView.load(request)
        context.coordinator.currentVideoID = videoID

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self

        if context.coordinator.currentVideoID != videoID && !videoID.isEmpty {
            context.coordinator.currentVideoID = videoID
            DispatchQueue.main.async {
                self.showFallback = false
                var request = URLRequest(url: buildEmbedURL(videoID: self.videoID))
                request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Referer")
                request.setValue("https://www.youtube-nocookie.com", forHTTPHeaderField: "Origin")
                uiView.load(request)
            }
        }

        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }
}
#endif
