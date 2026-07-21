Issue 0017 - Selectable Response
Goal
AIの回答を選択・コピーできるようにする。
Requirements
Response Selection
回答テキストをマウスで選択できるようにする
macOS標準のコピー（⌘C）を利用できるようにする
ストリーミング中も選択可能な状態を維持する
Optional
lastPrompt（You）のテキストも選択可能にしてよい
Preserve Existing Behavior
Auto Scrollは変更しない
Streamingは変更しない
Thinking表示は変更しない
Coreは変更しない
AIProviderは変更しない
Out of Scope
Copyボタン
Markdown
リッチテキスト
コードブロック
Acceptance Criteria
回答をドラッグで選択できる
⌘Cでコピーできる
既存機能は変更しない
アプリビルド成功
Coreテスト成功
Additional Instructions
SwiftUI標準機能（例：textSelection(.enabled)）で実現できる場合は、それを優先してください。
必要以上にNSTextViewなどへ置き換えないでください。
UI構造はできるだけ変更しないでください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
