Issue 0023 - Drag & Drop Context
Goal
テキストファイルをドラッグ＆ドロップして、その内容を質問と一緒にAIへ送信できるようにする。
Added / Modified / Deleted files
Modified
ThinkBar/ContentView.swift
Added
ThinkBar/Attachment.swift
Deleted
なし
Design decisions
Attachment Model
新しく
struct Attachment: Identifiable {
    let id = UUID()
    let fileName: String
    let content: String
}
を追加する。
最初は1ファイルのみ対応。
ただし配列へ拡張しやすい設計にする。
Supported Files
対応する拡張子
txt
md
swift
php
json
log
yaml
yml
xml
すべてUTF-8として読み込む。
UI
ウィンドウへドラッグすると
📎 AppDelegate.swift
のように入力欄の上へ表示。
×ボタンで削除可能。
Send
送信時は
Attachment: AppDelegate.swift

<contents>

---

Question:
ユーザー入力
という形式で送る。
送信成功後は添付をクリアする。
送信失敗時は添付を保持する。
Preserve Existing Behavior
Streaming
Conversation
Markdown
Modes
Auto Scroll
Language Policy
変更なし。
Out of Scope
複数添付
PDF
画像
音声
ZIP
Acceptance Criteria
ドラッグ&ドロップできる
添付名が表示される
AIへ内容が送られる
送信成功で添付クリア
ビルド成功
Coreテスト成功
Additional Instructions
Attachmentは将来複数対応できるように設計すること。
ドラッグ&ドロップはSwiftUI標準APIを使用すること。
UTF-8読み込みに失敗した場合はユーザーへ分かるようにエラー表示すること。
必要以上のリファクタリングは行わないこと。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
