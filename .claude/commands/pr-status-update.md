---
description: PR マージ状態を確認し todo.md を更新 (project)
argument-hint: <feature>.todo.md
allowed-tools: Bash, Read, Edit, Grep
---

## 概要

todo.md 内のタスクに紐づく PR のマージ状態を確認し、ステータスを更新します。

## ステータスフロー

```
pending → in_progress → review → completed
              ↓
           blocked (依存タスク未完了)
```

## 実行手順

### Step 1: todo.md を読み込み

```bash
cat <feature>.todo.md
```

### Step 2: PR 一覧を取得

```bash
gh pr list --state all --json number,title,state,mergedAt --limit 50
```

### Step 3: 各タスクの状態を確認

todo.md 内の `pr:` フィールドから PR 番号を抽出し、状態を確認:

- `merged` → status: completed に更新
- `open` → status: review のまま
- `closed` (not merged) → status: review のまま（手動確認必要）

### Step 4: todo.md を更新

マージ済み PR のタスクを `completed` に変更:

```markdown
- [x] status: completed
- pr: [#XX: ...](https://...)
```

### Step 5: 次 Phase のブロック解除

Phase 内の全タスクが `completed` の場合、次 Phase の `blocked` を `pending` に変更。

### Step 6: 結果報告

- 更新したタスク一覧
- 現在の Phase 状態
- 次に実行可能なタスク
