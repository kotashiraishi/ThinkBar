Issue 0021 - Conversation Modes
Goal
用途に応じたAIモードを切り替えられるようにする。
Added / Modified / Deleted files
Modified
ThinkBar/ContentView.swift
Packages/ThinkBarCore/Sources/ThinkBarCore/OllamaProvider.swift
Added
なし
Deleted
なし
Design decisions
Built-in Modes
最初は以下の5つを実装する。
💬 General
🎺 Horn
💻 Swift
🐘 PHP
🏃 Run
Prompt
各モードは送信時にsystem prompt相当の指示を付与する。
例
Horn
You are an experienced professional horn teacher...

Swift
You are a senior Swift engineer...

など。
UI
画面上部にPicker(.segmented)または同等の標準UIを使用する。
選択中のモードが分かること。
Session
選択状態は起動中のみ保持。
永続保存しない。
Conversation
モード変更時も履歴は消さない。
新しい質問から新モードで回答する。
Preserve Existing Behavior
Streaming維持
Conversation維持
Auto Scroll維持
Global Shortcut維持
Out of Scope
カスタムモード
JSON読み込み
設定画面
アイコン変更
Acceptance Criteria
モードを切り替えられる
プロンプトがモードごとに変わる
Streamingは維持
ビルド成功
Coreテスト成功
Additional Instructions
プロンプト文字列は一か所にまとめて管理すること。
UI側へ長いプロンプトを書かないこと。
将来、カスタムモードを追加しやすい構造を意識すること。
必要以上のリファクタリングは行わないこと。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
