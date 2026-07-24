Issue 0024 - Paste Screenshot
Goal
クリップボードの画像を貼り付け（⌘V）できるようにし、画像をAIへのコンテキストとして送信できるようにする。
Added / Modified / Deleted files
Added
ThinkBar/ImageAttachment.swift
Modified
ThinkBar/ContentView.swift
Deleted
なし
Design decisions
ImageAttachment
画像専用モデルを追加する。
struct ImageAttachment: Identifiable {
    let id = UUID()
    let image: NSImage
}
（将来URLやPNGデータへ拡張可能な構造にする）
Paste
入力欄で
⌘V
を押したとき、
クリップボードに画像があれば添付する。
通常の文字列ペーストは従来どおり。
UI
画像が添付されたら
🖼 Screenshot
または小さなサムネイルを表示。
×で削除可能。
Send
今回はまだ画像をOllamaへ送らない。
代わりに
Image attached:
Screenshot

Question:
...
というダミーコンテキストを送る。
つまり、
画像添付UIだけ先に作る。
Preserve Existing Behavior
File Attachment
Conversation
Streaming
Modes
Markdown
変更なし。
Out of Scope
Vision Model
PNG送信
複数画像
ドラッグ画像
Acceptance Criteria
⌘Vで画像添付できる
テキストペーストは壊さない
UI表示
削除可能
ビルド成功
Coreテスト成功
Additional Instructions
Vision APIはまだ呼ばない。
将来Ollama Visionへ接続しやすい設計にする。
NSTextViewへの移行は行わない。
必要以上のリファクタリングは行わない。
作業終了後は
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
を出力してください。
