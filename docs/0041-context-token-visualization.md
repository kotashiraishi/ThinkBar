## Issue 0041 - Context Token Visualization

### Goal

AIへ送信するContext量を可視化し、Summaryによる圧縮効果を確認できるようにする。

### Design decisions

- Debug ConsoleにContext統計情報を表示する
- 保存対象にはしない
- 実際のProvider送信内容を基準に計測する
- Token数は推定値でよい
- Provider固有のToken APIには依存しない

### Debug Console additions

表示項目:

```
Context Statistics

Summary
- Characters:
- Estimated Tokens:

Recent History
- Turns:
- Characters:
- Estimated Tokens:

Current Message
- Characters:
- Estimated Tokens:

Total Context
- Characters:
- Estimated Tokens:
```

### Estimation

初期実装:

- 文字数ベースの簡易推定でよい
- 日本語・英語混在を考慮した概算値とする
- 正確なToken数取得は将来対応

例:

```
Estimated Tokens: ~1200
```

のように表示する。

### Context comparison

Debug Consoleに以下を表示する。

Summaryあり:

```
Context with Summary

Summary:
420 chars

History:
1800 chars

Total:
2300 chars
```

Summaryなし:

```
Context without Summary

History:
6200 chars

Total:
6200 chars
```

### Test scenario support

Debug Mode ON時に評価しやすいよう、テスト用Conversationを追加可能にする。

例:

```
Test Data

Load Long Conversation Sample
```

目的:

- Summary生成前後比較
- Context圧縮確認
- Debug Console表示確認

### Sample conversation

内容:

- ThinkBar開発相談
- Swift設計判断
- Provider設計
- ユーザーの開発方針

など、実際の利用に近い長めの会話を用意する。

### Implementation guidance

- ContextBuilderから統計情報を取得できるようにする
- Debug Consoleへ渡す情報とAI送信用Contextを一致させる
- ContentViewへロジックを追加しない
- Token計算処理は専用Serviceへ分離する

### Verification

- SummaryなしContextサイズを確認できる
- SummaryありContextサイズを確認できる
- Summary追加後にHistoryサイズが減少することを確認できる
- Test Conversationで再現可能
- Debug Consoleで確認できる
- Xcode build成功
- Core tests成功
- git diff --check成功

### Future work

- Provider APIによる正確なToken取得
- Context自動圧縮
- Token上限によるモデル切替
