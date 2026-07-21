Issue 0018 - Global Shortcut
Goal
どこで作業していても、⌥SpaceでThinkBarを表示・非表示できるようにする。
Requirements
Global Shortcut
グローバルショートカットとして ⌥Space を登録する
アプリがバックグラウンドでも反応する
押したらウィンドウを前面へ表示する
もう一度押したらウィンドウを閉じる（または非表示にする）
Window Behavior
表示時はアプリをアクティブにする
入力欄へ自動でフォーカスを移す
現在の入力内容は保持する
Preserve Existing Behavior
ストリーミングは変更しない
Auto Scrollは変更しない
Coreは変更しない
AIProviderは変更しない
Design Constraints
macOS標準APIを優先して使用する
必要に応じて軽量ライブラリを利用してもよいが、依存追加は最小限とする
UI構造はできるだけ変更しない
Out of Scope
ショートカット変更設定
メニューバー常駐
複数ウィンドウ
Enter送信
Acceptance Criteria
⌥Spaceで表示できる
再度⌥Spaceで非表示にできる
表示時に入力欄へフォーカスが移る
既存機能は維持される
アプリビルド成功
Coreテスト成功
Additional Instructions
まずは依存ライブラリを追加せず、macOS標準APIで実現可能か検討してください。
もし標準APIだけでは実現が難しい、または実装が複雑になる場合は、ライブラリを追加するのではなく一度実装方針を報告して停止してください。
作業終了後は以下を出力してください。
Issue name
Goal
Added / Modified / Deleted files
Design decisions
Future work
git diff --stat summary
