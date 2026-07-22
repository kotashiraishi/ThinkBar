Issue 0019 - Conversation History
Goal
ThinkBarを一問一答ではなく、会話として利用できるようにする。
Requirements
Conversation Model
会話履歴を@Stateで保持する
1件の会話はUser
Assistant
のペアで保持する

現在回答中のAssistantも履歴の最後に表示する
UI
最新の質問だけではなく履歴全体を表示する
User / Assistant を明確に区別する
現在のスクロールUIを利用する
Auto Scrollを維持する
回答は引き続き選択可能
Streaming
ストリーミング中は最後のAssistantだけ更新する
新しいチャンクで履歴全体を作り直さない
Session
アプリ起動中のみ保持
保存機能は作らない
件数制限は不要（将来追加）
Preserve Existing Behavior
OllamaProvider変更なし
AIProvider変更なし
Core変更なし
Global Shortcut変更なし
Out of Scope
永続保存
Markdown
複数チャット
タイトル生成
Acceptance Criteria
会話として表示される
Auto Scrollは維持
Streamingは維持
回答は選択可能
ビルド成功
Coreテスト成功
Additional Instructions
lastPromptは削除して構いません。
履歴がlastPromptの役割を自然に置き換える設計を優先してください。
ViewModelは追加せず、現在の構成を維持してください。
必要以上のリファクタリングは行わないでください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
