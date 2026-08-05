## Issue 0046a - Incremental Conversation Rendering

### Goal

Conversation切替時の体感速度を改善する。

長いConversationでも直近の会話を素早く表示し、過去の履歴は必要になったタイミングで段階的に表示する。

### Background

Conversation切替時に全turnを一度に描画しているため、
履歴が長いConversationでは表示開始まで時間がかかる。

保存形式はそのまま維持し、
描画対象のみ段階的に増やすことで体感速度を改善する。

### Changes

- Conversation切替直後は直近30turnのみ表示する
- 上方向へスクロールし、先頭付近へ到達したら過去20turnを追加表示する
- 以降も同様に段階的に追加表示する
- 最新メッセージ表示位置は維持する
- Summary・Context生成は従来どおりConversation全体を利用する
- 保存形式は変更しない

### Design decisions

- 全Conversationはメモリ上へ読み込んだままとする
- UI表示のみ段階的に行う
- VStack構成は維持する
- LazyVStackへ戻さない
- 追加描画時にスクロール位置が飛ばないよう配慮する

### Loading behavior

Conversation切替

↓

表示:
最新30turn

↓

ユーザーが上へスクロール

↓

追加:
20turn

↓

必要に応じて繰り返す

### Non-goals

今回は以下を実装しない。

- 保存形式変更
- Conversationファイル分割
- 真のディスク遅延ロード
- Context生成変更
- Summary生成変更

### Verification

以下を確認する。

- 長いConversationへの切替が速くなる
- 最新メッセージがすぐ表示される
- 上へスクロールすると過去履歴が追加表示される
- スクロール位置が飛ばない
- Summary・Contextは従来どおり動作する
- ストリーミング表示へ影響しない
- Xcode build成功
- Core tests成功
- git diff --check成功

### Future work

- Conversationファイル分割
- 真のLazy Loading
- 表示キャッシュ
- 仮想スクロール

### Additional Cursor Notes

- Store層や保存形式は変更しない。
- 描画対象だけを管理するPresentation層を追加してもよい。
- UI更新は最小限とし、Conversation全体のデータは保持する。
- 将来の仮想スクロールへ移行しやすい責務分離を意識する。
