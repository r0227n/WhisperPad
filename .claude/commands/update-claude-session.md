---
description: セッション情報を整理し、develop から新規ブランチで PR 作成
argument-hint: <branch-name>
allowed-tools: Bash(cp:*), Bash(gh pr create:*), Bash(git -C add:*), Bash(git -C branch:*), Bash(git -C commit:*), Bash(git -C diff:*), Bash(git -C log:*), Bash(git -C push:*), Bash(git -C status:*), Bash(git -C worktree:*), Bash(mkdir:*), Read, Grep, Glob, TodoWrite, AskUserQuestion
---

# Update Claude Session: セッション情報から PR 作成

## 引数

- `$ARGUMENTS`: ブランチ名（未指定時は AskUserQuestion で入力）

## 概要

セッション内の情報を収集・整理し、`.claude/` 配下のファイル/ディレクトリの変更を develop から新規ブランチで PR 作成まで行います。

## 処理フロー

1. セッション情報の収集
2. 変更内容の整理
3. ブランチ名の決定
4. worktree 作成
5. 変更ファイルのコピー
6. /pr-create 処理の実行

---

## Step 1: セッション情報の収集

以下のコマンドで現在の状態を取得:

```bash
# 現在の作業ディレクトリ
pwd

# 現在のブランチ
git branch --show-current

# 未コミット変更
git status --short

# .claude/ 配下の変更を特定
git status --short .claude/
```

---

## Step 2: 変更内容の整理

`git status --short` の出力を分類:

| 記号 | 状態         | 説明                    |
| ---- | ------------ | ----------------------- |
| `??` | 新規作成     | Untracked ファイル      |
| `M`  | 編集         | Modified ファイル       |
| `D`  | 削除         | Deleted ファイル        |
| `A`  | ステージ済み | Added (staged) ファイル |

### 対象ファイルのリスト化

```markdown
## 変更ファイル一覧

### 新規作成

- `path/to/new-file.md`

### 編集

- `path/to/modified-file.md`

### 削除

- `path/to/deleted-file.md`
```

---

## Step 3: ブランチ名の決定

### 引数が指定されている場合

`$ARGUMENTS` をブランチ名として使用

### 引数が未指定の場合

AskUserQuestion で入力:

```
question: "新しいブランチ名を入力してください"
options:
  - label: "feature/..."
    description: "新機能用ブランチ"
  - label: "fix/..."
    description: "バグ修正用ブランチ"
  - label: "docs/..."
    description: "ドキュメント更新用ブランチ"
```

---

## Step 4: worktree 作成

### worktree 名の自動生成

ブランチ名から worktree ディレクトリ名を生成:

- `feature/xxx` → `feature-xxx`
- `fix/yyy` → `fix-yyy`
- `docs/zzz` → `docs-zzz`

### コマンド

```bash
# メインリポジトリに移動
cd /Users/r0227n/Dev/WhisperPad

# worktree 作成
git worktree add ../WhisperPad-worktrees/<worktree-name> -b <branch-name> develop
```

---

## Step 5: 変更ファイルのコピー

現在のworktreeから新しいworktreeに変更ファイルをコピー:

```bash
# 新規作成・編集ファイルをコピー
cp <source-file> <dest-worktree>/<file-path>

# ディレクトリが存在しない場合は作成
mkdir -p <dest-worktree>/<dir-path>
```

### 注意事項

- 削除ファイルは新 worktree では操作不要（develop ベースなので元から存在しない可能性）
- `.claude/` 配下のファイルのみをコピー対象とする

---

## Step 6: /pr-create 処理の実行

新しい worktree で以下の処理を実行:

### 6.1 コミット戦略の立案

レイヤー分類ルールに従ってコミットを分割:

| 優先度 | レイヤー | パスパターン                     |
| ------ | -------- | -------------------------------- |
| 1      | Commands | `.claude/commands/*.md`          |
| 2      | Skills   | `.claude/skills/**`              |
| 3      | Agents   | `.claude/agents/**`              |
| 4      | Hooks    | `.claude/hooks/**`               |
| 5      | Settings | `.claude/settings*.json`         |
| 6      | Misc     | その他 `.claude/` 配下のファイル |

### 6.2 コミットメッセージ形式

```
<type>(<scope>): <description>

<body - 変更の詳細説明>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**type**: docs, feat, fix, refactor, chore
**scope**: commands, skills, agents, hooks, settings

### 6.3 AskUserQuestion で確認

```markdown
## コミット戦略

### Commit 1: <type>(<scope>): <description>

- `path/to/file1.md`
- `path/to/file2.md`

---

## PR 内容

**タイトル**: <title>

**本文**:

<body>
```

```
question: "以下の内容で実行しますか？"
options:
  - label: "実行"
    description: "コミット作成 → PR 作成を実行"
  - label: "コミットのみ"
    description: "コミットのみ作成（PR は作成しない）"
  - label: "キャンセル"
    description: "実行せずに終了"
```

### 6.4 コミット実行

```bash
git add <files>
git commit -m "<message>"
```

### 6.5 PR 作成

```bash
# ブランチを push
git push -u origin <branch-name>

# PR 作成
gh pr create --base develop --title "<title>" --body "<body>"
```

---

## プロジェクト固有情報: WhisperPad

### worktree ベースディレクトリ

```
/Users/r0227n/Dev/WhisperPad-worktrees/
```

### メインリポジトリ

```
/Users/r0227n/Dev/WhisperPad
```

### .claude/ 構造

```
.claude/
├── agents/      → エージェント定義
├── commands/    → カスタムスラッシュコマンド
├── hooks/       → フック
├── skills/      → スキル
├── settings.json
└── settings.local.json
```
