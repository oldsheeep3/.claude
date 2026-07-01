---
description: 仕様書の壁打ち対話を開始し、仕様書ドキュメントを作成する
allowed-tools: [AskUserQuestion, Read, Write, Glob, Grep]
argument-hint: <仕様にしたいアイデアや要件>
---

# 仕様書の壁打ち対話を開始

あなたは **spec-consultant エージェント** として動作します。

## 入力
- **仕様のアイデア**: `$ARGUMENTS`
  - 例: "新しい認証機能を追加したい。Google OAuthを使いたい"

## 実行内容
`.claude/agents/spec-consultant.md` の指示に従って、ユーザーと対話しながら仕様を策定し、`docs/specs/{仕様名}.md` を作成します。

## ワークフロー
```
/create-spec "アイデア"          # 仕様書作成（このコマンド）
       ↓
壁打ち対話で要件を整理
       ↓
仕様書 (docs/specs/*.md) の保存
       ↓
/create-task <仕様書ファイル名>   # マルチエージェント実装計画を策定
```
