## Issue 0022c - Simplify Markdown Detection

### Goal

Markdownレンダリングをコードブロックを含む回答のみに限定し、通常の文章では改行を確実に保持する。

### Modified

- `ThinkBar/ContentView.swift`

### Design decisions

- `shouldRenderMarkdown()`はコードブロック（```）の検出のみ行う。
- コードブロックを含まない回答は常にプレーンテキスト表示する。
- `AttributedString(markdown:)`はコードブロックを含む回答にのみ使用する。
- Streaming、Auto Scroll、Conversation、Text Selectionは変更しない。

### Verification

- 通常の文章は改行が保持される。
- コードブロックを含む回答はMarkdown表示される。
- Xcode build成功。
- Core tests成功。

### Future work

- 将来的に必要であれば、表や引用などMarkdown判定を段階的に追加する。
