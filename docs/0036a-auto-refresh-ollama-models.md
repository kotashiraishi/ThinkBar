## Issue 0036a - Auto Refresh Ollama Models

### Goal

Settings画面表示時にOllamaモデル一覧を自動取得する。

### Modified files

- `ThinkBar/SettingsView.swift`

### Design decisions

- Settings画面初回表示時にOllamaモデル取得を自動実行する
- Refreshボタンは手動再取得用として維持する
- 取得中はProgress表示する
- 取得成功時のみモデル一覧を更新する
- 取得失敗・空結果の場合は既存設定を維持する
- OpenRouterのモデル取得処理には影響させない
- モデル取得ロジックは引き続き`OllamaModelService`へ集約する

### Implementation guidance

- SwiftUIの`.task`等を利用して初回表示時に実行する
- Ollama選択時のみモデル取得を行う
- SettingsViewはAPI通信詳細を意識しない
- 既に取得済みの場合の不要な通信は避けてもよい
- Provider切替時には必要に応じて再取得する

### Verification

- Settings初回表示時にモデル一覧が表示される
- Refreshボタンで再取得できる
- Ollama停止時でもSettingsが利用できる
- 既存のモデル選択状態が維持される
- OpenRouter設定に影響しない
- Xcode build成功
- Core tests成功

### Future work

- バックグラウンド更新
- モデルキャッシュ
- モデル詳細表示
- モデルPull UI
