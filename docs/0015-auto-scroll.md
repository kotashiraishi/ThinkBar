もちろんです。今回はそのままCursorへ貼れる形にしておきます。
Issue 0015 - Auto Scroll
Goal
ストリーミング中も常に最新の回答が表示されるよう、自動スクロールを追加する。
Requirements
Auto Scroll
ScrollViewReader を使用する
回答表示領域の末尾にスクロールアンカーを配置する
新しいチャンクが表示されるたびに末尾へスクロールする
回答完了後も末尾を表示したままにする
Preserve Existing Behavior
ストリーミング処理は変更しない
Thinking... の動作は変更しない
lastPrompt 表示は変更しない
ScrollView構成は維持する
ThinkBarCoreは変更しない
AIProviderは変更しない
Out of Scope
ストリーミングの更新頻度変更
レイアウトの揺れ改善
Markdown
会話履歴
キャンセル
Acceptance Criteria
ストリーミング中は常に最新行が見える
回答完了後も末尾が表示されている
既存機能は変更しない
アプリビルド成功
Coreテスト成功
Additional Instructions
ScrollViewReader を利用してください。
自動スクロール用のアンカー以外、UI構造はできるだけ変更しないでください。
必要以上のリファクタリングは行わないでください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
