## Issue 0029 - Provider Configuration

### Goal

AI Providerの設定情報を管理する仕組みを追加し、将来的なProvider切替に備える。

### Added / Modified / Deleted files

**Added**
- `Packages/ThinkBarCore/Sources/ThinkBarCore/ProviderConfiguration.swift`

**Modified**
- 必要に応じてProvider生成部分

**Deleted**
- なし

### Design decisions

- Provider種別をenumで管理
- Provider固有設定を構造体で保持
- UI変更は行わない
- 既存のOllamaProvider/OpenRouterProviderは維持
- 実際の切替UIは次Issue以降で実装
- APIキー保存はKeychain対応まで仮管理

### Example

```swift
enum ProviderKind {
    case ollama
    case openRouter
}

struct ProviderConfiguration {
    let kind: ProviderKind
    let model: String
    let apiKey: String?
}
```

### Verification

- Xcode build成功
- Core tests成功
- 既存Provider動作に影響しない

### Future work

- Provider Picker
- Model Picker
- Keychain保存
- 設定画面

Provider生成責務をContentViewから分離してください。ContentViewはAIProviderインスタンスを受け取るだけにし、Provider固有の初期化処理を持たない構造を維持してください。
