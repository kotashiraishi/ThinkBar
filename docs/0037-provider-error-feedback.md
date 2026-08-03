## Issue 0037 - Provider Error Feedback

### Goal

AI実行時のProviderエラーをユーザーへ分かりやすく表示する。

### Design decisions

- 設定操作エラーは一時フィードバック表示
- AI回答生成エラーはConversation内へ表示
- エラー発生時も入力内容を保持する
- Provider固有エラーを共通Error型へ変換する
- 無反応に見える状態をなくす

### Error examples

- Ollama server unavailable
- Model not found
- OpenRouter API key missing
- Authentication failed
- Network error
- Timeout

### Implementation guidance

- ContentViewで個別エラー文字列を判定しない
- Provider層で意味のあるErrorを返す
- UI表示文言と内部Error情報を分離する
- 将来的なRetry実装を考慮する

### Verification

- モデル不存在時に原因が表示される
- Ollama停止時に原因が表示される
- OpenRouter APIエラーが確認できる
- 入力内容が失われない
- Xcode build成功
- Core tests成功

### Future work

- Retryボタン
- Regenerate
- Error log viewer
