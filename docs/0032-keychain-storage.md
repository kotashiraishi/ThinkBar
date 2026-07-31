## Issue 0032 - Keychain Storage

### Goal

OpenRouterなどのAPIキーをmacOS Keychainへ安全に保存・取得できる仕組みを追加する。

### Added / Modified / Deleted files

**Added**
- `Packages/ThinkBarCore/Sources/ThinkBarCore/KeychainService.swift`
- `Packages/ThinkBarCore/Tests/ThinkBarCoreTests/KeychainServiceTests.swift`

**Modified**
- 必要に応じてOpenRouter設定関連

**Deleted**
- なし

### Design decisions

- APIキー保存にはmacOS Keychainを使用する
- UserDefaultsや平文ファイルには保存しない
- Keychain操作は専用Serviceへ分離する
- ProviderはKeychainの存在を直接意識しない
- ProviderConfigurationにはAPIキー参照結果を渡す
- OllamaなどAPIキー不要Providerには影響させない
- UI変更は今回対象外

### Implementation guidance

- Keychainアクセス処理をCore層へ分離する
- ContentViewやThinkBarAppから直接Keychain APIを呼ばない
- Provider固有の認証情報管理を共通化できる設計にする
- 将来的に複数ProviderのAPIキーを保存できる構造にする

### Expected API

例:

```swift
protocol SecretStorage {
    func save(key: String, value: String) throws
    func load(key: String) throws -> String?
    func delete(key: String) throws
}
```

### Verification

- APIキー保存成功
- APIキー取得成功
- 削除成功
- 未保存時はnilを返す
- 既存Provider動作に影響なし
- Core tests成功

### Future work

- APIキー入力UI
- Provider設定画面
- Model Picker
- Keychain Access Group対応
