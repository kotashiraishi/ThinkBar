# Issue 0020 - Conversation Context

## Goal

会話履歴をOllamaへコンテキストとして渡し、継続した会話を可能にする。

## Added / Modified / Deleted files

**Modified**

- `Packages/ThinkBarCore/Sources/ThinkBarCore/OllamaProvider.swift`
- `ThinkBar/ContentView.swift`

**Added**

なし

**Deleted**

なし

---

## Design decisions

### Context Construction

現在のConversation履歴から

```
User: ...
Assistant: ...
User: ...
Assistant: ...
```

という形式のプロンプトを生成し、

最後に

```
Assistant:
```

を付けてOllamaへ送信する。

---

### Context Size

最初は

**直近5ターン**

のみ送信する。

（設定化しない）

---

### Streaming

現在のストリーミング実装をそのまま利用する。

---

### Preserve Existing Behavior

- AIProvider変更なし
- Streaming維持
- Auto Scroll維持
- Conversation UI維持
- Global Shortcut維持

---

## Out of Scope

- systemプロンプト
- Prompt Template
- 履歴の永続保存
- Token数の自動計算

---

## Acceptance Criteria

- 前の会話を踏まえた回答になる
- 直近5ターンのみ送信される
- Streamingは維持
- ビルド成功
- Coreテスト成功

---

## Additional Instructions

- AIProviderのAPIは変更しないこと。
- Context生成はContentView側ではなく、Ollamaへ送る直前の層で行うこと。
- 将来OpenAI Providerを追加しやすい構造を意識すること。
- 必要以上のリファクタリングは行わないこと。

作業終了後は以下を出力してください。

- Issue name
- Goal
- Added / Modified / Deleted files
- Design decisions
- Future work
- git diff --stat summary

