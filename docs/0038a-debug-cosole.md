## Issue 0038a - Debug Console

### Goal

AIへ送信しているContextや生成されたプロンプトを確認できるデバッグ画面を追加する。

### Design decisions

- Debug ModeをSettingsでON/OFF可能にする
- Debug Mode OFF時はログ画面を表示しない
- ログは永続保存しない
- アプリ終了時に破棄する
- AI送信用Context生成後の内容を表示する
- Conversation表示やAI動作には影響させない

### Debug Console内容

表示項目:

- Timestamp
- Provider
- Model
- Mode
- Generated Context
- User Message
- Attachment Context
- Conversation Summary（将来対応）
- Provider Response

### UI

- 別ウインドウで表示
- SettingsからDebug Consoleを開く
- macOS標準Window操作に合わせる

### Implementation guidance

- Debugログ用サービスを追加する
- ContentViewへ直接ログ処理を書かない
- ContextBuilder生成結果を記録できるようにする
- Debug Mode判定はUIだけでなくLogger側でも行う
- OFF時は不要な文字列生成を避ける

### Verification

- Debug Mode ONでログ表示できる
- OFFではウインドウを開けない
- アプリ再起動でログが消える
- 通常会話に影響しない
