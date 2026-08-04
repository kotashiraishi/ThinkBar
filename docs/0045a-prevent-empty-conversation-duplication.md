## Issue 0045a - Prevent Empty Conversation Duplication

### Goal

空のConversationが複数作成されないよう、New Conversation操作の有効条件を整理する。

### Changes

- Active Conversationのturnsが空の場合、New Conversationを無効化する
- 1件以上のturnがある場合のみNew Conversationを有効化する
- AI回答生成中は従来どおり無効化する
- Toolbar、Menu、⌘⇧Nで同じ有効条件を使用する
- 空Conversationの自動削除や起動時クリーンアップは追加しない

### Design decisions

- 空Conversationは1件だけ存在可能
- 最初の送信完了後に次のNew Conversationを作成可能とする
- 有効条件はUIごとに重複実装せず、共通Stateまたは共通判定へ集約する

### Verification

- 空Conversation上ではToolbarのNew Conversationが無効
- メニューと⌘⇧Nも実行されない
- 最初の質問送信後はNew Conversationが有効になる
- 新規Conversation作成後は再び無効になる
- 既存Conversation切替後、turnsの有無に応じて状態が正しく変わる
- AI生成中は無効
- Xcode build成功
- Core tests成功
- git diff --check成功

### Additional Cursor Notes

- Conversation削除や保存形式変更は行わない。
- Toolbar、Menu、Commandで同じ有効条件を使う。
- UIからConversation配列を直接確認・変更せず、Active Conversationの状態から判定する。
