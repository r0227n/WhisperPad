---
description: Phase 単位で git worktree を使った並列開発を実行 (project)
argument-hint: <feature>.todo.md <phase 番号>
allowed-tools: Bash, Read, Glob, Grep, TodoWrite, Task, AskUserQuestion, Skill(parallel-dev:parallel-dev)
---

## 実行手順

### Step 1: 事前確認

1. todo.md から Phase N のタスク一覧を確認
2. 前 Phase が完了しているか確認（blocked なら中止）
3. ベースブランチを最新化:

```bash
git checkout develop
git pull origin develop
```

### Step 2: worktree 一括作成

Phase 内の全タスク用に worktree を作成:

```bash
git gtr new <branch-name-1> --from develop
git gtr new <branch-name-2> --from develop
```

**Note**: mise trust 警告は自動的に対応済み（または手動で `mise trust <path>` を実行）

### Step 3: 実装計画

各タスクの実装内容を整理:

1. todo.md の acceptance criteria を確認
2. 対象ファイルパスを特定
3. 各タスクの実装詳細を記述

### Step 4: 並列実装

Task ツールで parallel-dev エージェントを起動:

```
<Task tool>
subagent_type: parallel-dev:parallel-dev
run_in_background: true
prompt: |
  タスク: <branch-name>
  Worktree: /path/to/worktree
  ファイル: <target-files>
  内容: <implementation-details>

  完了後: mise run lint && mise run format → commit → push → gh pr create
</Task>
```

複数タスクは並列で Task を起動し、TaskOutput で結果を収集。

### Step 5: 検証と PR 作成

1. 各 worktree で lint/format 実行
2. コミット＆プッシュ
3. PR 作成（gh pr create）
4. todo.md を更新（status: review, pr: リンク）

### Step 6: todo.md 更新

- 実装タスクのステータスを `review` に更新
- PR リンクを追加
- PR マージ後に `completed` に変更
- 次 Phase のブロックを解除（blocked → pending）
