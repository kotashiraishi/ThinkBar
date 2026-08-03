## Issue 0041b - Fix Long Assistant Response Rendering

### Goal

長いAI回答でも表示が途中で切れず、最後まで閲覧できるようにする。

### Background

0041aでレスポンス本文保持とMarkdown表示分離を行った。
保存されているassistant本文は正しい前提で、表示レイヤーの問題を修正する。

### Investigation

以下を確認する。

- ConversationStore保存内容
- ストリーミング完了後の表示State
- AssistantResponseFormatter
- Markdown描画処理
- ScrollView / Layout制約

### Design decisions

- 保存されるAIレスポンス本文は変更しない
- Markdown表示可否判定ロジックは維持
- 表示側だけ修正する
- 長文でもScrollView内で最後まで表示可能にする
- ストリーミング中と完了後で表示内容を一致させる

### Verification

以下のケースで確認する。

- 長い通常文章
- 長いMarkdown文章
- コードブロックを含む回答
- 箇条書きを大量に含む回答
- ストリーミング完了直後
- Conversation再読み込み後

確認項目:

- 最後の行まで表示される
- コピー内容と表示内容が一致する
- 再起動後も同じ内容が表示される

### Non-goals

- 回答本文の整形変更
- Markdown仕様変更
- 入力欄高さ変更（0042で対応予定）

### Verification

- Xcode build成功
- Core tests成功
- git diff --check成功
