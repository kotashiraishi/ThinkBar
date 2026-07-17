このままだとCursorが迷うところが一つあります。
それは
UIはどうやって stream() を呼ぶの？

です。
今は ContentView が any AIProvider を持っているはずなので、
provider.ask(...)
しか呼べません。
私ならここをもう少し明確にします。
私がCursorに渡すIssue
Issue 0014 - Streaming Response
Goal
OllamaのストリーミングAPIを利用し、回答をリアルタイムに表示する。
Requirements
OllamaProvider
stream(_:, onChunk:) async throws を追加する
/api/generate を stream: true で呼び出す
JSON Lines形式のレスポンスを逐次読み取る
response フィールドをチャンクごとに onChunk へ渡す
done == true で終了する
UI
OllamaProvider利用時のみ stream() を使用する
Thinking... は最初のチャンク受信まで表示
最初のチャンク受信後に回答表示へ切り替える
チャンク受信ごとに回答へ追記する
スクロールUIは維持する
Preserve Existing Behavior
AIProvider プロトコルは変更しない
ask() はそのまま残す
FakeAIProvider は変更しない
Coreの既存テストを壊さない
Out of Scope
キャンセル
Markdown
履歴
OpenAI
Provider切替
Acceptance Criteria
回答がリアルタイムに増えていく
完了時に正常終了する
ビルド成功
Coreテスト成功
Additional Instructions
AIProviderをストリーミング対応へ変更しないこと。
必要以上の抽象化を追加しないこと。
OllamaProvider固有機能として実装すること。
作業終了後はいつものサマリーを出力すること。
