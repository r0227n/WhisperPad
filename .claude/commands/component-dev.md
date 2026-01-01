---
description: コンポーネント単位でworktreeを作成し、フェーズ別に実装・マージしてPR作成
argument-hint: <機能名>
allowed-tools: Bash(git -C add:*), Bash(git -C commit:*), Bash(git -C diff:*), Bash(git -C log:*), Bash(git -C status:*), Bash(git -C worktree:*), Bash(git -C branch:*), Bash(git -C push:*), Bash(git gtr:*), Bash(git merge:*), Bash(mise:*), Bash(gh pr create:*), Read, Write, Edit, Grep, Glob, TodoWrite, AskUserQuestion, Skill(pr-create)
---

# Component Dev: コンポーネント単位並列開発ワークフロー

## 引数

- `$ARGUMENTS`: 機能名（例: `shortcut-ui`, `model-settings`）

## 概要

UI 実装をコンポーネント単位で worktree に分離し、フェーズ別に実装・検証・マージを行います。
機能名のみ入力すれば、AI がフェーズ分割から実装、PR 作成まで自動実行します。

## 処理フロー

1. 機能分析とフェーズ自動生成
2. 各フェーズで worktree 作成 → 実装 → lint/format → マージ
3. 最終検証後に `/pr-create` 実行

---

## Step 1: 現在の状態を確認

以下のコマンドで現在のブランチ状態を取得:

```bash
git branch --show-current
git status --short
git worktree list
```

---

## Step 2: フェーズ自動生成

機能名 `$ARGUMENTS` を分析し、以下のレイヤー分類に基づいてフェーズを自動生成:

### レイヤー分類ルール

| 優先度 | フェーズ | レイヤー     | 説明                                       |
| ------ | -------- | ------------ | ------------------------------------------ |
| 1      | Phase 1  | Models/Types | データモデル、enum 拡張、基礎型            |
| 2      | Phase 2  | Components   | 新規 UI コンポーネント、State 追加         |
| 3      | Phase 3  | Integration  | 既存 View のリファクタリング、Feature 統合 |

### フェーズ定義の出力形式

```markdown
## フェーズ計画

### Phase 1: <概要>

- worktree: `feature/<機能名>-phase1`
- 変更ファイル: `<ファイルパス>`
- 内容: <実装内容>

### Phase 2: <概要>

...
```

---

## Step 3: フェーズ実行ループ

各フェーズで以下を実行:

### 3.1 worktree 作成

```bash
# worktree作成（現在のブランチから分岐）
git gtr new feature/<機能名>-phase<N> --from <現在のブランチ>
```

### 3.2 実装

worktree 内でコンポーネントを実装:

ファイルの作成・編集を実行。

### 3.3 lint/format 検証

```bash
mise run lint
mise run format
```

**問題があれば修正**してから次へ進む。

### 3.4 コミット

```bash
git add -A
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<body - 変更の詳細説明>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### 3.5 メインブランチにマージ

```bash

# マージ
git merge feature/<機能名>-phase<N> --no-ff -m "$(cat <<'EOF'
Merge feature/<機能名>-phase<N>: <概要>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Step 4: 最終検証

全フェーズ完了後:

```bash
mise run lint
mise run format
```

問題がなければ Step 5 へ。

---

## Step 5: PR 作成

`/pr-create` を実行して PR を作成。

---

## 命名規則

### worktree 名

- 形式: `feature/<機能名>-phase<N>`
- 例: `feature/shortcut-ui-phase1`, `feature/shortcut-ui-phase2`

### コミットメッセージ

- Conventional Commits 形式
- type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- scope: 変更対象（Settings, Recording, etc.）

---

## 実績例: shortcut-ui

### 入力

```
/component-dev shortcut-ui
```

### 自動生成されたフェーズ

| Phase | worktree                     | 内容                      | ファイル                                       |
| ----- | ---------------------------- | ------------------------- | ---------------------------------------------- |
| 1     | `feature/shortcut-ui-phase1` | HotkeyType 拡張           | SettingsTypes.swift                            |
| 2     | `feature/shortcut-ui-phase2` | ShortcutKeyButton + State | ShortcutKeyButton.swift, SettingsFeature.swift |
| 3     | `feature/shortcut-ui-phase3` | HotkeySettingsTab 再設計  | HotkeySettingsTab.swift                        |

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

### lint/format コマンド

```bash
mise run lint        # SwiftLint実行
mise run format      # SwiftFormat実行
mise run check       # lint + format check (CI用)
```
