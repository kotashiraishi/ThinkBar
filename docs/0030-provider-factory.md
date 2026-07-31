## Issue 0030 - Provider Factory

### Goal

ProviderConfigurationから適切なAIProviderを生成するFactoryを追加し、Provider生成責務を分離する。

### Added / Modified / Deleted files

**Added**
- `Packages/ThinkBarCore/Sources/ThinkBarCore/ProviderFactory.swift`
- `Packages/ThinkBarCore/Tests/ThinkBarCoreTests/ProviderFactoryTests.swift`

**Modified**
- `ThinkBar/ThinkBarApp.swift`

**Deleted**
- なし

### Design decisions

- Provider生成ロジックをFactoryへ移動する
- ContentViewは引き続き`AIProvider`インスタンスのみ受け取る
- 入力は`ProviderConfiguration`を使用する
- Ollama / OpenRouter両方の生成に対応する
- Provider固有の初期化処理をThinkBarAppから排除する
- 外部ライブラリは使用しない
- UI、設定保存、Keychainは今回対象外

### Expected structure

```
ProviderConfiguration
        |
        v
ProviderFactory
        |
        +---- OllamaProvider
        |
        +---- OpenRouterProvider
```

### Verification

- Xcode build成功
- Core tests成功
- OllamaProvider生成確認
- OpenRouterProvider生成確認
- 既存ContentView動作に変更なし

### Future work

- Provider Picker
- Model Picker
- Keychain保存
- 設定画面
- Provider追加時の動的登録

### 補足
- ProviderFactoryはCore側に配置し、UI層（ThinkBarAppやContentView）がProvider固有の知識を持たない設計を維持してください。
