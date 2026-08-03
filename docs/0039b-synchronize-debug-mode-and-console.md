## Issue 0039b - Synchronize Debug Mode and Debug Console

### Goal

Debug ModeとDebug Consoleの状態を同期し、UIをより直感的にする。

### Design decisions

- Enable Debug ModeをONにするとDebug Consoleを自動表示する
- Debug Consoleを閉じた場合はDebug Modeを自動でOFFにする
- Debug ModeがOFFになるとログ収集を停止する
- Debugログをメモリから破棄する
- Windowメニューの「Show Debug Console」はDebug ModeをONにしてConsoleを表示する
- Debug ModeとConsoleの表示状態が常に一致する

### Implementation guidance

- ConsoleのCloseイベントを監視する
- Close時にDebug ModeをOFFへ更新する
- Debug Mode変更時は既存のログ停止・破棄処理を利用する
- 二重に状態変更しないようイベントループに注意する

### Verification

- Debug Mode ONでConsoleが表示される
- Consoleを閉じるとDebug ModeがOFFになる
- Windowメニューから開くとDebug ModeがONになる
- OFF時はログが破棄される
- Core tests成功
- Xcode build成功
- `git diff --check`成功

### Future work

- Debug Consoleのレイアウト改善
- Contextコピー
- Token数表示
- API時間表示
