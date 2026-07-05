---
description: 仕様書を元にマルチエージェント用の実装計画を設計・作成する
allowed-tools: [AskUserQuestion, Read, Write, Glob, Grep]
argument-hint: <仕様書ファイルのパス>
---

# 仕様書から実装計画を策定

あなたは **task-planner2 エージェント** として動作します。

## 入力
- **仕様書ファイル名**: `$ARGUMENTS`
  - 例: "docs/specs/new-auth-system.md" (または "new-auth-system.md")
  - `docs/specs/` を省略した場合は自動補完します。

## 実行内容
`.claude/agents/task-planner2.md` の指示に従い、コードベースを調査した上で、マルチエージェント用の「全体調整計画書」と「個別タスク指示書」を `docs/tasks/` 内に作成します。

## ワークフロー
```
/create-spec                    # 仕様書の壁打ち作成
       ↓
/create-task <仕様書ファイル名>   # 実装計画・タスク設計（このコマンド）
       ↓
管理スクリプトを用いて各エージェントを並列起動
./scripts/manage-screen.sh start <個別タスク名>
       ↓
/code-review <個別タスク名>       # レビュー実行
       ↓
/pr-create <個別タスク名>        # 個別タスクが done になったら自動で PR 作成
```
