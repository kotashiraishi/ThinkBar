よし、ではそのままCursorへ渡せる形でまとめます。
Issue 0016 - Smooth Streaming
Goal
ストリーミング中のレイアウトの揺れを減らし、より滑らかな表示にする。
Requirements
Buffered UI Updates
Ollamaから受信したチャンクは即座に受け取る
UI更新は約50〜100msごとにまとめて行う
UI更新時にまとめてresponseTextへ反映する
ストリーミング完了時は残っているバッファを即座に表示する
Preserve Existing Behavior
Auto Scrollは維持する
Thinking表示は維持する
Last Prompt表示は維持する
OllamaProviderのストリーミング実装は変更しない
AIProviderは変更しない
ThinkBarCoreは変更しない
Design Constraints
更新頻度の制御は ContentView側 で行うこと
OllamaProviderは受信したチャンクをそのまま通知する責務を維持すること
必要以上の抽象化やViewModelは追加しないこと
Out of Scope
Markdown
コードブロック
キャンセル
履歴
OpenAI対応
Acceptance Criteria
ストリーミング中の折り返しの揺れが軽減される
Auto Scrollは引き続き正常に動作する
ストリーミング完了時に全文が表示される
アプリビルド成功
Coreテスト成功
Additional Instructions
UI更新は人間が滑らかに感じられることを優先してください。
更新間隔は固定値（50〜100ms程度）で構いません。設定画面やカスタマイズ機能は追加しないでください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
