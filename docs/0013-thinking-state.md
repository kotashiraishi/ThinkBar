Issue 0013 - Thinking State
Goal
AIの応答待ちを分かりやすくし、送信後すぐに次の入力を始められるようにする。
Requirements
Thinking State
AI呼び出し中は ProgressView と Thinking... を表示する
応答が返ったら通常の回答表示に切り替える
Immediate Input Clear
送信ボタン押下時に
lastPrompt = input
input = ""
を実行する。
AIの応答完了を待たず、入力欄はすぐ空にする。
Error Recovery
AI呼び出しに失敗した場合は
input = lastPrompt
として入力内容を復元する。
Preserve Existing Behavior
ThinkBarCore変更なし
AIProvider変更なし
IME動作を変更しない
ScrollView維持
Last Prompt表示維持
Out of Scope
Streaming
会話履歴
Markdown
Provider切替
Acceptance Criteria
送信直後に入力欄が空になる
Thinking... が表示される
応答後に回答へ置き換わる
エラー時は入力内容が復元される
ビルド成功
Coreテスト成功
Additional Instructions
ProgressView はmacOS標準のものを使用してください。
必要以上のリファクタリングは行わないでください。
既存UI構成は維持してください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
