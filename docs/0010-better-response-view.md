Issue 0010 - Better Response View
Goal
長いAI回答でも快適に読み返せるよう、回答表示領域を改善する。
Requirements
Scrollable Response
回答表示を ScrollView にする
長文でも最後までスクロールできる
ウィンドウ全体ではなく回答領域だけがスクロールする
Flexible Layout
入力欄は現在の約2行表示のまま維持
回答欄は残りの領域を占める
ウィンドウを大きくすると回答欄も自然に広がる
Preserve Existing Behavior
送信処理は変更しない
AIProviderは変更しない
ThinkBarCoreは変更しない
日本語IMEの動作を壊さない
Out of Scope
履歴
最後の質問表示
Thinking表示
Streaming
UIデザイン変更
Acceptance Criteria
長い回答をスクロールして読める
入力欄は常に見えている
既存の動作は変わらない
ビルド成功
Coreテスト成功
Additional Instructions
既存UIをできるだけ維持してください。
必要以上のリファクタリングは行わず、レイアウト改善だけを実装してください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
