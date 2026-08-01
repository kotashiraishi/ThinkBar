## Issue 0033 - Provider Settings View

### Goal

Provider設定を管理する設定画面を追加する。

### Added / Modified / Deleted files

**Added**
- `ThinkBar/SettingsView.swift`

**Modified**
- `ThinkBar/ThinkBarApp.swift`
- 必要に応じてProvider設定管理部分

**Deleted**
- なし

### Design decisions

- Provider設定を専用Settings画面へ分離する
- Provider選択状態を表示・変更可能にする
- OpenRouter APIキー入力欄を追加する
- APIキーはKeychainへ保存する
- UIはKeychain APIへ直接依存しない
- Provider生成は引き続きProviderFactoryのみが担当する
- 会話履歴・Conversation Modeには影響させない

### Implementation guidance

- SettingsViewは設定編集のみを担当する
- Keychain操作は`SecretStorage`経由で行う
- APIキーをUserDefaultsや平文ファイルへ保存しない
- Provider固有の初期化処理をUIへ書かない
- Provider追加時にSettingsViewの変更を最小化できる構造を維持する
- 既存のProviderConfigurationを中心に状態管理する

### UI scope

今回対応:
- Provider選択
- OpenRouter APIキー入力
- 保存状態表示（必要なら）

今回対象外:
- Model Picker
- Temperature等のパラメータ
- 複数APIキー管理
- 高度なProvider設定

### Verification

- Settings画面を開ける
- Provider変更が反映される
- OpenRouter APIキーを保存できる
- Keychainから再取得できる
- 既存チャット機能に影響しない
- Core tests成功

### Future work

- Model Picker
- Provider別詳細設定
- 設定のエクスポート
- 複数Providerプロファイル

