よし、行きましょう！🚀
今の流れなら、このIssueで回答の見やすさが一段上がるはずです。
Issue 0022 - Markdown Rendering
Goal
AIの回答をMarkdownとして表示し、見出し・箇条書き・太字・コードブロックを読みやすくする。
Added / Modified / Deleted files
Added
なし
Modified
ThinkBar/ContentView.swift
Deleted
なし
Design decisions
Rendering
AttributedString(markdown:) を優先して使用する
Markdown解析に成功した場合はリッチテキストとして表示
解析に失敗した場合は通常のTextへフォールバック
Streaming
ストリーミング中は通常テキスト表示を維持する
応答完了時に一度だけMarkdown解析を行う
受信チャンクごとにMarkdown解析しない
Preserve Existing Behavior
Conversation履歴
Conversation Modes
Auto Scroll
Text Selection
Global Shortcut
を維持する。
Out of Scope
シンタックスハイライト
Mermaid
LaTeX
HTML
外部ライブラリ導入
Acceptance Criteria
完了した回答はMarkdownとして表示される
ストリーミング中は従来どおり高速表示される
コピー可能
Auto Scroll維持
ビルド成功
Coreテスト成功
Additional Instructions
ストリーミング中はMarkdown解析を行わないこと。
Markdown解析は応答完了時に一度だけ実施すること。
外部ライブラリは追加しない。
必要以上のリファクタリングは行わないこと。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
