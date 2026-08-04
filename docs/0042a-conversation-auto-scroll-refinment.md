## Issue 0042a - Conversation Auto Scroll Refinement

### Goal

Conversationの自動スクロール挙動を改善し、長文回答の可読性を向上させる。

### Background

現在は以下の場合でもscrollToBottom()が実行される。

- Composer高さ変更
- AIストリーミング更新

そのため、

- 入力欄が伸びるたびConversationが動く
- AI回答を途中まで読んでいる最中でも最下部へ戻される

というUXになっている。

### Changes

- Composer高さ変更ではscrollToBottom()を実行しない
- AIストリーミング中は、ユーザーが最下部付近にいる場合のみ自動追従する
- ユーザーが上へスクロールしている場合は自動追従を停止する
- ユーザーが最下部へ戻ると自動追従を再開する
- 新規Userメッセージ送信時の自動スクロールは維持する

### Design decisions

Conversationのスクロール位置はユーザー操作を優先する。

Composerのレイアウト変更はConversationスクロールへ影響を与えない。

AI回答は「読める速度」で表示されることを優先し、ユーザーが過去メッセージを閲覧中はスクロール位置を変更しない。

### Implementation guidance

- scrollBottom（または同等の値）を利用して最下部判定を行う
- 最下部判定には数px程度の許容値を設けてもよい
- Composer高さ変更イベントとConversation更新イベントを分離する
- scrollToBottom()呼び出し条件を一箇所へ集約する

### Verification

以下を確認する。

- Composerが2〜10行へ伸びてもConversation位置が変わらない
- AI回答中、最下部にいる場合は自動追従する
- AI回答中、途中までスクロールすると自動追従しない
- 回答終了までその位置を維持する
- 最下部へ戻ると以降のストリーミングは再び追従する
- 新規送信時は従来どおり最下部へ移動する

### Non-goals

- Conversationレイアウト変更
- Composer UI変更
- Summary／Context変更

### Future work

- 「↓ New messages」ボタン追加
- 未読メッセージ数表示
- スムーズスクロールアニメーション

### Additional Cursor Notes

- Core層、Provider層には変更を加えない。
- Conversation UXのみを改善する。
- スクロール判定ロジックは今後「New messages」ボタンでも利用できるよう独立させる。
