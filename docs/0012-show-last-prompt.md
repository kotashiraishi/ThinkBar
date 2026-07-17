Issue 0012 - Show Last Prompt
Goal
回答を読んでいるときでも、直前に何を質問したか分かるようにする。
Requirements
Store Last Prompt
@State private var lastPrompt = "" を追加
送信開始時に lastPrompt = input
成功時のみ入力欄をクリア
失敗時は入力欄を保持（現状維持）
Show Last Prompt
回答欄の上に表示する
lastPrompt が空なら表示しない
回答欄と同じように読みやすいレイアウトにする
ラベルは "You" とする
Preserve Existing Behavior
ThinkBarCoreは変更しない
AIProviderは変更しない
IMEの動作を変更しない
ScrollViewは維持する
Out of Scope
履歴
複数ターン会話
Thinking表示
Streaming
Markdown
Acceptance Criteria
回答の上に直前の質問が表示される
送信成功後は入力欄がクリアされる
既存機能はそのまま
ビルド成功
Coreテスト成功
Additional Instructions
lastPrompt は 1件だけ保持してください。
履歴管理やViewModel化は行わず、最小変更で実装してください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary

