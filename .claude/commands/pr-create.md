---
description: develop との差分を整理し PR を作成・オープン
argument-hint: [--skip-confirm] [--draft]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git push:*), Bash(gh pr create:*), Read, Grep, Glob, TodoWrite, EnterPlanMode, ExitPlanMode
---

# Create PR: develop との差分から PR 作成

## 引数

- `$ARGUMENTS`:
  - `--skip-confirm`: plan mode 確認をスキップ
  - `--draft`: ドラフト PR として作成

## 概要

develop ブランチと現在のブランチの差分を分析し、整理された PR を作成・オープンします。

## 処理フロー

1. ブランチ情報の収集
2. 変更内容の分析
3. PR 内容の生成（テンプレート使用）
4. ユーザー確認（`--skip-confirm` 未指定時）
5. PR 作成 & オープン

---

## Step 1: ブランチ情報を収集

以下のコマンドで現在の状態を取得してください:

```bash
# 現在のブランチ
git branch --show-current
```

```bash
# develop との差分コミット
git log develop..HEAD --oneline
```

```bash
# 差分ファイル一覧
git diff develop..HEAD --stat
```

```bash
# リモートとの同期状態
git status -sb
```

---

## Step 2: 変更内容を分析

### コミット分類ルール

コミットメッセージの prefix から種類を判定:

| Prefix      | カテゴリ      |
| ----------- | ------------- |
| `feat:`     | New Features  |
| `fix:`      | Bug Fixes     |
| `refactor:` | Refactoring   |
| `docs:`     | Documentation |
| `test:`     | Tests         |
| `chore:`    | Chores        |

### ファイル分類ルール

| パスパターン        | レイヤー |
| ------------------- | -------- |
| `*/Models/*.swift`  | Models   |
| `*/Clients/*.swift` | Clients  |
| `*/Features/*/`     | Features |
| `*/App/*.swift`     | App      |
| `*/Tests/`          | Tests    |
| `*.md`, `docs/`     | Docs     |

---

## Step 3: PR 内容を生成

### PR テンプレート

@.github/pull_request_template.md

### タイトル形式

```
<type>(<scope>): <summary>
```

**type**: feat, fix, refactor, docs, test, chore
**scope**: 主要な変更対象（Settings, Recording, Transcription など）
**summary**: 変更の簡潔な説明（英語、50 文字以内）

### 本文生成ルール

テンプレートの各セクションを変更内容に基づいて埋める:

1. **Summary**: 主要な変更を 1-3 点でまとめる
2. **Changes**: コミットを種類ごとに整理
3. **Files Changed**: ファイルをレイヤーごとに整理
4. **Test Plan**: 変更に応じたテスト手順を提案

---

## Step 4: ユーザー確認

`--skip-confirm` が **指定されていない** 場合:

1. 生成した PR タイトルと本文を表示
2. `EnterPlanMode` を使用してユーザー確認を求める
3. ユーザーが承認したら Step 5 へ進む

ユーザーは以下のアクションが可能:

- **承認**: そのまま PR 作成
- **修正依頼**: タイトルや説明の変更を指示
- **キャンセル**: PR 作成せずに終了

---

## Step 5: PR 作成 & オープン

### 事前確認

1. リモートにブランチが push されているか確認
2. 未 push の場合は `git push -u origin <branch>` を実行

### PR 作成コマンド

```bash
# 通常の PR
gh pr create --base develop --title "<title>" --body "<body>"

# ドラフト PR（--draft 指定時）
gh pr create --base develop --title "<title>" --body "<body>" --draft
```

### 作成後

1. 作成された PR の URL を表示

---

## プロジェクト固有情報: WhisperPad

### アーキテクチャ

- **TCA** (The Composable Architecture) v1.23.1
- macOS 14.0+ メニューバーアプリ

### 主要な機能スコープ

| Scope         | 説明                        |
| ------------- | --------------------------- |
| Recording     | 音声録音機能                |
| Transcription | WhisperKit 文字起こし       |
| Settings      | 設定画面                    |
| Output        | クリップボード/ファイル出力 |
| App           | アプリ全体・統合            |

### ディレクトリ構造

```
WhisperPad/WhisperPad/
├── App/           → AppReducer, AppDelegate
├── Features/      → Recording, Transcription, Settings
├── Clients/       → AudioRecorder, Transcription, Output, UserDefaults
├── Models/        → データモデル
└── Views/         → 共通View
```
