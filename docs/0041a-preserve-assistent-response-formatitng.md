## Issue 0041a - Preserve Assistant Response Formatting

Goal

ストリーミング終了後もAI回答の改行・空白を保持する。

Design decisions

- AIレスポンス本文の末尾改行を保持する
- 保存前に不要なtrim処理を行わない
- ストリーミング表示と保存内容を一致させる
- Markdown判定処理で本文を変更しない

Verification

- 複数段落の回答で改行保持
- コードブロック表示確認
- 再起動後も表示一致
