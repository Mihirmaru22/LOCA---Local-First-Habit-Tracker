import SwiftUI
import WebKit

// MARK: - YouTubeWebView (Direct First-Party HTTP Navigation to eliminate Error 150/152/153)

#if os(macOS)
struct YouTubeWebView: NSViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Inject CSS & JS to hide YouTube controls and force 16:9 full cover
        let css = """
        * { margin: 0 !important; padding: 0 !important; overflow: hidden !important; }
        body, html { width: 100vw !important; height: 100vh !important; background: #000 !important; }
        .ytp-chrome-top, .ytp-chrome-bottom, .ytp-gradient-top, .ytp-gradient-bottom,
        .ytp-pause-overlay, .ytp-youtube-button, .ytp-show-cards-title, .ytp-watermark,
        .ytp-contextmenu, .ytp-cued-thumbnail-overlay {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
            pointer-events: none !important;
        }
        video, .html5-main-video {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            object-fit: cover !important;
        }
        """
        let userScript = WKUserScript(
            source: """
            var style = document.createElement('style');
            style.innerHTML = `\(css)`;
            document.head.appendChild(style);
            
            function ensurePlayback() {
                var v = document.querySelector('video');
                if (v) {
                    v.loop = true;
                    v.volume = \(volume);
                    if (v.paused) { v.play(); }
                }
            }
            setInterval(ensurePlayback, 1000);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        loadDirectURL(in: webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
        nsView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadDirectURL(in webView: WKWebView) {
        // Direct first-party URL request with real Referer & Origin to avoid null origin Error 152/153
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)?autoplay=1&mute=0&controls=0&loop=1&playlist=\(videoID)&playsinline=1&modestbranding=1&rel=0&iv_load_policy=3&enablejsapi=1") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Referer")
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Origin")
        webView.load(request)
    }
}
#else
struct YouTubeWebView: UIViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let css = """
        * { margin: 0 !important; padding: 0 !important; overflow: hidden !important; }
        body, html { width: 100vw !important; height: 100vh !important; background: #000 !important; }
        .ytp-chrome-top, .ytp-chrome-bottom, .ytp-gradient-top, .ytp-gradient-bottom,
        .ytp-pause-overlay, .ytp-youtube-button, .ytp-show-cards-title, .ytp-watermark {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
        }
        video, .html5-main-video {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            object-fit: cover !important;
        }
        """
        let userScript = WKUserScript(
            source: """
            var style = document.createElement('style');
            style.innerHTML = `\(css)`;
            document.head.appendChild(style);
            
            function ensurePlayback() {
                var v = document.querySelector('video');
                if (v) {
                    v.loop = true;
                    v.volume = \(volume);
                    if (v.paused) { v.play(); }
                }
            }
            setInterval(ensurePlayback, 1000);
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        loadDirectURL(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadDirectURL(in webView: WKWebView) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)?autoplay=1&mute=0&controls=0&loop=1&playlist=\(videoID)&playsinline=1&modestbranding=1&rel=0&iv_load_policy=3&enablejsapi=1") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Referer")
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Origin")
        uiView.load(request)
    }
}
#endif
