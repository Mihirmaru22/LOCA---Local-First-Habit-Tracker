import SwiftUI
import WebKit

// MARK: - YouTubeWebView (Cross-platform iOS & macOS with Official YouTube IFrame Player API)

#if os(macOS)
struct YouTubeWebView: NSViewRepresentable {
    let videoID: String
    var volume: Double // 0.0 to 1.0

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

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
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          html, body {
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
            min-width: 177.77vh; /* 16:9 aspect cover */
            min-height: 56.25vw;
            transform: translate(-50%, -50%);
            pointer-events: none;
            border: none;
          }
        </style>
        </head>
        <body>
          <div id="player"></div>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            var player;
            var targetVolume = \(Int(volume * 100));

            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '\(videoID)',
                playerVars: {
                  'autoplay': 1,
                  'mute': 1,
                  'controls': 0,
                  'showinfo': 0,
                  'rel': 0,
                  'loop': 1,
                  'playlist': '\(videoID)',
                  'playsinline': 1,
                  'modestbranding': 1,
                  'iv_load_policy': 3,
                  'fs': 0,
                  'disablekb': 1,
                  'origin': 'https://www.youtube.com'
                },
                events: {
                  'onReady': onPlayerReady,
                  'onStateChange': onPlayerStateChange
                }
              });
            }

            function onPlayerReady(event) {
              event.target.playVideo();
              event.target.unMute();
              event.target.setVolume(targetVolume);
            }

            function onPlayerStateChange(event) {
              if (event.data === YT.PlayerState.ENDED) {
                player.playVideo();
              }
            }

            function setVolume(vol) {
              targetVolume = Math.round(vol * 100);
              if (player && player.setVolume) {
                if (targetVolume > 0) {
                  player.unMute();
                  player.setVolume(targetVolume);
                } else {
                  player.mute();
                }
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
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          html, body {
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
            pointer-events: none;
            border: none;
          }
        </style>
        </head>
        <body>
          <div id="player"></div>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            var player;
            var targetVolume = \(Int(volume * 100));

            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '\(videoID)',
                playerVars: {
                  'autoplay': 1,
                  'mute': 1,
                  'controls': 0,
                  'showinfo': 0,
                  'rel': 0,
                  'loop': 1,
                  'playlist': '\(videoID)',
                  'playsinline': 1,
                  'modestbranding': 1,
                  'iv_load_policy': 3,
                  'fs': 0,
                  'disablekb': 1,
                  'origin': 'https://www.youtube.com'
                },
                events: {
                  'onReady': onPlayerReady,
                  'onStateChange': onPlayerStateChange
                }
              });
            }

            function onPlayerReady(event) {
              event.target.playVideo();
              event.target.unMute();
              event.target.setVolume(targetVolume);
            }

            function onPlayerStateChange(event) {
              if (event.data === YT.PlayerState.ENDED) {
                player.playVideo();
              }
            }

            function setVolume(vol) {
              targetVolume = Math.round(vol * 100);
              if (player && player.setVolume) {
                if (targetVolume > 0) {
                  player.unMute();
                  player.setVolume(targetVolume);
                } else {
                  player.mute();
                }
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
