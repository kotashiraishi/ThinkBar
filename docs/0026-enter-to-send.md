## Issue 0026 - Enter to Send (IME Safe)

### Goal

日本語IMEの変換操作を妨げることなく、Enterキーで送信できるようにする。

### Added / Modified / Deleted files

**Modified**
- `ThinkBar/ContentView.swift`

**Added**
- なし

**Deleted**
- なし

### Must

- 日本語IMEで変換中のEnterは従来どおり変換確定として動作する。
- 変換が終了した状態でEnterを押すと送信する。
- ⌘+Enterでも送信できる。
- Sendボタンは残す。
- ストリーミング中は送信しない。

### Should

- Shift+Enterで改行できる実装が可能なら採用してよい。
- 実装方法はSwiftUI標準を優先し、必要ならmacOS APIを利用してよい。

### Out of Scope

- キー設定の変更
- ショートカットのカスタマイズ
- 他プラットフォーム対応

### Design decisions

- IMEとの互換性を最優先とする。
- 以前採用した`onKeyPress`実装には戻さない。
- 日本語入力中のEnter誤送信が起こる実装は採用しない。
- 必要であれば専用のNSTextViewラッパーを作成してもよい。

### Acceptance Criteria

- 日本語入力で違和感なく変換できる。
- Enterで送信できる。
- ⌘+Enterでも送信できる。
- Shift+Enterが実装された場合は改行できる。
- Xcode build成功。
- Core tests成功。

### Additional Instructions

最小実装を優先してください。

IMEとの互換性が十分に確保できない場合は、無理に実装せず、実現方法と制約を整理したうえで停止してください。

作業終了後は以下を出力してください。

- Issue name
- Goal
- Added / Modified / Deleted files
- Design decisions
- Future work
- git diff --stat summary
