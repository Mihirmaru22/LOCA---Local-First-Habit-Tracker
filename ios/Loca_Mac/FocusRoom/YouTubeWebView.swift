import SwiftUI
import WebKit

// MARK: - YouTubeWebView (Cross-platform iOS & macOS)

#if os(macOS)
struct YouTubeWebView: NSViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        loadVideo(in: webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
        nsView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadVideo(in webView: WKWebView) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)?autoplay=1&loop=1&playlist=\(videoID)&controls=0&mute=0&playsinline=1&rel=0&showinfo=0&modestbranding=1") else { return }
        let request = URLRequest(url: url)
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
        let webView = WKWebView(frame: .zero, configuration: config)
        loadVideo(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let js = "var v = document.querySelector('video'); if (v) { v.volume = \(volume); };"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadVideo(in webView: WKWebView) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)?autoplay=1&loop=1&playlist=\(videoID)&controls=0&mute=0&playsinline=1&rel=0&showinfo=0&modestbranding=1") else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
#endif
