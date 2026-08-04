## Issue 0044 - New Conversation

### Goal

新しいConversationを作成し、現在のConversationとは独立した文脈で会話を開始できるようにする。

### Background

0043でConversationモデルとConversationStoreは複数Conversation対応となった。

今回はUIから新しいConversationを作成し、Active Conversationを切り替える最小機能を追加する。

Conversation一覧やSidebarは次Issueで実装する。

### Changes

- "New Conversation"アクションを追加
- 新しいConversationを生成する
- Active Conversationを新規Conversationへ切り替える
- Composerを空の状態にする
- Conversation表示を空にする
- Summaryは空で開始する
- 新規Conversationを保存する

### Conversation initialization

新しいConversationは以下で初期化する。

- 新しいUUID
- createdAt = now
- updatedAt = now
- title = "New Conversation"（仮）
- turns = []
- summary = ""
- summaryCoveredTurnCount = 0

### Design decisions

- New Conversationは現在のConversationを削除しない
- Active Conversationのみ切り替える
- Provider設定・Model設定・Debug設定は引き継ぐ
- SummaryはConversationごとに独立する
- ConversationStoreSnapshotのAPIを利用し、UIから配列を直接操作しない

### UI

今回は最小実装とする。

以下のいずれかで十分。

- Toolbarボタン
- Menu
- Command

デザインは次Issueで整理する。

### Non-goals

今回は以下を実装しない。

- Conversation一覧
- Sidebar
- Conversation削除
- Conversationタイトル変更
- タイトル自動生成
- Conversation検索

### Verification

以下を確認する。

- New Conversationで空画面になる
- 入力すると新Conversationへ保存される
- 元Conversationは保持される
- Active Conversationが更新される
- 再起動後も両Conversationが保存される
- SummaryがConversationごとに独立する

- Xcode build成功
- Core tests成功
- git diff --check成功

### Future work

- Conversation Sidebar
- Conversation切替
- タイトル自動生成
- Conversation削除
- Conversation検索

### Additional Cursor Notes

- UI変更は最小限とする。
- 既存Conversationを破壊しない。
- Active Conversation切替処理はConversationStoreSnapshotの責務とする。
- 将来Sidebarから同じAPIを利用できるよう、新規Conversation生成ロジックをUIへ埋め込まない。
