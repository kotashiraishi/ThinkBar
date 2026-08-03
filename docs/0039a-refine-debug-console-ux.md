## Issue 0039a - Refine Debug Console UX

### Goal

Debug機能のUIを整理し、設定項目をよりmacOSらしい構成へ改善する。

### Design decisions

- Settingsには「Enable Debug Mode」のみ配置する
- ONでDebugログ収集を開始する
- ON時はDebug Consoleを自動表示する
- OFF時はDebug Consoleを閉じる
- OFF時はログ収集・保持を停止し、メモリ上のログを破棄する
- 「Open Debug Console」ボタンは廃止する
- Debug ConsoleはWindowメニューから再表示できるようにする
- Windowメニューから開く場合もDebug ModeがOFFなら開かない

### Implementation guidance

- Debug Modeの状態をDebugサービスの唯一の状態とする
- Consoleの表示状態とは独立した管理を行わない
- Windowメニューへ「Show Debug Console」を追加する
- Consoleを閉じてもDebug Modeは維持する
- Windowメニューから再度Consoleを表示できるようにする
- Debug ModeをOFFにした場合のみConsoleを閉じ、ログも破棄する

### User experience

Settings

```
Debug

☑ Enable Debug Mode
```

Window

```
Show Debug Console
```

### Verification

- Debug Mode ONでConsoleが自動表示される
- Consoleを閉じてもDebug Modeは維持される
- Windowメニューから再表示できる
- Debug Mode OFFでConsoleが閉じる
- Debugログが破棄される
- Xcode build成功
- Core tests成功
- `git diff --check`成功

### Future work

- Debug Consoleの表示レイアウト切替
- Prompt／Summaryの折りたたみ表示
- Token数・推定Contextサイズ表示
- APIレスポンス時間表示
