Issue 0025 - Edit & Resend
Goal
過去のUserメッセージを編集し、その内容で再送信できるようにする。
Added / Modified / Deleted files
Modified
ThinkBar/ContentView.swift
Added
なし
Deleted
なし
Design decisions
User Message Editing
Userメッセージの右上に
✏️
または
Edit
ボタンを表示する。
Edit Flow
編集を押すと
そのUserメッセージを入力欄へコピー
入力欄へフォーカス
元のConversationは変更しない
つまり
You
今日はホルンの高音が苦しい

Assistant
...
↓
Edit
↓
入力欄
今日はホルンの高音が苦しい。
使っている楽器はシュミットのトリプルです。
Send
送信すると
新しいConversationとして追加する。
履歴を書き換えない。
Conversation Context
履歴送信は現在の仕様のまま。
つまり編集後も
通常の会話として扱う。
Preserve Existing Behavior
Streaming
Markdown
Modes
Attachments
Image Attachments
Auto Scroll
変更なし。
Out of Scope
Assistant回答の編集
履歴の削除
履歴の上書き
Undo
Acceptance Criteria
Userメッセージを編集できる
入力欄へコピーされる
フォーカスされる
再送信できる
元履歴は残る
ビルド成功
Coreテスト成功
Additional Instructions
まずは最小実装を優先する。
編集中であることを示すUIは不要。
Conversationを書き換えないこと。
必要以上のリファクタリングは行わないこと。
作業終了後は
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
を出力してください。
