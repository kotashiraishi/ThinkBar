## Issue 0039 - Conversation Summary Support

### Goal

Conversationに要約情報を保持できるようにし、AI Context生成時に利用可能な基盤を追加する。

### Modified files

- Conversation model
- ConversationStore
- ConversationContextBuilder
- Debug Console（必要に応じて）

### Design decisions

- ConversationにSummaryフィールドを追加する
- Summaryは表示用Conversationとは分離して扱う
- Summaryは永続保存対象とする
- 既存v2保存形式を拡張する
- 既存Conversationとの互換性を維持する
- Summary生成処理自体は今回は実装しない
- Summaryが存在する場合のみContextBuilderが利用する

### Context behavior

現在:

System
+
直近5ターン
+
現在の質問

変更後:

System
+
Conversation Summary（存在時）
+
直近5ターン
+
現在の質問

### Implementation guidance

- ContentViewでSummary処理を行わない
- ContextBuilderがSummary利用判断を担当する
- ConversationStoreで保存・復元できるようにする
- 将来AIによるSummary生成へ置き換え可能な設計にする
- Summary未設定時の挙動は現在と完全互換にする

### Debug Console

Debug Mode ON時:

- Summary内容を表示する
- SummaryがContextへ含まれたか確認できるようにする

### Verification

- 既存Conversationを読み込める
- SummaryありConversationを保存・復元できる
- Summaryなしの場合、回答品質・Contextが変化しない
- Summaryありの場合、Debug Consoleで確認できる
- Core tests成功
- Xcode build成功

### Future work

- 自動Summary生成
- 古い会話の自動圧縮
- Memory検索
- Conversationタイトル生成
Cursor向け追加注意もIssue内に含めていますが、特に重要なのはここです。
追加注意:

今回はSummary生成AIを実装しない。

目的は「Summaryという情報をContextに組み込める構造を作ること」であり、
現在の回答品質を変えないことを優先する。
