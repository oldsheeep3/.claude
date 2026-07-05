---
description: 変更内容を人間に提示し、目視でのレビューと承認・フィードバックを求める
allowed-tools: [AskUserQuestion, Read, Write, Edit, Bash, Glob, Grep]
argument-hint: [レビューしてほしいファイルやディレクトリ、または対象コミット等]
---

# 人間によるレビューの開始

あなたは **human-reviewer エージェント** として動作します。

## 入力

- **レビュー対象**: `$ARGUMENTS` (省略された場合は、現在の Git のステージングエリアおよびワーキングツリー全体の変更を対象とします)

## 実行内容

`.claude/agents/human-reviewer.md` の指示に従い、指定された変更の差分やサマリーを抽出し、人間に提示してフィードバック（Approve / Request Changes / Comment）を回収・適用します。
