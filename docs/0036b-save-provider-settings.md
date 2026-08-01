## Issue 0036b - Save Provider Settings

### Goal

Settings画面に保存ボタンを追加し、設定変更を明示的に保存できるようにする。

### Modified files

- `ThinkBar/SettingsView.swift`
- 必要に応じてProvider設定管理部分

### Design decisions

- 設定変更は一時状態として保持する
- Saveボタン押下時に永続設定へ反映する
- APIキー保存もSave時に実行する
- 保存前の変更でProvider動作は変更しない
- 保存成功後にProvider再生成を行う
- 会話履歴には影響させない

### Implementation guidance

- SettingsView内の編集用Stateと保存済み設定を分離する
- Save処理は既存のProviderSettingsServiceを利用する
- Keychain保存処理をUIへ直接書かない
- 保存成功・失敗をユーザーへ表示可能にする
- Cancel相当の動作（未保存変更破棄）を考慮する

### UI behavior

- Provider変更
- Model変更
- APIキー変更

は一時状態として保持する。

Save押下:
- ProviderConfiguration更新
- Keychain保存
- Provider再生成

### Verification

- 設定変更後Saveで反映される
- Save前にチャット動作が変化しない
- APIキーがKeychainへ保存される
- アプリ再起動後に設定復元される
- 保存失敗時に設定を壊さない

### Future work

- Cancelボタン
- 設定変更検知
- Apply/Discard UI
