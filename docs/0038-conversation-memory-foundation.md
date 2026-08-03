## Issue 0038 - Conversation Memory Foundation

### Goal

長期会話を扱えるようにするため、Conversation履歴とAI送信用コンテキストを分離し、履歴要約の基盤を追加する。

### Design decisions

- 表示用Conversation履歴とAIへ送信するContextを分離する
- 全履歴を毎回Providerへ送信しない
- 直近の会話は原文を維持する
- 古い会話は要約データとして保持可能にする
- ConversationStoreの既存保存形式を拡張可能な形にする
- 既存の会話表示・編集機能は変更しない

### Implementation guidance

- ConversationモデルにAI Context用メタデータを追加する
- Providerへ渡す履歴生成処理を専用クラスへ分離する
- ContentViewで履歴加工を行わない
- 要約処理自体は今回必須ではない
- 将来的にAI Providerを利用した要約生成を追加できる設計にする

### Initial behavior

- 現在の直近5ターン送信方式を維持
- ContextBuilderを導入し、Providerへの入力生成を集約する
- 既存ConversationStoreとの互換性を維持する

### Verification

- 既存会話表示が変化しない
- Provider切替後も会話Contextが維持される
- 保存済みConversationを読み込める
- Core tests成功
- Xcode build成功

### Future work

- 古い会話の自動要約
- ユーザーMemory
- 検索型Memory（Embedding）
- テーマ別Conversation
- 会話タイトル生成
