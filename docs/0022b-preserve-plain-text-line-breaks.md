## Issue 0022b - Preserve Plain Text Line Breaks

### Goal

通常のAI回答では改行をそのまま保持し、Markdownとして表示する必要がある回答のみMarkdownレンダリングする。

### Added / Modified / Deleted files

**Modified**
- `ThinkBar/ContentView.swift`

**Added**
- なし

**Deleted**
- なし

### Design decisions

- 回答完了後に表示方式を決定する。
- Markdownとして表示する価値がある回答のみ`AttributedString(markdown:)`を使用する。
- それ以外はプレーンテキスト表示とし、LLMが出力した改行・空行をそのまま保持する。
- Markdown判定ロジックは小さなヘルパーメソッドへ切り出す。
- 判定条件は実装側で適切に決めてよい。
- Streaming、Auto Scroll、Text Selection、Conversation、Modes、Attachmentsは変更しない。

### Acceptance Criteria

- 通常の文章は改行が保持される。
- Markdown回答は従来どおり読みやすく表示される。
- コピーした内容が画面表示と一致する。
- Xcode build成功。
- Core tests成功。

### Additional Instructions

- 判定は軽量に実装すること。
- 必要以上のリファクタリングは行わない。

作業終了後は以下を出力してください。

- Issue name
- Goal
- Added / Modified / Deleted files
- Design decisions
- Future work
- git diff --stat summary
