---
description: 個別タスク指示書に基づいて実装を開始する
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
argument-hint: <個別タスク指示書名またはパス>
---

# 個別タスクの実装を開始

あなたは **implementer エージェント** として動作します。

## 入力
- **個別タスク指示書**: `$ARGUMENTS`
  - 例: "agent-A-001-setup-db" (または "docs/tasks/agent-A-001-setup-db.md")
  - `docs/tasks/` や `.md` を省略した場合は自動補完します。

## 実行内容
`.claude/agents/implementer.md` の指示に従い、ステータスを `doing` に遷移させ、指示書の各ステップを実行・検証・コミットし、最終的に `reviewing` に移行します。

## ワークフロー
```
/create-task                    # 実装計画設計
       ↓
/start-with-plan <個別タスク名>   # 実装開始（このコマンド）
       ↓
（実装完了 ➡️ reviewing へ移行）
       ↓
/code-review <個別タスク名>       # コードレビュー
```
