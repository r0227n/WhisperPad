---
description: PR レビューコメントを分析し、1件ずつ対応・コミット
argument-hint: [--skip-confirm]
allowed-tools: Bash(gh api:*), Bash(gh pr view:*), Bash(git -C add:*), Bash(git -C commit:*), Bash(git -C diff:*), Bash(git -C push:*), Bash(git -C status:*), Read, Grep, Glob, Edit, TodoWrite, EnterPlanMode, ExitPlanMode
---

# PR Comments: レビューコメント対応

## 引数

- `$ARGUMENTS`: `--skip-confirm` が指定された場合、plan mode 確認をスキップ

## 概要

GitHub PR のレビューコメントを取得・分析し、対応が必要なコメントは 1 件ずつ個別にコミットを作成します。
対応不要なコメントには理由を返信します。

## 処理フロー

1. PR 情報とコメント取得
2. コメント分析・分類
3. ユーザー確認（`--skip-confirm` 未指定時）
4. 対応実行（1 件ずつコミット or 理由を返信）
5. プッシュと完了報告

---

## Step 1: PR 情報とコメント取得

以下のコマンドで PR 情報を取得してください:

```bash
# PR 番号とリポジトリ情報
gh pr view --json number,headRepository,headRefName
```

```bash
# レビューコメント（コード行に対するコメント）
gh api /repos/{owner}/{repo}/pulls/{number}/comments
```

```bash
# PR 全体へのコメント
gh api /repos/{owner}/{repo}/issues/{number}/comments
```

### 取得すべき情報

レビューコメントから以下を抽出:

| フィールド               | 説明                        |
| ------------------------ | --------------------------- |
| `id`                     | コメント ID（返信時に使用） |
| `path`                   | 対象ファイルパス            |
| `line` / `original_line` | 対象行番号                  |
| `diff_hunk`              | 差分コンテキスト            |
| `body`                   | コメント本文                |
| `user.login`             | コメント投稿者              |

---

## Step 2: コメント分析・分類

各コメントを以下の基準で分類:

### 対応が必要なコメント

- コード修正の提案がある
- バグや問題点の指摘
- リファクタリングの提案
- セキュリティ上の懸念

### 対応不要なコメント

- 現在の実装が意図的である場合
- 設計上の理由で変更が不適切な場合
- 既に別の方法で対応済みの場合
- 質問や確認のみで変更不要な場合

### 分析結果の形式

```markdown
| #   | ファイル           | 問題         | 対応 | 理由         |
| --- | ------------------ | ------------ | ---- | ------------ |
| 1   | path/to/file.swift | 未使用変数   | 要   | -            |
| 2   | path/to/file.swift | 設計上の懸念 | 不要 | 意図的な実装 |
```

---

## Step 3: ユーザー確認

`--skip-confirm` が **指定されていない** 場合:

1. 分析結果を表示
2. `EnterPlanMode` を使用してユーザー確認を求める
3. ユーザーが承認したら Step 4 へ進む

ユーザーは以下のアクションが可能:

- **承認**: そのまま実行
- **修正依頼**: 対応方針の変更を指示
- **キャンセル**: 実行せずに終了

---

## Step 4: 対応実行

### 対応が必要なコメント

**1 件ずつ** 以下の手順で対応:

1. 対象ファイルを読み込み
2. 指摘内容に基づいて修正
3. 個別にコミット作成

```bash
# ファイルをステージング
git add <file>

# コミット作成
git commit -m "$(cat <<'EOF'
fix: <問題の簡潔な説明>

<詳細説明（必要に応じて）>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

4. 対応完了後、コメントスレッドに返信

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -f body="Fixed in <commit_hash>
<修正内容の簡潔な説明>"
```

### 対応不要なコメント

既存のコメントスレッドに理由を返信:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -f body="対応不要と判断しました。

理由: <具体的な理由>"
```

---

## Step 5: プッシュと完了報告

### プッシュ

```bash
git push
```

### 完了報告

以下の形式でサマリーを表示:

```markdown
## 対応完了

### 対応済みコメント (N 件)

| コミット | ファイル   | 修正内容         |
| -------- | ---------- | ---------------- |
| abc1234  | file.swift | 未使用変数を削除 |

### 未対応コメント (M 件)

| ファイル   | 理由               |
| ---------- | ------------------ |
| file.swift | 意図的な実装のため |
```

---

## コミットメッセージ規則

Conventional Commits 形式を使用:

```
<type>: <description>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**type の種類:**

| Type       | 用途                   |
| ---------- | ---------------------- |
| `fix`      | バグ修正、問題解決     |
| `refactor` | リファクタリング       |
| `docs`     | ドキュメント追加・修正 |
| `style`    | コードスタイル修正     |

---

## プロジェクト固有情報: WhisperPad

### アーキテクチャ

- **TCA** (The Composable Architecture) v1.23.1
- macOS 14.0+ メニューバーアプリ

### ディレクトリ構造

```
WhisperPad/WhisperPad/
├── App/           → AppReducer, AppDelegate
├── Features/      → Recording, Transcription, Settings
├── Clients/       → AudioRecorder, Transcription, Output, UserDefaults
├── Models/        → データモデル
└── Views/         → 共通View
```

### リポジトリ情報

- Owner: `r0227n`
- Repo: `WhisperPad`
