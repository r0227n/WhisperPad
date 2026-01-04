---
description: PR レビューコメントを分析し、1件ずつ対応・コミット
argument-hint: [--skip-confirm]
allowed-tools: Bash(gh api:*), Bash(gh pr view:*), Bash(git -C add:*), Bash(git -C commit:*), Bash(git -C diff:*), Bash(git -C push:*), Bash(git -C status:*), Read, Grep, Glob, Edit, TodoWrite, AskUserQuestion, EnterPlanMode, ExitPlanMode
---

# PR Comments: レビューコメント対応

## 引数

- `$ARGUMENTS`: `--skip-confirm` が指定された場合、ユーザー確認をスキップして自動で推奨対応を実行

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

以下の形式で各コメントの情報を整理:

```markdown
| #   | ファイル                       | 問題の概要                   | 推奨対応 | 理由                   | 修正内容の要約                           |
| --- | ------------------------------ | ---------------------------- | -------- | ---------------------- | ---------------------------------------- |
| 1   | AudioRecorder.swift            | 一時ファイル未クリーンアップ | 修正要   | リソースリーク防止     | エラーパスに FileManager.removeItem 追加 |
| 2   | FileOutputDetailsPopover.swift | 翻訳者コメント欠落           | 修正要   | 翻訳コンテキスト維持   | String(localized:comment:) に戻す        |
| 3   | SettingsFeature.swift          | 監視停止未実行               | 修正要   | リソースクリーンアップ | stopAudioLevelObservation 呼び出し       |
```

**含めるべき情報:**

- コメント番号 (#)
- 対象ファイルパス
- 問題の概要 (簡潔に)
- 推奨される対応 (修正要/不要)
- 推奨理由
- 修正内容の要約 (修正要の場合)

---

## Step 3: ユーザー確認

`--skip-confirm` が **指定されていない** 場合:

### 1. 分析結果の表示

Step 2 で作成した分析結果の表を表示し、全体像を把握できるようにする。

### 2. AskUserQuestion での個別確認

各レビューコメントについて、`AskUserQuestion` を使用して個別に対応を確認する。

**質問形式の例:**

```
コメント #1: AudioRecorder.swift - 一時ファイル未クリーンアップ
推奨: 修正要
理由: リソースリーク防止のため、エラーパス発生時に一時ファイルをクリーンアップする必要がある
修正内容: エラーパスに FileManager.removeItem 追加

このコメントにどう対応しますか?
```

**選択肢:**

- **推奨通り修正する**: Step 4 で修正・コミット・返信を実行
- **対応不要として返信する**: コード修正せず、理由を添えてコメントに返信のみ
- **スキップ (後で手動対応)**: 現時点では何もせず、後で手動で対応する

### 3. ユーザーの選択に基づいて実行計画を作成

各コメントへのユーザーの選択を記録し、Step 4 で実行する内容を確定する。

**`--skip-confirm` フラグが指定された場合:**
全てのコメントに対して自動で推奨対応を実行 (AskUserQuestion をスキップ)

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

```txt
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

```bash
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
