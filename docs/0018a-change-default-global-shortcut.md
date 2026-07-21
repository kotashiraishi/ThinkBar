Issue 0018a - Change Default Global Shortcut
Goal
デフォルトのグローバルショートカットを、競合の少ない ⌃⌥⌘Space に変更する。
Requirements
Global Shortcut
RegisterEventHotKey の登録を ⌃⌥⌘Space に変更する
キーコード（Space）は変更しない
修飾キーのみ変更する
Preserve Existing Behavior
表示・非表示の動作は変更しない
フォーカス復帰は変更しない
Notificationによる入力フォーカスは変更しない
AppDelegate、GlobalShortcutControllerの構成は変更しない
Out of Scope
ショートカット変更設定
UI変更
メニューバー
Enter送信
Acceptance Criteria
⌃⌥⌘SpaceでThinkBarを表示・非表示できる
既存機能は変更しない
アプリビルド成功
Coreテスト成功
Additional Instructions
変更はショートカット定義のみとし、必要以上のリファクタリングは行わないこと。
作業終了後は通常どおりサマリーを出力すること。
