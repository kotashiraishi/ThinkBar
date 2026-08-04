## Issue 0043 - Conversation Model Separation

### Goal

現在の単一Conversation前提の構造を、複数Conversation対応可能な内部モデルへ変更する。

UI変更は行わず、データモデルと保存層のみを対応させる。

### Background

現在は1つの会話履歴を継続的に利用している。

しかし、今後以下のような用途を想定している。

- ThinkBar開発相談
- ホルン練習相談
- 日常的な質問
- その他テーマ別の会話

Conversationごとに独立したContextとSummaryを持てる構造が必要。

### Changes

- Conversationを独立したエンティティとして管理する
- Conversationごとに一意なIDを持つ
- Conversationごとに以下を保持する

  - ID
  - 作成日時
  - 更新日時
  - 表示タイトル（仮）
  - ConversationTurns
  - Summary
  - Summary関連メタデータ

- ConversationStoreを複数Conversation保存対応へ変更
- Active Conversationという概念を追加
- 現在の会話は既存データから1件のConversationとして扱う

### Persistence

- 既存conversations.jsonとの後方互換性を維持する
- 起動時に旧形式の場合は単一Conversationとして読み込む
- 保存形式はversionを維持しながら拡張する
- 既存Conversation内容を失わない

### Design decisions

- SummaryはConversation単位で管理する
- Provider設定、Model設定、Debug設定などアプリ全体設定はConversationから分離する
- ConversationContextBuilderはConversation単位でContextを生成する
- UI変更は次Issue以降で行う

### Non-goals

今回は以下を実装しない。

- New Conversationボタン
- Conversation一覧表示
- Sidebar
- Conversation切替UI
- タイトル自動生成

### Verification

以下を確認する。

- 既存conversationが起動後も表示される
- 既存Summaryが維持される
- 既存メッセージが失われない
- 保存・読み込みが正常
- version違いの処理が正常
- 新しいConversationモデルのUnit Test追加

- Xcode build成功
- Core tests成功
- git diff check成功

### Additional Cursor Notes

- UI層の変更は最小限にする。
- Provider層、AI送信処理は変更しない。
- 既存のConversationContextBuilderとの責務境界を維持する。
- 将来Conversation切替UIを追加できるよう、Active Conversationの取得・更新処理を独立させる。
