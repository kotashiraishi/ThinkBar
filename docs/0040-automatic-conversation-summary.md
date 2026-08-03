## Issue 0040 - Automatic Conversation Summary

### Goal

長い会話でContextが肥大化しないよう、Conversation SummaryをAIで自動生成・更新できるようにする。

### Design decisions

- Summary生成はConversationRunner側で管理する
- ContentViewはSummary生成ロジックを持たない
- Summary更新は毎回ではなく条件付きで実行する
- 通常回答の速度低下を避ける
- Summary生成失敗時は既存Conversationを維持する

### Summary update trigger

以下の条件のいずれかを満たした場合にSummary更新を検討する。

- 未要約の会話ターン数が一定数を超えた場合
- Context文字数が一定量を超えた場合

初期値:

- 10ターン以上
- または推定Contextサイズ超過

※閾値は将来設定可能にする

### Summary generation

専用のSummary生成Contextを使用する。

例:

System:

```
You summarize conversations for future AI context.
Keep important user preferences, decisions, ongoing tasks,
and relevant technical details.
Do not include temporary details.
```

Input:

```
Existing Summary:

<current summary>

Recent Conversation:

<User>
...
<Assistant>
...
```

Output:

```
<new summary only>
```

### Provider usage

- 既存AIProviderを利用する
- 通常回答とは別リクエストとして実行する
- Summary生成中も通常回答を優先する
- Provider失敗時はSummary更新をスキップする

### Context behavior after update

更新前:

```
Summary
+
Recent Turns(5)
+
Current Message
```

更新後:

```
New Summary
+
Recent Turns(5)
+
Current Message
```

### Storage

- Summary更新後はConversationStoreへ保存する
- 既存v2形式を維持する
- SummaryなしConversationとの互換性を維持する

### Debug Console

Debug Mode ON時:

表示項目を追加する。

- Summary generation triggered
- Previous Summary
- Generated Summary
- Summary update success/failure

### Implementation guidance

- Summary生成処理を専用サービスへ分離する
- ConversationRunnerへ直接AIプロンプトを書かない
- Summary生成用PromptはCore管理にする
- 通常回答ContextとSummary生成Contextを混在させない
- Summary更新失敗でユーザー回答を失敗扱いにしない

### Verification

- 短い会話ではSummary生成されない
- 閾値到達でSummary生成される
- Summary更新後に次回Contextへ反映される
- Summary生成失敗でも回答は成功する
- 保存・再起動後もSummaryが残る
- Debug Consoleで生成過程を確認できる
- Xcode build成功
- Core tests成功
- `git diff --check`成功

### Future work

- Summary品質評価
- 複数Conversation間Memory
- ユーザー設定Memory
- 長期Memory検索
