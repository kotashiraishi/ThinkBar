## Issue 0036 - Ollama Model Discovery

### Goal

Ollamaにインストール済みのモデル一覧を取得し、SettingsのModel Pickerへ動的表示できるようにする。

### Added / Modified / Deleted files

**Added**
- `OllamaModelService.swift`
- `OllamaModelServiceTests.swift`

**Modified**
- `OllamaProvider.swift`
- `ProviderModel.swift`
- `SettingsView.swift`
- 必要に応じて`ProviderFactory.swift`

**Deleted**
- なし

### Design decisions

- Ollamaの`/api/tags` APIを利用する
- インストール済みモデルのみPickerへ表示する
- Ollama以外のProviderのモデル管理には影響させない
- OpenRouterは従来の固定モデル一覧を維持する
- モデル取得失敗時は既存設定を維持する
- Provider層がモデル取得責務を持ち、UIは取得方法を意識しない

### Implementation guidance

- モデル取得処理をSettingsViewへ直接書かない
- `OllamaModelService`として分離する
- 将来的なOpenRouter Models API対応を考慮し、モデル取得インターフェースを拡張可能にする
- 取得結果は`ProviderModel`へ変換する
- モデル取得中はProgress表示可能な構造にする
- Ollama未起動時でもアプリ全体がクラッシュしないようにする

### UI behavior

- Ollama選択時:
  - 「Refresh」操作でモデル一覧取得
  - 取得したモデルをPicker表示
  - 現在選択中モデルが存在する場合は維持
  - 存在しない場合は先頭モデルまたはデフォルトへ変更

- OpenRouter選択時:
  - 既存固定モデル一覧を表示

### Verification

- Ollama起動中にモデル一覧取得できる
- インストール済みモデルのみ表示される
- 未インストールモデルを選択できない
- Ollama停止時も設定画面が利用可能
- Provider切替後も設定が正しく保持される
- Xcode build成功
- Core tests成功

### Future work

- 自動Refresh
- OllamaモデルPull UI
- モデル詳細表示（サイズ、パラメータ）
- OpenRouter Models API対応
- モデル検索
