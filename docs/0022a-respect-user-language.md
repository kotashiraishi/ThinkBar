Issue 0022a - Respect User Language
Goal
ユーザーの最新メッセージと同じ言語で回答するようAIへ指示し、日本語での利用時に英語で返答されることを防ぐ。
Added / Modified / Deleted files
Modified
Packages/ThinkBarCore/Sources/ThinkBarCore/OllamaProvider.swift
Packages/ThinkBarCore/Tests/ThinkBarCoreTests/OllamaProviderTests.swift（必要に応じて）
Added
なし
Deleted
なし
Design decisions
全Conversation Mode共通で、システム指示の末尾に以下を追加する。
Answer in the same language as the user's latest message.
Do not switch languages unless the user explicitly requests it.
General / Horn / Swift / PHP / Run のすべてに適用する。
Modeごとの役割や専門性の指示は変更しない。
UI、Conversation、Streaming、Auto Scrollには変更を加えない。
AIProvider APIは変更しない。
Verification
日本語で質問すると日本語で回答する。
英語で質問すると英語で回答する。
「英語で答えて」と明示した場合は英語で回答する。
既存のCoreテストがすべて成功する。
Future work
回答言語を設定で固定するオプション
ユーザー言語の自動判定ロジック
モードごとの多言語対応テンプレート
git diff --stat summary
作業完了後に出力してください。
<git diff --stat>
