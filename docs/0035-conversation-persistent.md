## Issue 0035 - Conversation Persistence

### Goal

会話履歴をローカルへ保存し、アプリ再起動後も前回の会話を継続できるようにする。

### Added / Modified / Deleted files

**Added**
- `Packages/ThinkBarCore/Sources/ThinkBarCore/ConversationStore.swift`
- `Packages/ThinkBarCore/Tests/ThinkBarCoreTests/ConversationStoreTests.swift`

**Modified**
- `ThinkBar/ContentView.swift`

**Deleted**
- なし

### Design decisions

- 会話履歴をJSON形式でローカル保存する
- アプリ起動時に自動読み込みする
- 会話送信・応答完了時に自動保存する
- 会話の表示順・内容をそのまま復元する
- 添付ファイル・画像は今回保存対象外
- Conversation Mode、Provider、Model設定には影響しない
- 保存失敗時でもチャット利用は継続できる

### Implementation guidance

- 保存処理は`ContentView`から分離し、`ConversationStore`へ集約する
- `Codable`を利用してシンプルに実装する
- UIは保存方法を意識しない構造を維持する
- 将来の複数チャット対応を見据え、保存フォーマットは拡張しやすい構造にする
- ストリーミング中は保存せず、回答完了時のみ保存する
- 保存先パスをUIへハードコードしない
- 既存のConversationモデルの責務を増やしすぎない

### Storage

- macOS Application Support配下へ保存
- JSONファイル1つで管理
- 初回起動時は空の履歴を生成する

### Verification

- 新しい会話が保存される
- アプリ再起動後に復元される
- 複数会話が順番どおり復元される
- 保存失敗時もチャット継続可能
- Xcode build成功
- Core tests成功
- `git diff --check`成功

### Future work

- 複数チャット
```
