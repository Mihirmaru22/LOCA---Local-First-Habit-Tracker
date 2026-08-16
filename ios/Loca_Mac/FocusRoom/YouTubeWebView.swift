import SwiftUI
import WebKit

// MARK: - YouTubeWebView (Cross-platform iOS & macOS with Error 153 Prevention)

#if os(macOS)
struct YouTubeWebView: NSViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        loadVideoHTML(in: webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let js = "if (typeof setVolume === 'function') { setVolume(\(volume)); };"
        nsView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadVideoHTML(in webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            background-color: #000000;
          }
          #player {
            position: absolute;
            top: 50%;
            left: 50%;
            width: 100vw;
            height: 100vh;
            min-width: 177.77vh;
            min-height: 56.25vw;
            transform: translate(-50%, -50%);
            border: none;
          }
        </style>
        </head>
        <body>
          <iframe id="player"
            src="https://www.youtube.com/embed/\(videoID)?autoplay=1&mute=0&controls=0&loop=1&playlist=\(videoID)&enablejsapi=1&origin=https://www.youtube.com&playsinline=1&rel=0&iv_load_policy=3&modestbranding=1"
            allow="autoplay; encrypted-media; picture-in-picture"
            allowfullscreen>
          </iframe>
          <script>
            function setVolume(vol) {
              var iframe = document.getElementById('player');
              if (iframe && iframe.contentWindow) {
                iframe.contentWindow.postMessage(JSON.stringify({
                  "event": "command",
                  "func": "setVolume",
                  "args": [vol * 100]
                }), "*");
              }
            }
          </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
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
        loadVideoHTML(in: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let js = "if (typeof setVolume === 'function') { setVolume(\(volume)); };"
        uiView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func loadVideoHTML(in webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            background-color: #000000;
          }
          #player {
            position: absolute;
            top: 50%;
            left: 50%;
            width: 100vw;
            height: 100vh;
            min-width: 177.77vh;
            min-height: 56.25vw;
            transform: translate(-50%, -50%);
            border: none;
          }
        </style>
        </head>
        <body>
          <iframe id="player"
            src="https://www.youtube.com/embed/\(videoID)?autoplay=1&mute=0&controls=0&loop=1&playlist=\(videoID)&enablejsapi=1&origin=https://www.youtube.com&playsinline=1&rel=0&iv_load_policy=3&modestbranding=1"
            allow="autoplay; encrypted-media; picture-in-picture"
            allowfullscreen>
          </iframe>
          <script>
            function setVolume(vol) {
              var iframe = document.getElementById('player');
              if (iframe && iframe.contentWindow) {
                iframe.contentWindow.postMessage(JSON.stringify({
                  "event": "command",
                  "func": "setVolume",
                  "args": [vol * 100]
                }), "*");
              }
            }
          </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
}
#endif
