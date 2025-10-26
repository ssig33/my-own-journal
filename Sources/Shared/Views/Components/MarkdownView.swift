import SwiftUI
import WebKit

#if canImport(UIKit)
struct MarkdownView: UIViewRepresentable {
    var markdown: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML(from: markdown)
        webView.loadHTMLString(html, baseURL: nil)
        webView.scrollView.setContentOffset(.zero, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}
#elseif canImport(AppKit)
struct MarkdownView: NSViewRepresentable {
    var markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.openWindow = context.environment.openWindow
        let html = generateHTML(from: markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var openWindow: OpenWindowAction?

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    if url.scheme == nil && url.path.hasPrefix("/") {
                        var filePath = url.path
                        if filePath.hasPrefix("/") {
                            filePath = String(filePath.dropFirst())
                        }
                        openWindow?(value: filePath)
                        decisionHandler(.cancel)
                        return
                    }
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}
#endif

private func generateHTML(from markdown: String) -> String {
    let escapedMarkdown = markdown
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")

    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="color-scheme" content="light dark">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/styles/github.min.css">
        <script>
            document.addEventListener('DOMContentLoaded', async () => {
                const hljs = await import('https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/+esm');
                const markdownit = await import('https://cdn.jsdelivr.net/npm/markdown-it@14.1.0/+esm');
                const md = markdownit.default({
                    html: false,
                    breaks: true,
                    linkify: true,
                    typographer: true,
                    highlight: function(str, lang) {
                        if (lang && hljs.default.getLanguage(lang)) {
                            try {
                                return hljs.default.highlight(str, { language: lang }).value;
                            } catch (e) {}
                        }
                        return '';
                    }
                });
                const markdownText = "\(escapedMarkdown)";
                document.getElementById('content').innerHTML = md.render(markdownText);
                document.querySelectorAll('pre code').forEach((block) => {
                    hljs.default.highlightElement(block);
                });
            });
        </script>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                padding: 16px;
            }
            code {
                background-color: #f5f5f5;
                font-family: Menlo, monospace;
                padding: 2px 4px;
                border-radius: 3px;
            }
            pre {
                background-color: #f5f5f5;
                padding: 12px;
                border-radius: 6px;
                overflow-x: auto;
            }
            pre code {
                background-color: transparent;
                padding: 0;
            }
            @media (prefers-color-scheme: dark) {
                body {
                    color: #e0e0e0;
                    background-color: transparent;
                }
                code {
                    background-color: #2a2a2a;
                    color: #e0e0e0;
                }
                pre {
                    background-color: #2a2a2a;
                }
            }
        </style>
    </head>
    <body><div id="content"></div></body>
    </html>
    """
}
