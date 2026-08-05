## Issue 0046b - Conversation Switch Performance Instrumentation

### Goal

Conversation切替のどの処理に時間がかかっているかを計測し、ボトルネックを特定する。

保存形式や表示ロジックはまだ変更せず、実測結果をもとに次の改善方針を判断できる状態にする。

### Background

0046aで初期描画を直近30 turnへ制限し、過去履歴を段階表示するようにしたが、Conversation切替の体感速度は大きく改善しなかった。

描画より前の以下の処理がボトルネックになっている可能性がある。

- 現在Conversationの保存
- Snapshot全体のJSONエンコード／ファイル書き込み
- Active Conversation切替
- 選択Conversationの取得
- 表示モデル生成
- SwiftUI初回描画

### Changes

Conversation切替処理へ一時的なパフォーマンス計測を追加する。

最低限、以下の区間を個別に計測する。

1. Save current conversation
2. Encode snapshot
3. Write snapshot file
4. Activate selected conversation
5. Retrieve selected conversation
6. Build display items
7. Prepare incremental rendering state
8. Request UI update
9. Total switch duration

可能であれば、初回表示が実際に完了したタイミングも計測する。

### Log example

Debug Consoleまたは開発ログへ、以下のような形式で出力する。

Conversation Switch Performance

- Source Conversation:
- Destination Conversation:
- Total conversations:
- Total turns in snapshot:
- Source turns:
- Destination turns:

Timings:
- Save current conversation: 000 ms
- Encode snapshot: 000 ms
- Write snapshot file: 000 ms
- Activate conversation: 000 ms
- Retrieve conversation: 000 ms
- Build display items: 000 ms
- Prepare visible turns: 000 ms
- UI state update requested: 000 ms
- First render completed: 000 ms
- Total: 000 ms

### Measurement requirements

- `ContinuousClock`または同等の単調増加時計を利用する
- `Date()`差分だけに依存しない
- 計測処理自体が重くならないようにする
- Debug Mode OFF時はログ生成を行わない、または最小限にする
- 本文やSummaryの内容そのものはログへ複製しない
- Conversation ID、turn数、文字数などのメタデータのみでよい

### Test scenarios

以下の条件で比較できるようにする。

Scenario A:
- 短いConversationから短いConversationへ切替

Scenario B:
- 短いConversationから長いConversationへ切替

Scenario C:
- 長いConversationから短いConversationへ切替

Scenario D:
- 長いConversationから長いConversationへ切替

Scenario E:
- 同じConversationを往復してキャッシュ有無を比較

長いConversationは、可能なら数十turn以上かつ長文回答を含むものを利用する。

### Design decisions

- 今回は計測のみとし、保存形式を変更しない
- ConversationStoreSnapshotの構造を変更しない
- 0046aの段階描画を維持する
- 計測結果が出る前に推測で最適化しない
- 計測コードは後で削除またはDebug専用として維持できるよう分離する

### Interpretation guide

結果から次の方針を判断する。

Save / Encode / Writeが大きい:
- Snapshot全体保存が原因
- Conversationごとの個別ファイル化を検討

Retrieve / Activateが大きい:
- Snapshotの値型更新や探索方法を確認
- IDベースの索引や状態管理を見直す

Build display items / First renderが大きい:
- UI変換、Markdown、レイアウト処理を再調査
- 表示キャッシュや仮想化を検討

すべて小さいのにTotalだけ大きい:
- MainActor待機
- 非同期タスクの順序
- SwiftUI更新タイミング
- 不要な複数回再描画

を確認する。

### Verification

以下を確認する。

- Conversation切替ごとに区間別の時間が表示される
- Total時間と各区間の合計に大きな矛盾がない
- 短いConversationと長いConversationで比較できる
- Debug Mode OFF時に通常利用へ目立つ負荷がない
- Conversation内容や保存データが変わらない
- 既存の切替・保存・Summary・Context・Streaming挙動が維持される

- Xcode build成功
- Core tests成功
- `git diff --check`成功

### Non-goals

- Conversationファイル分割
- Snapshot保存形式変更
- ディスク遅延ロード
- 表示件数の追加調整
- キャッシュ導入
- パフォーマンス改善そのもの

### Future work

計測結果に応じて以下のいずれかを進める。

- Conversation Index + 個別Conversationファイル
- Active Conversationのみメモリロード
- Snapshot差分保存
- 表示モデルキャッシュ
- Markdownレンダリングキャッシュ
- Conversation切替処理のMainActor範囲縮小

### Additional Cursor Notes

- 計測ポイントはConversation切替処理の一箇所へ集約する。
- UI、Store、ファイルI/Oで同じ処理を重複計測しない。
- JSONエンコードとファイル書き込みは可能なら別々に計測する。
- `save()`が内部でencodeとwriteを一括実行している場合、Debug計測用のフックや計測結果型を追加してもよいが、本番APIを不必要に複雑化しない。
- Debug Consoleが既にあるため、計測結果はそこへ出すのが望ましい。
- 次Issueで保存形式を変更する可能性があるため、今回の計測結果を比較基準として残せる形にする。
