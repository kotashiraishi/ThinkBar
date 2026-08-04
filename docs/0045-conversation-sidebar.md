## Issue 0045 - Conversation Sidebar

### Goal

保存済みConversationを一覧表示し、任意のConversationへ切り替えられるSidebarを追加する。

### Background

0043で複数Conversation対応のデータモデルを導入し、
0044でNew Conversation作成とActive切替を実装した。

現在は過去Conversationへ戻るUIがないため、
保存済みConversationを一覧し、切り替えられる操作を追加する。

### Changes

- Conversation一覧を表示するSidebarを追加
- Active Conversationを視覚的に識別できるようにする
- Conversation選択時にActive Conversationを切り替える
- 選択したConversationのturnsとSummaryを表示する
- Conversation切替前に現在の入力・turnsを安全に保存する
- 再起動後も最後にActiveだったConversationを復元する
- New Conversation操作をSidebarからも実行可能にする

### Layout

基本構成:

Sidebar
- New Conversation
- Conversation一覧

Main Content
- Conversation表示
- Composer

### Conversation list

各Conversation行には最低限以下を表示する。

- title
- updatedAtを基準にした並び順
- Active状態

初期実装では補助情報は最小限でよい。

### Sorting

- updatedAtの降順
- Active Conversationも通常の並び順に従う
- 新規Conversationは作成直後に上部へ表示される

### Selection behavior

Conversation選択時:

1. 現在のComposer入力やConversation状態を必要に応じて保存
2. activeConversationIDを更新
3. 選択したConversationのturnsを表示
4. 選択したConversationのSummaryをContextへ利用
5. Composerは空にする

### Design decisions

- Conversation切替処理はConversationStoreSnapshotのAPIを利用する
- UIからconversations配列を直接変更しない
- SummaryはConversationごとに独立して扱う
- Provider / Model / Mode / Debug設定はアプリ全体設定として維持する
- Conversation一覧は表示用データへ変換して扱ってよい
- SidebarはmacOS標準のNavigationSplitViewまたは同等の構成を使用する

### Unsaved composer behavior

Conversation切替時にComposerへ未送信テキストがある場合は、
初期実装では以下のどちらかを採用する。

推奨:
- Conversationごとにdraft保存はまだ行わず、切替時にComposerをクリアする
- ただし誤消去防止のため、未送信テキストがある場合は切替前に確認を表示する

代替:
- 未送信テキストがある場合は切替をキャンセルする

無言で未送信テキストを破棄しないこと。

### Empty state

Conversationが存在しない場合:

- New Conversation作成を促す表示
- Composerは必要に応じて無効化または新規Conversation自動生成

通常起動時は少なくとも1件のConversationが存在する状態を維持する。

### Non-goals

今回は以下を実装しない。

- Conversation削除
- Conversation検索
- Conversationの手動並び替え
- タイトル自動生成
- Conversationアーカイブ
- ピン留め
- draftの永続保存

### Verification

以下を確認する。

- 複数ConversationがSidebarに表示される
- Conversationを選択すると内容が切り替わる
- 元Conversationへ戻れる
- Active Conversationが視覚的に分かる
- 新規Conversationが一覧上部へ表示される
- 再起動後もConversation一覧とActive状態が復元される
- ConversationごとのSummaryが混ざらない
- Conversation切替中にストリーミングや保存状態が壊れない
- 未送信Composerテキストを無言で失わない
- ⌘⇧NとToolbarのNew Conversationが引き続き動作する

- Xcode build成功
- Core tests成功
- git diff --check成功

### Future work

- Conversation title auto generation
- Conversation rename
- Conversation delete
- Conversation search
- Conversation archive
- Draft persistence
- Sidebar collapse / expand shortcut

### Additional Cursor Notes

- 既存のConversationStoreSnapshotとActive Conversation APIを利用する。
- UI層からConversation配列を直接編集しない。
- Conversation切替と保存処理を一箇所へ集約する。
- 既存Conversationのデータ損失を最優先で防ぐ。
- Sidebar導入によってComposer、Streaming、Auto Scrollの挙動を壊さない。
- まず一覧表示と切替を完成させ、タイトル生成や削除は別Issueへ分ける。
