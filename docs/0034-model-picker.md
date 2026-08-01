## Issue 0034 - Model Picker

### Goal

現在選択中のProviderに応じて利用モデルをSettings画面から選択できるようにする。

### Added / Modified / Deleted files

**Added**
- 必要に応じてModel情報を管理するCoreファイル（例: `ProviderModel.swift`）

**Modified**
- `ThinkBar/SettingsView.swift`
- `Packages/ThinkBarCore/Sources/ThinkBarCore/ProviderConfiguration.swift`
- 必要に応じて`ProviderFactory.swift`

**Deleted**
- なし

### Design decisions

- モデル設定は`ProviderConfiguration`で保持する
- Providerごとのモデル候補はProvider層で管理する
- Settings画面は現在選択中Providerのモデル一覧のみ表示する
- Provider変更時は対応するデフォルトモデルを自動選択する
- ContentViewはモデル情報を直接扱わない
- Provider生成は引き続きProviderFactoryのみが担当する

### Implementation guidance

- モデル名をSettingsViewへハードコードしない
- Providerごとのモデル情報はProvider層またはCore側のProvider定義へ集約する
- 将来的にAPIからモデル一覧を取得できる構造を意識する
- Provider追加時に既存UIの変更が最小となる設計を維持する
- 現時点では固定リストで構わないが、UIが取得方法に依存しないよう実装する

### Initial models

**Ollama**
- gemma3:4b
- llama3
- qwen2
```
