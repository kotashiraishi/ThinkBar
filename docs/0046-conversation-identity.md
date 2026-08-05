## Issue 0046 - Conversation Identity

### Goal

Conversationを識別しやすくし、Sidebarの操作性を向上させる。

### Background

Sidebarにより複数Conversationを扱えるようになった。

しかし現在は、

- タイトルが "New Conversation" のまま
- AI回答生成中でもConversation行をクリックできる
- Conversationの識別性が低い

ため、操作性を改善する。

### Changes

- 最初のユーザー入力からConversationタイトルを自動生成する
- タイトルは初回のみ生成し、その後は維持する
- AI回答生成中はConversation一覧の選択を無効化する
- Toolbar、Sidebar、Menuの操作可否を統一する
- Active Conversationをより分かりやすく表示する

### Title generation

初回User Messageから短いタイトルを生成する。

例:

"0046の設計を相談したい"
→ "0046の設計"

"ホルンの高音について"
→ "ホルンの高音"

初期実装ではAI生成は行わず、
User Messageから簡易生成でよい。

### Design decisions

- タイトル生成はConversation作成時ではなく、最初の送信後に行う
- ユーザー編集機能は今回は実装しない
- タイトルはConversationに保存する
- Conversation選択可否はConversationActionStateなど共通Stateで管理する

### Verification

- 最初の送信後にタイトルが付く
- タイトルは再起動後も維持される
- New Conversation直後は仮タイトル表示
- AI回答生成中はSidebarのConversationを選択できない
- Toolbar、Menu、Sidebarの状態が一致する

- Xcode build成功
- Core tests成功
- git diff --check成功

### Future work

- AIによるタイトル生成
- Conversation名変更
- Conversation削除
- Conversation検索
- ピン留め

### Additional Cursor Notes

- タイトル生成は軽量なローカル処理とし、AI APIは利用しない。
- Conversation選択可否の判定は複数箇所へ重複実装しない。
- 既存Conversationとの互換性を維持する。
