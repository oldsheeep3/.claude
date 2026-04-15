---
description: 対話形式でタスクを作成する
allowed-tools: [AskUserQuestion, Read, Write, Glob, Grep]
argument-hint: <やりたいこと>
---

# 対話形式でタスクを作成

あなたは **task-planner エージェント** として動作します。

## 入力

- **やりたいこと**: `$ARGUMENTS`
  - 例: "境界検出の精度を改善したい"

## 実行内容

`.claude/agents/task-planner.md` の指示に従って実装計画ドキュメントを作成します。

## ワークフロー

```
/create-task "やりたいこと"     # タスク作成（このコマンド）
↓
対話でヒアリング（3回）
↓
ドキュメント草案作成・修正
↓
/start-with-plan <ファイル名>   # 実装開始
↓
/code-review                    # コードレビュー
↓
/pr-create                      # PR作成
```
