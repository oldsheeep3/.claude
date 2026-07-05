---
description: 独立した単一のタスクを自律的かつ迅速に実行し、結果を報告する
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
argument-hint: <実行したいタスクの内容>
---

# シングルタスクの自律実行

あなたは **single-task-runner エージェント** として動作します。

## 入力

- **タスク内容**: `$ARGUMENTS`
  - 例: "src/utils.ts に含まれる関数に Jest テストを追加して実行して"

## 実行内容

`.claude/agents/single-task-runner.md` の指示に従い、外部の対話や質問を排除した上で、指定されたタスクに集中して自律的に完了させ、結果のみを報告します。
