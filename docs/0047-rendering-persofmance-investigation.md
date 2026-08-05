## Issue 0047 - Rendering Performance Investigation

### Goal

Conversation切替時の描画ボトルネックを特定する。

0046bの計測により、Conversation切替の約3.4秒のほぼ全てが
"First render completed" に含まれることが分かった。

保存・JSON・Conversation取得ではなく、
描画処理のどこが時間を消費しているかを切り分ける。

### Background

0046bの実測例

- Save current conversation: 約0.1 ms
- Encode snapshot: 約1.5 ms
- Write snapshot file: 約2 ms
- Activate conversation: 約0 ms
- Build display items: 約0 ms
- First render completed: 約3400 ms

保存形式は十分高速であり、
現在のボトルネックはレンダリング側にある。

### Investigation targets

以下を個別に切り分ける。

- Markdownパース
- AssistantResponseFormatter
- AttributedString生成
- SwiftUI View生成
- レイアウト計算
- スクロール位置復元

### Changes

Debug Mode限定でレンダリング時間を詳細計測する。

最低限以下を個別計測する。

- Markdown parse
- AssistantResponseFormatter
- AttributedString creation
- View construction
- Layout / first appearance

可能であれば

- turnごとの時間
- 合計時間
- 最大時間のturn

も出力する。

### Investigation experiment

以下の比較ができるようにする。

Experiment A

通常レンダリング

Experiment B

Assistantメッセージを一時的に

Text(rawString)

だけで描画する。

Markdown処理を完全にバイパスして比較する。

この切替はDebug限定でよい。

### Expected interpretation

Markdown無効で大幅改善

↓

Markdown処理がボトルネック

Markdown無効でも改善しない

↓

SwiftUIレイアウトまたはView構築がボトルネック

Formatterだけ遅い

↓

Formatterキャッシュを検討

AttributedStringだけ遅い

↓

レンダリング済み結果キャッシュを検討

### Design decisions

- 保存形式は変更しない
- ConversationStoreは変更しない
- Summary処理は変更しない
- UI表示結果は変えない
- Debug専用計測とする

### Verification

以下を確認する。

- Markdown有効時のレンダリング時間
- Markdown無効時のレンダリング時間
- 最大時間を消費する処理が特定できる
- Debug OFFでは影響しない

- Xcode build成功
- Core tests成功
- git diff --check成功

### Future work

調査結果に応じて以下を検討する。

- Markdown結果キャッシュ
- AttributedStringキャッシュ
- AssistantResponseFormatterキャッシュ
- Viewモデルキャッシュ
- レンダリング済みConversationキャッシュ
- SwiftUIレイアウト最適化

### Additional Cursor Notes

- 今回は原因調査のみを目的とする。
- 最適化コードは必要最小限に留める。
- 計測結果からボトルネックが明確になってから最適化Issueを作成する。
- Debug Consoleに集約して表示し、0046bと比較できる形式にする。
