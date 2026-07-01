---
description: 個別タスクの完了を検証し、タスクごとに親Epicブランチへ向けた Pull Request を作成・更新する
allowed-tools: [Bash, Read, Grep, Glob]
argument-hint: <個別タスク名またはパス>
---

# 個別タスクごとの PR 作成・更新

指定されたエージェントの個別タスクが完了していることを確認し、そのタスク専用の Pull Request を親 Epic ブランチに向けて作成、または既存の PR に変更を反映（プッシュ）します。

## 引数

- `$ARGUMENTS`: 個別タスク名（例: `agent-A-002-update-db` またはパス `docs/tasks/agent-A-002-update-db.md`）
  - `docs/tasks/` や `.md` を省略した場合は自動補完します。

## 手順

1. **タスク完了状況の確認**:
   - 指定された個別タスク指示書ファイルを読み込む。
   - YAML フロントマターの `status` が `done` になっているか確認する。
   - もし `done` になっていない場合（`planning`/`doing`/`reviewing`/`fixing` の状態）は、レビューが未完了であるため、PR 作成を中断する。

2. **親 Epic ブランチおよび subtree 情報の取得**:
   - `docs/tasks/orchestration-plan.md` から「Epicブランチ名」を取得する。
   - 指示書から「Git Subtree プレフィックス」や「ブランチ情報」を取得する。

3. **対象 subtree ブランチのプッシュ**:
   - 該当する subtree ブランチをリモートリポジトリにプッシュする（例: `git push origin <subtree-branch>`）。

4. **既存 PR の確認**:
   - `gh pr list --head <subtree-branch>` 等を実行し、すでに対象ブランチからの PR が存在するか確認する。
   - **既存の PR が存在する場合**:
     - すでに PR があるため、追加の `gh pr create` は実行せず、プッシュのみで PR が自動更新されることを報告して終了する。

5. **PR テンプレートのロードと本文作成**:
   - **リポジトリ内の PR テンプレートの探索**:
     リポジトリのルートまたはサブディレクトリ（例: `.github/PULL_REQUEST_TEMPLATE.md`、`.github/pull_request_template.md`、または `docs/pull_request_template.md`）に PR テンプレートファイルが存在するか確認する。
   - **テンプレートが存在する場合**:
     - 該当するテンプレートの内容を読み込む。
     - テンプレートに定義されている各項目（概要、変更内容、テスト方法など）について、今回の個別タスク指示書に書かれた「実装ステップ」や「達成目標」の内容をもとに適切にテキストを埋め、PR 本文とする。
   - **テンプレートが存在しない場合**:
     - 下記の「デフォルト PR 本文フォーマット」を使用して本文を作成する。

6. **PR 作成の実行**:
   - マージ先のベースブランチとして Epic ブランチ（例: `feature/epic-xxx`）を指定して `gh pr create` を実行する。
   - PR のタイトルは `[個別タスク名] {タスク名}` とする。

---

## デフォルト PR 本文フォーマット (テンプレート未検出時)

```
gh pr create --head <subtree-branch> --base feature/epic-xxx --title "[<個別タスク名>] <タスク名>" --body "$(cat <<'EOF'
## 概要
<個別タスクの目的と実装内容の要約>

## 担当エージェント情報
- エージェントID: agent-[A-Z]
- サブツリープレフィックス: <subtree_prefix>

## 実装内容
- [x] <完了した実装ステップのリスト>

## 影響範囲・懸念点
<影響範囲や懸念点。なければ「なし」>
EOF
)"
```
