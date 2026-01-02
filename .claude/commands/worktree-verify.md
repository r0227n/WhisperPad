---
description: worktree で lint/format を実行し、変更があれば push (project)
argument-hint: <branch-name>
allowed-tools: Bash, Read, AskUserQuestion
---

## 概要

指定した worktree で lint/format を実行し、変更があればコミット＆プッシュします。

## 実行手順

### Step 1: worktree パスを特定

```bash
# worktree 一覧から対象を特定
git worktree list | grep "<branch-name>"
```

### Step 2: lint/format 実行

```bash
cd <worktree-path>/WhisperPad
mise run lint
mise run format
```

### Step 3: 変更確認

```bash
git status --short
```

### Step 4: 変更があればコミット＆プッシュ

```bash
# 変更がある場合のみ
git add .
git commit -m "style: Apply lint and format fixes

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

git push origin <branch-name>
```

### Step 5: 結果報告

- lint/format の結果
- コミット/プッシュの有無
- 現在のブランチ状態
