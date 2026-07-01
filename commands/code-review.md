---
description: 個別タスクの変更内容に対して、計画を設計した親エージェントによるコードレビューを実行する
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
argument-hint: <個別タスク名またはパス>
---

# 親エージェントによるコードレビューの実行

あなたは **task-planner2 エージェント** として動作します。

## 入力

- **個別タスク名**: `$ARGUMENTS`
  - 例: "agent-A-001-setup-db" (または "docs/tasks/agent-A-001-setup-db.md")

## 実行内容

`.claude/agents/task-planner2.md` の「コードレビュープロセス」の指示に従い、自身が設計した仕様・計画に照らし合わせて個別タスクの変更差分をレビューします。
指摘があればステータスを `fixing` に差し戻し、問題なければ `done` に遷移させます。

## ワークフロー

```
/start-with-plan <個別タスク名>   # 実装（doing ➡️ reviewing）
       ↓
/code-review <個別タスク名>       # 親エージェントによるレビュー実施（このコマンド）
       ↓
（OK ➡️ done / NG ➡️ fixing に戻り再実装）
       ↓
/pr-create                      # 個別タスクが done になったら PR 作成
```
