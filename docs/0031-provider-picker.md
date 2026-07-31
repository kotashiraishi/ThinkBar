## Issue 0031 - Provider Picker

### Goal

アプリ内で使用するAI ProviderをOllama / OpenRouterから選択できるようにする。

### Added / Modified / Deleted files

**Added**
- 必要に応じてProvider設定管理用View

**Modified**
- `ThinkBar/ContentView.swift` または設定UI関連
- `ThinkBar/ThinkBarApp.swift`

**Deleted**
- なし

### Design decisions

- Provider選択状態は`ProviderConfiguration`として管理する
- Provider生成は引き続き`ProviderFactory`のみが担当する
- ContentViewはProvider固有処理を持たない
- 選択変更後は新しいProviderインスタンスを生成する
- 会話履歴は維持する
- UIは最小限のPickerから開始する

### Implementation guidance

- Provider名やモデル名を直接UIへ埋め込まない
- UI層は`ProviderKind`と`ProviderConfiguration`のみ扱う
- Provider追加時に既存UI変更が最小になる構造を維持する

### Verification

- Ollama/OpenRouter切替が可能
- 切替後の送信が正常動作
- 既存Conversation Modeが維持される
- Core tests成功

### Future work

- Model Picker
- Keychain保存
- 設定画面
- Provider別パラメータ設定`
