## Issue 0042 - Composer UX Refresh

### Goal

質問入力エリア（Composer）の配置と操作性を改善する。

Conversation表示を主役にし、入力欄を画面下部へ配置する。

### Background

現在の入力欄はConversationより上に配置されている。

長時間AIと会話する用途では、回答を読みながら次の入力を行う流れが自然になるため、一般的なチャットUIと同様にComposerを下部配置へ変更する。

### Changes

- Input areaをConversation上部から下部へ移動
- Composer領域を独立したUIコンポーネントとして整理
- Auto Growing Input Fieldを実装
- 初期状態は現在と同程度の高さを維持
- 2行目入力時に高さを拡張
- 最大10行程度まで拡張
- 最大高さ到達後は内部スクロール
- 送信完了後は入力欄を初期高さへ戻す

### Layout

変更前:

Input
Conversation

変更後:

Conversation
Input / Composer

### Design decisions

- Conversation表示領域を優先する
- 入力欄はComposerとして独立管理する
- 既存のIME対応を維持する
- Enter送信動作を維持する
- Shift+Enter改行を維持する
- 添付機能を維持する
- Provider、Model、Modeなど既存設定UIは必要に応じてComposer周辺へ配置可能
- ConversationモデルやProvider処理は変更しない

### Implementation guidance

- 既存NSTextViewベースの入力コンポーネントを活用する
- SwiftUI TextEditorへ置換しない
- 高さ計算と送信処理を分離する
- 入力文字列変更時に高さ更新する
- 入力文字列クリア時に高さをリセットする
- スクロール領域とComposer領域の責務を分離する

### Verification

以下を確認する。

- 起動時の入力欄高さが自然
- 入力欄が画面下部に表示される
- 2行入力で高さが拡張される
- 長文入力で最大高さ制限が働く
- 最大高さ以上で内部スクロールできる
- 送信後に1行相当へ戻る
- 日本語IME変換が正常
- Enter送信が正常
- Shift+Enter改行が正常
- 画像ペーストが正常
- ストリーミング表示が壊れない
- 自動スクロール動作が壊れない

### Non-goals

- Conversation履歴管理変更
- Provider処理変更
- Summary/Context処理変更
- Markdown表示変更

### Future work

- 添付プレビュー
- 音声入力
- Composer Actions
- Markdown入力補助
- 回答コピー機能

### Additional Cursor Notes

- UI変更のみを目的とし、Core層やAI Provider層へ影響を広げない。
- 既存のNSTextView利用理由（IME対応、画像ペースト対応）を維持する。
- 高さ変更処理はIME変換中にも発生するため、NSTextView delegate処理で変換状態を壊さない。
- 入力欄移動によってConversation表示、ストリーミング更新、自動スクロール挙動を変更しない。
- 実装は小さな単位で進め、まず配置変更、次に高さ自動調整を確認する。
