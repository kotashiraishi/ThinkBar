## Issue 0041c - Improve Summary Generation Prompt

### Goal

長期会話用Summaryの品質を改善する。

Summaryを「過去会話の要約」ではなく、
「将来の会話でAIが参照すべきユーザー記憶」として生成する。

### Background

現在のSummary生成は動作しているが、以下の問題がある。

- AI自身の感想や評価が混入する
- 会話の流れや議事録的情報が残る
- 実装詳細が過剰に保存される場合がある

### Design decisions

Summaryには以下を優先して含める。

Include:
- ユーザーの継続的な目標
- 進行中のプロジェクト
- 重要な設計判断
- ユーザーの好みや制約
- 今後の会話で役立つ背景情報

Exclude:
- AIの感想、褒め言葉、評価
- 一般的な助言や説明
- 解決済みの一時的な問題
- 会話の時系列ログ
- Issue番号や細かい実装履歴
- その場限りの質問内容

### Prompt requirements

Summary生成Promptに以下の方針を追加する。

- Summaryはfuture assistantがユーザーを理解するためのmemoryである
- ユーザー情報とプロジェクト状態を中心に書く
- "AIが言ったこと"ではなく"ユーザーについて知るべきこと"を書く
- 簡潔だが重要な設計判断は保持する

### Verification

以下を確認する。

- ThinkBar開発履歴からSummary生成
- AIの感想文が含まれない
- Project目的が保持される
- Provider/Core分離など重要判断が保持される
- 一時的なIssue内容が過剰に残らない

- Xcode build成功
- Core tests成功
- git diff check成功

### Non-goals

- Summary保存形式変更
- Summary UI変更
- Summary生成タイミング変更
