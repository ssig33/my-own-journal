import SwiftUI
import WebKit
import Down

// MarkdownをレンダリングするためのUIViewRepresentable
struct MarkdownView: UIViewRepresentable {
    var markdown: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        
        // スクロールインジケータを非表示にする
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        // コンテンツの余白を調整
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let down = Down(markdownString: markdown)
        
        // Markdownをレンダリングするためのオプションを設定
        let options: DownOptions = [.hardBreaks, .safe]
        
        do {
            // MarkdownをHTMLに変換
            let html = try down.toHTML(options)
            
            // スタイルを適用したHTMLを作成
            let styledHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        font-size: 18px;
                        line-height: 1.5;
                        margin: 0;
                        padding: 0 10px;
                        color: #000;
                        background-color: transparent;
                    }
                    
                    h1 {
                        font-size: 32px;
                        font-weight: bold;
                        margin-top: 20px;
                        margin-bottom: 10px;
                    }
                    
                    h2 {
                        font-size: 28px;
                        font-weight: bold;
                        margin-top: 18px;
                        margin-bottom: 9px;
                    }
                    
                    h3 {
                        font-size: 24px;
                        font-weight: bold;
                        margin-top: 16px;
                        margin-bottom: 8px;
                    }
                    
                    h4 {
                        font-size: 22px;
                        font-weight: bold;
                        margin-top: 14px;
                        margin-bottom: 7px;
                    }
                    
                    h5 {
                        font-size: 20px;
                        font-weight: bold;
                        margin-top: 12px;
                        margin-bottom: 6px;
                    }
                    
                    h6 {
                        font-size: 18px;
                        font-weight: bold;
                        margin-top: 10px;
                        margin-bottom: 5px;
                    }
                    
                    p {
                        margin-top: 0;
                        margin-bottom: 10px;
                    }
                    
                    ul, ol {
                        margin-top: 0;
                        margin-bottom: 10px;
                        padding-left: 20px;
                    }
                    
                    li {
                        margin-bottom: 5px;
                    }
                    
                    code {
                        font-family: Menlo, Monaco, Consolas, monospace;
                        background-color: #f5f5f5;
                        padding: 2px 4px;
                        border-radius: 3px;
                    }
                    
                    pre {
                        background-color: #f5f5f5;
                        padding: 10px;
                        border-radius: 5px;
                        overflow-x: auto;
                    }
                    
                    pre code {
                        padding: 0;
                        background-color: transparent;
                    }
                    
                    blockquote {
                        border-left: 4px solid #ddd;
                        padding-left: 10px;
                        margin-left: 0;
                        color: #666;
                    }
                    
                    a {
                        color: #0366d6;
                        text-decoration: none;
                    }
                    
                    a:hover {
                        text-decoration: underline;
                    }
                    
                    table {
                        border-collapse: collapse;
                        width: 100%;
                        margin-bottom: 10px;
                    }
                    
                    th, td {
                        border: 1px solid #ddd;
                        padding: 8px;
                        text-align: left;
                    }
                    
                    th {
                        background-color: #f5f5f5;
                    }
                    
                    img {
                        max-width: 100%;
                        height: auto;
                    }
                </style>
            </head>
            <body>
                \(html)
            </body>
            </html>
            """
            
            // HTMLをロード
            webView.loadHTMLString(styledHTML, baseURL: nil)
            
            // スクロール位置を先頭に設定
            webView.scrollView.setContentOffset(.zero, animated: false)
        } catch {
            // Markdownのパースに失敗した場合はプレーンテキストとして表示
            let errorHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        font-size: 18px;
                        line-height: 1.5;
                        margin: 0;
                        padding: 0 10px;
                        color: #000;
                        background-color: transparent;
                    }
                </style>
            </head>
            <body>
                <pre>\(markdown)</pre>
            </body>
            </html>
            """
            webView.loadHTMLString(errorHTML, baseURL: nil)
        }
    }
}