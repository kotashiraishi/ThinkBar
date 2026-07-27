## Issue 0027 - OpenRouter Provider

### Goal

OpenRouter APIを利用できるProviderを追加し、ThinkBarからクラウドAIを利用可能にする。

### Added / Modified / Deleted files

**Added**
- `Packages/ThinkBarCore/Sources/ThinkBarCore/OpenRouterProvider.swift`

**Modified**
- `Packages/ThinkBarCore/Sources/ThinkBarCore/AIProvider.swift`
- `Packages/ThinkBarCore/Tests/ThinkBarCoreTests/`

**Deleted**
- なし

### Must

- `OpenRouterProvider`を追加する。
- 既存の`AIProvider`プロトコルへ適合する。
- ストリーミング応答に対応する。
- OpenRouter Chat Completions APIを使用する。
- モデル名は初期実装では固定（例: `openai/gpt-5.5` または利用可能な代表モデル）。
- APIキーは今回はコード内の定数でよい（後でKeychainへ移行予定）。

### Should

- OllamaProviderと実装スタイルをできるだけ揃える。
- `stream()`中心で実装し、`ask()`は必要に応じてラップする。

### Out of Scope

- Provider切替UI
- モデル切替UI
- APIキー設定画面
- Keychain保存
- Vision
- Function Calling

### Design decisions

- OllamaProviderの設計をできるだけ踏襲する。
- 既存Conversation・Mode・Streamingをそのまま利用できる構成とする。
- HTTP通信は`URLSession`のみ使用する。
- 外部ライブラリは追加しない。
- エラーメッセージは最低限でよい。

### Acceptance Criteria

- Build成功。
- Core tests成功。
- OpenRouter APIからストリーミング応答を取得できる。
- OllamaProviderの動作へ影響しない。

### Future work

- APIキーをKeychainへ保存
- Provider Picker
- Model Picker
- Vision対応
- Responses API対応（必要に応じて）

### Additional Instructions

Provider切替UIはまだ作成しません。

まずはCoreへOpenRouterProviderを追加し、ContentViewから一時的に差し替えて動作確認できる状態を目標としてください。

作業終了後は以下を出力してください。

- Issue name
- Goal
- Added / Modified / Deleted files
- Design decisions
- Future work
- git diff --stat summary
