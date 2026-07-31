## Issue 0028 - Migrate Ollama to Chat API

### Goal

Ollamaの `/api/generate` を `/api/chat` へ移行し、OpenRouterと同じメッセージベースの会話モデルへ統一する。

### Added / Modified / Deleted files

**Modified**
- `Packages/ThinkBarCore/Sources/ThinkBarCore/OllamaProvider.swift`
- `Packages/ThinkBarCore/Tests/ThinkBarCoreTests/OllamaProviderTests.swift`

**Added**
- なし

**Deleted**
- なし

### Design decisions

- `/api/generate`から`/api/chat`へ移行
- `prompt`文字列生成を廃止
- `messages`配列を組み立てて送信
- `system`メッセージへModeと言語ポリシーを設定
- `user` / `assistant`履歴をそのままmessagesへ変換
- ストリーミングは`stream: true`を維持
- 既存Conversation Mode・履歴件数・UIは変更しない
- OpenRouterと同じ会話モデル構造に揃える

### Verification

- Xcode build成功
- Core tests成功
- General/Horn/Swift/PHP/Runの各Modeで会話継続を確認
- General Modeでユーザー入力のオウム返しが改善されることを確認

### Future work

- OpenAI / Claude / Gemini Providerとのmessages共通化
- Provider共通ConversationBuilderの導入
- Tool Calling対応
- Vision入力対応

### git diff --stat（想定）

```text
OllamaProvider.swift      | ~120 ++++++++++++++++++++++++------------
OllamaProviderTests.swift |  ~60 ++++++++++++++++
2 files changed, 約120 insertions(+), 約50 deletions(-)
```
