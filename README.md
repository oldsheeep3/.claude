# .claude

どのプロジェクトでも流用できる、汎用の [Claude Code](https://docs.claude.com/en/docs/claude-code) 設定テンプレート集。

言語・フレームワーク・デプロイ先に依存しない形で、マルチエージェント並列開発ワークフローに対応したエージェント定義、スラッシュコマンド、レビュー観点、および画面・プロセス管理スクリプトを揃えています。任意のリポジトリのルートに `.claude/` ディレクトリとして配置するだけで機能します。

## セットアップ

任意のプロジェクトのルートで、このリポジトリを `.claude/` として取り込みます。

```bash
git clone git@github.com:oldsheeep3/.claude.git .claude
```

```bash
git clone https://github.com/oldsheeep3/.claude.git .claude
```

以降、Claude Code を起動するとこのディレクトリの設定が自動で読み込まれます。

## ディレクトリ構成

```
.claude/
├── README.md              このファイル
├── settings.json          共有してよい権限設定（git / gh 中心の最小許可）
├── settings.local.json    ユーザーローカル設定（共有しない / .gitignore 推奨）
├── review-patterns.md     言語非依存のレビュー観点・マルチエージェント開発用チェックリスト
├── agents/
│   ├── spec-consultant.md 仕様書の壁打ち・策定エージェント
│   └── task-planner2.md   仕様書 → 並列/直列タスク設計・指示書作成、およびコードレビュー
├── commands/
│   ├── create-spec.md     /create-spec  仕様書の壁打ち作成
│   ├── create-task.md     /create-task  仕様書に基づく実装計画・指示書作成
│   ├── start-all-tasks.md /start-all-tasks 未完了タスクを一括並列起動
│   ├── start-with-plan.md /start-with-plan <個別タスク名>  実装エージェント起動
│   ├── code-review.md     /code-review <個別タスク名>  親エージェントによるコードレビュー起動
│   ├── pr-create.md       /pr-create <個別タスク名>    個別タスク完了後の PR 作成・更新
│   └── clean-branch.md    /clean-branch マージ済みブランチの整理
├── scripts/
│   ├── manage-screen.sh   GNU Screen によるエージェントセッション・ステータス管理シェル
│   ├── run-lifecycle.sh   各タスクの自律ライフサイクル（実装・レビュー・PR作成）ランナー
│   └── notify.sh          Windows システム通知（アラート音と前面メッセージボックス）
└── skills/
    └── SKILL.md           プロジェクト固有トラブルシュート置き場
```

## 🚀 利用手順 (使い方)

マルチエージェントによる自律・並列開発を進めるためのステップバイステップの手順です。

### 1. 仕様の壁打ち・策定
まず、新しく追加したい機能や修正したい仕様のアイデアを提示して、仕様書を策定します。
```bash
/create-spec "新しい認証機能の追加。Google OAuthを使用し、ユーザー情報をDBに保存する。"
```
- **使用エージェント/モデル**: `spec-consultant` (Opus推奨)
- **動作**: 質問と壁打ちを繰り返して要件を整理し、`docs/specs/{spec-name}.md` を出力します。

### 2. 実装計画・タスク設計の策定
仕様書から並列開発可能なタスクの切り出しと依存関係の整理を行います。
```bash
/create-task docs/specs/{spec-name}.md
```
- **使用エージェント/モデル**: `task-planner2` (Opus推奨)
- **成果物**:
  - `docs/tasks/orchestration-plan.md` (全体の進行計画と親ブランチ名)
  - `docs/tasks/agent-A-001-{task-name}.md` (各エージェント別の個別指示書)

### 3. Epicブランチの作成とSubtreeの初期化
全体調整計画書 (`orchestration-plan.md`) の指示に従い、全体の親となるブランチの作成と各エージェント用の subtree 初期化を手動で1回実行します。
```bash
# 計画書に記載されたEpicブランチを作成・チェックアウト
git checkout -b feature/epic-{仕様名}

# 計画書に記載された各エージェントのsubtreeブランチを初期化
git subtree add --prefix=src/sub/agent-A agent-A-branch
```

### 4. マルチエージェント一括起動
準備が整ったら、以下のコマンドで全エージェントをバックグラウンド並列起動します。
```bash
/start-all-tasks
```
- **動作**: 計画書のフェーズ1にある未完了の全タスクが Screen セッション（セッション名: `planning-agent-*-*`）で一括起動します。
- 各セッション内では `run-lifecycle.sh` が自動で回り、タスクごとに最適なモデル（Sonnet や Antigravity 等）で実装（`/start-with-plan`）が始まります。

### 5. 開発中の進捗確認とユーザーへの通知
- **進捗の確認**: ターミナルで `screen -ls` を実行すると、エージェントの現在ステータス（`doing`/`reviewing`/`fixing`等）が付いたセッション一覧を確認できます。`screen -r <PID>` で個別のセッションに入ってログを確認することも可能です。
- **ユーザーへの確認アラート**:
  エージェントが実装中やレビュー中に質問を行ったり、エラーにより保留となった場合、**Windowsのシステム通知（ビープ音と前面ダイアログ）**でデスクトップに通知が飛びます。通知されたセッションにアタッチして質問に回答してください。

### 6. レビュー・修正・PR作成の自動処理
- 実装エージェントがテストにパスすると、自動的にステータスを `reviewing` に更新し、親エージェント（Opus / `task-planner2`）による `/code-review` が走ります。
  - ❌ **指摘あり**: `status` が `fixing` に差し戻され、エージェントが修正を行います。
  - ⭕ **合格**: `status` が `done` に変更され、自動で `/pr-create` が実行されます。
- `git subtree` ブランチから親 Epic ブランチに向けて**タスクごとの PR が GitHub 上に自動作成**されます。

### 7. GitHub での最終マージ
- すべてのエージェントのタスクが `done` になると、GitHub の Epic ブランチに対して各エージェントの PR が届いています。
- ユーザーはそれらを確認・マージし、最後に Epic ブランチから `develop`/`main` へマージしてタスク全体が完了します。

---

## マルチエージェント並列開発ワークフロー

```
1. /create-spec "要件"         # spec-consultant が壁打ち対話し、仕様書 (docs/specs/*.md) を作成
                               # (設計などの上流工程は claude-3-opus での実行を推奨)
         ↓
2. /create-task <仕様書>       # task-planner2 が依存関係を整理し、全体計画 (orchestration-plan.md) 
                               # およびエージェント別の個別指示書 (docs/tasks/agent-A-001-*.md) を作成
                               # ※同時に機能全体の親となる Epic ブランチを切る
                               # (タスクの性質に応じて agent_cli を sonnet/agy/opus 等に割り振る)
         ↓
3. /start-all-tasks            # 未完了の全エージェントを Screen で一括同時起動（完了済みタスクは自動スキップ）
   (内部で ./scripts/manage-screen.sh が各エージェントを自動起動)
         ↓
4. 自律ライフサイクル実行 (screenセッション内)
   (run-lifecycle.sh が指示書の agent_cli を自動解析し、対応するツール(sonnet/agy等)で implementer を起動。
    実装完了時に自動でレビュー依頼を出し、親エージェント(Opus/task-planner2)がレビューを自律ループ実行)
         ├─ [実装中 / 修正中] ➡️ status: doing / fixing 
         ├─ [レビュー中]      ➡️ status: reviewing (親エージェントがレビュー検証)
         └─ [ユーザーへの質問]  ➡️ エージェントが AskUserQuestion 等で待機する際、
                                   notify.sh がビープ音とダイアログで Windows デスクトップに通知
         ↓
5. PR自動作成・更新
   (status: done になると、run-lifecycle.sh が自動で /pr-create を実行。
    すでに PR が存在する場合は push のみ行い、無ければ新規 PR を親 Epic ブランチに向けて作成)
         ↓
6. ユーザー確認
   (ユーザーが GitHub 上で作成された各タスクの PR を確認・マージ)
```

## エージェント（モデル・ツール）の切り替えについて

本ワークフローでは、処理内容やタスクの重さに合わせて、最適なエージェントツールやモデルを自動で切り替えて実行できます。

- **設計・計画・レビューフェーズ（上流・検証工程）**:
  仕様の壁打ち（`/create-spec`）、計画策定（`/create-task`）、および実装コードの検証（`/code-review`）は、仕様全体の文脈を深く理解している必要があるため、**`claude -m claude-3-opus`（Opus）の親エージェント（`task-planner2`）** が一貫して担当します。
- **実装フェーズ（並列実行工程）**:
  個別指示書の YAML フロントマターにある `agent_cli` メタデータにより、エージェントを動的に解決します。
  ```yaml
  agent_cli: sonnet   # claude -m claude-3-5-sonnet で起動
  # または
  agent_cli: agy      # agy (Antigravity) で起動
  ```
  `run-lifecycle.sh` がこの値を読み取り、該当する CLI ツールを自動選択して `screen` 下で並列処理を実行します。

## 仕様の変更・追加時のフロー

開発完了後に、要件の追加や仕様変更が発生した場合でも、本ワークフローは適切に差分開発をサポートします。

1.  **仕様書の再策定**: `/create-spec` を起動して差分要件を提示。`spec-consultant` が既存の仕様書 `docs/specs/*.md` を読み込んで「## 仕様変更履歴」を追記し、仕様書を更新します。
2.  **差分プランニング**: `/create-task` を再度実行。`task-planner2` が既存の `orchestration-plan.md` を解析し、**すでに `done` のタスクはそのまま残しつつ、追加実装に必要な新規のタスク（例: 連番をインクリメントした `agent-A-002-...` など）を計画に追加**します。
3.  **差分実装の起動**: `/start-all-tasks` を実行。すでに `done` のタスクは自動的に起動をスキップされ、**新規に追加された未完了タスクのみが Screen セッションで並列起動**します。
4.  **PRの自動ハンドリング**: 追加分のタスクが `done` に達すると、`run-lifecycle.sh` が自動で `/pr-create` を呼び出し、該当する差分ブランチから Epic ブランチに向けた新しい PR を作成します。

## 他の AI エージェント（Antigravity, Codexなど）での利用方法

本リポジトリはフォルダ名が `.claude` となっていますが、**Claude Code 以外の AI エージェントツールでもそのまま再利用できます**。
以下の設定を行うことで、別のエージェントに本テンプレートのプロンプトやスクリプトを認識させ、連携動作させることが可能です。

### 1. エージェントへの指示ファイルの紐付け (`CLAUDE.md`)
他の AI エージェント（`antigravity` や `codex` など）がプロジェクトをロードした際、自動的に本設定を参照して動作できるように、プロジェクトルートに `CLAUDE.md` を配置して以下の参照指示を記述します。

```markdown
# Project Instructions
このプロジェクトの開発ルール、エージェント定義、レビューガイドライン、および自動化スクリプトはすべて `.claude/` ディレクトリ内に配置されています。
タスクを実行する際は、必ず以下のドキュメントをロードし、その指示に従ってください。
- レビューガイドライン: `.claude/review-patterns.md`
- エージェント役割・プロンプト: `.claude/agents/`
- 各種カスタムコマンド定義: `.claude/commands/`
- 進捗管理スクリプト: `.claude/scripts/`
```

### 2. 実行時 AI CLI ツール名の切り替え (環境変数 `AI_CLI`)
Screen セッション内で動く自動ライフサイクルランナー (`run-lifecycle.sh`) は、デフォルトで `agy` コマンドを実行します。
他のエージェントツールを使用する場合は、起動前に環境変数 `AI_CLI` をエクスポートすることで、呼び出す CLI を変更できます。

*   **Claude Code を使用する場合**:
    ```bash
    export AI_CLI="claude"
    ```
*   **他の AI アシスタント CLI を使用する場合**:
    ```bash
    export AI_CLI="your-agent-cli-command"
    ```

## 通知の仕組み

エージェントがバックグラウンド（Screen 内）で稼働中に、不明点の質問やエラーにより人間の介入（入力待ち）が必要となった場合、`scripts/notify.sh` が作動します。
Windows のシステム機能（ビープ音）と前面ポップアップ（メッセージボックス）でデスクトップ通知が送信されるため、処理が気付かれずに停滞するのを防ぎます。

## 設計方針

- **競合の回避**: 各エージェントは `git subtree` を用いて、共通 Epic ブランチから派生させた個別のサブディレクトリ・ブランチで作業するため、並列実行してもコードのコンフリクトが起きません。
- **直列化の保証**: 定制が必要なタスクは、`task-planner2` が自動で直列の依存関係（フェーズ分け）として設計します。
- **検証の自動化**: 各エージェントは `package.json` などの設定ファイルを自動検出して linter や test を実行し、合格するまで次のステータスへ進めません。
