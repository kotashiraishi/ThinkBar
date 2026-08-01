## Issue 0036c - Auto Dismiss Settings Feedback

### Goal

Settings保存結果メッセージを一時表示に変更する。

### Modified files

- `SettingsView.swift`

### Design decisions

- Save成功時の`Saved`表示は一定時間後に自動消去する
- 保存失敗メッセージも同様に一時表示する
- 設定状態そのものは変更しない
- メッセージ表示中に再度Saveした場合はタイマーをリセットする

### Implementation guidance

- SwiftUIの`Task.sleep`等で自動消去する
- 既存の保存処理やProvider再生成処理は変更しない
- View表示状態と設定データを混在させない

### Verification

- Save成功後にメッセージが表示される
- 数秒後に自動で消える
- 連続Saveでも表示が不自然に残らない
- 保存失敗時も確認後に消える
- Xcode build成功
- Core tests成功

### Future work

- macOS標準通知風UI
- Toastコンポーネント共通化
