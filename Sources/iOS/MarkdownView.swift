import SwiftUI
import SwiftUI
import WebKit

// MarkdownをレンダリングするためのUIViewRepresentable
struct MarkdownView: UIViewRepresentable {
    var markdown: String
    
    func makeUIView(context: Context) -> WKWebView {
        // WKWebViewの設定
        let configuration = WKWebViewConfiguration()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
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
        // エスケープ処理
        let escapedMarkdown = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        
        // スタイルを適用したHTMLを作成
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <meta name="color-scheme" content="light dark">
            <!-- highlight.js のスタイルシート -->
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/styles/github.min.css">
            <script>
                // markdown-itとhighlight.jsを読み込む
                document.addEventListener('DOMContentLoaded', async () => {
                    try {
                        // highlight.jsを読み込む
                        const hljs = await import('https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/+esm');
                        // markdown-itを読み込む
                        const markdownit = await import('https://cdn.jsdelivr.net/npm/markdown-it@14.1.0/+esm');
                        
                        // markdown-itの設定
                        const md = markdownit.default({
                            html: false,
                            breaks: true,
                            linkify: true,
                            typographer: true,
                            highlight: function(str, lang) {
                                if (lang && hljs.default.getLanguage(lang)) {
                                    try {
                                        return hljs.default.highlight(str, { language: lang }).value;
                                    } catch (e) {
                                        console.error(e);
                                    }
                                }
                                return ''; // 言語が指定されていない場合は空文字を返す
                            }
                        });
                        
                        // Markdownをレンダリング
                        const markdownText = "\(escapedMarkdown)";
                        const result = md.render(markdownText);
                        document.getElementById('content').innerHTML = result;
                        
                        // コードブロックに対してハイライトを適用
                        document.querySelectorAll('pre code').forEach((block) => {
                            hljs.default.highlightElement(block);
                        });
                    } catch (error) {
                        console.error('Markdown rendering error:', error);
                        // エラーが発生した場合はプレーンテキストとして表示
                        document.getElementById('content').innerHTML = '<pre>' +
                            "\(escapedMarkdown)".replace(/&/g, '&amp;')
                                .replace(/</g, '&lt;')
                                .replace(/>/g, '&gt;') +
                            '</pre>';
                    }
                });
            </script>
            <style>
                :root {
                    color-scheme: light dark;
                }
                
                /* ライトモード（デフォルト）のスタイル */
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 18px;
                    line-height: 1.5;
                    margin: 0;
                    padding: 0 10px;
                    color: #000;
                    background-color: transparent;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    font-weight: bold;
                }
                
                h1 {
                    font-size: 32px;
                    margin-top: 20px;
                    margin-bottom: 10px;
                }
                
                h2 {
                    font-size: 28px;
                    margin-top: 18px;
                    margin-bottom: 9px;
                }
                
                h3 {
                    font-size: 24px;
                    margin-top: 16px;
                    margin-bottom: 8px;
                }
                
                h4 {
                    font-size: 22px;
                    margin-top: 14px;
                    margin-bottom: 7px;
                }
                
                h5 {
                    font-size: 20px;
                    margin-top: 12px;
                    margin-bottom: 6px;
                }
                
                h6 {
                    font-size: 18px;
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
                    color: #333;
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
                
                /* highlight.jsのスタイル調整 */
                pre {
                    margin: 0.5em 0;
                    border-radius: 5px;
                    padding: 10px;
                }
                
                pre code {
                    font-family: Menlo, Monaco, Consolas, monospace;
                    font-size: 0.9em;
                    padding: 0;
                    background-color: transparent;
                }
                
                /* ダークモードのスタイル */
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #e0e0e0;
                    }
                    
                    code {
                        background-color: #2a2a2a;
                        color: #e0e0e0;
                    }
                    
                    pre {
                        background-color: #2a2a2a;
                    }
                    
                    blockquote {
                        border-left-color: #555;
                        color: #aaa;
                    }
                    
                    a {
                        color: #58a6ff;
                    }
                    
                    th, td {
                        border-color: #555;
                    }
                    
                    th {
                        background-color: #2a2a2a;
                    }
                    
                    /* highlight.jsのダークモード調整 */
                    .hljs {
                        background: #2a2a2a;
                        color: #e0e0e0;
                    }
                    
                    .hljs-comment,
                    .hljs-quote {
                        color: #8292a2;
                    }
                    
                    .hljs-keyword,
                    .hljs-selector-tag,
                    .hljs-addition {
                        color: #8be9fd;
                    }
                    
                    .hljs-number,
                    .hljs-string,
                    .hljs-meta .hljs-meta-string,
                    .hljs-literal,
                    .hljs-doctag,
                    .hljs-regexp {
                        color: #50fa7b;
                    }
                    
                    .hljs-title,
                    .hljs-section,
                    .hljs-name,
                    .hljs-selector-id,
                    .hljs-selector-class {
                        color: #ffb86c;
                    }
                    
                    .hljs-attribute,
                    .hljs-attr,
                    .hljs-variable,
                    .hljs-template-variable,
                    .hljs-class .hljs-title,
                    .hljs-type {
                        color: #ff79c6;
                    }
                    
                    .hljs-symbol,
                    .hljs-bullet,
                    .hljs-subst,
                    .hljs-meta,
                    .hljs-meta .hljs-keyword,
                    .hljs-selector-attr,
                    .hljs-selector-pseudo,
                    .hljs-link {
                        color: #bd93f9;
                    }
                    
                    .hljs-built_in,
                    .hljs-deletion {
                        color: #f1fa8c;
                    }
                    
                    .hljs-formula {
                        background: #2a2a2a;
                    }
                    
                    .hljs-emphasis {
                        font-style: italic;
                    }
                    
                    .hljs-strong {
                        font-weight: bold;
                    }
                }
            </style>
        </head>
        <body>
            <div id="content">
                <!-- JavaScriptでMarkdownがレンダリングされます -->
            </div>
        </body>
        </html>
        """
        
        // HTMLをロード
        webView.loadHTMLString(styledHTML, baseURL: nil)
        
        // スクロール位置を先頭に設定
        webView.scrollView.setContentOffset(.zero, animated: false)
    }
}