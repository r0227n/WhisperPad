---
description: 未コミット変更のコミット分割 + develop との差分から PR 作成
argument-hint: [--skip-confirm] [--draft]
allowed-tools: Bash(gh pr create:*), Bash(git -C add:*), Bash(git -C branch:*), Bash(git -C commit:*), Bash(git -C diff:*), Bash(git -C log:*), Bash(git -C push:*), Bash(git -C status:*), Read, Grep, Glob, TodoWrite, AskUserQuestion
---

# Create PR: コミット分割 & PR 作成

## 引数

- `$ARGUMENTS`:
  - `--skip-confirm`: AskUserQuestion 確認をスキップ
  - `--draft`: ドラフト PR として作成

## 概要

未コミットの変更がある場合はコミット戦略を立案し、develop ブランチとの差分から PR を作成します。
**一度の確認で両方を実行** できます。

## 処理フロー

1. ブランチ情報の収集
2. 未コミット変更の検出
3. (変更あり) コミット戦略の立案
4. PR 内容の生成
5. AskUserQuestion で統合確認（`--skip-confirm` 未指定時）
6. コミット実行（該当時）
7. PR 作成 & オープン

---

## Step 1: ブランチ情報を収集

以下のコマンドで現在の状態を取得:

```bash
git branch --show-current
git status --short
git log develop..HEAD --oneline
git diff develop..HEAD --stat
```

---

## Step 2: 未コミット変更の検出

`git status --short` の出力を確認:

- **出力あり** → Step 3（コミット戦略）へ
- **出力なし** → Step 4（PR 内容生成）へスキップ

---

## Step 3: コミット戦略の立案

未コミット変更がある場合、以下のルールでコミットを分割:

### レイヤー分類ルール

| 優先度 | レイヤー            | パスパターン                  | 説明                         |
| ------ | ------------------- | ----------------------------- | ---------------------------- |
| 1      | Models              | `*/Models/*.swift`            | データモデル、基礎型         |
| 2      | Clients (Interface) | `*/Clients/*Client.swift`     | 依存性インターフェース       |
| 2      | Clients (Live)      | `*/Clients/*ClientLive.swift` | Live 実装                    |
| 2      | Clients (Service)   | `*/Clients/*Service.swift`    | サービス層                   |
| 3      | Features            | `*/Features/*/`               | TCA Feature (Reducer + View) |
| 3      | Views               | `*/Views/*.swift`             | 独立した View                |
| 4      | App                 | `*/App/*.swift`               | アプリルート統合             |
| 5      | Misc                | その他                        | 設定ファイル、ドキュメント等 |

### 除外ファイル

- `*.xcuserstate`
- `xcschememanagement.plist`
- `*.xcuserdatad/`
- `.claude/`
- `.DS_Store`
- `Pods/`

### コミットメッセージ形式

```
<type>(<scope>): <description>

<body - 変更の詳細説明>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**type**: feat, fix, refactor, docs, test, chore

---

## Step 4: PR 内容を生成

### PR テンプレート

@.github/pull_request_template.md

### タイトル形式

```
<type>(<scope>): <summary>
```

**scope**: 主要な変更対象（Settings, Recording, Transcription, App など）
**summary**: 変更の簡潔な説明（英語、50 文字以内）

### 本文生成ルール

1. **Summary**: 主要な変更を 1-3 点でまとめる
2. **Changes**: コミットを種類ごとに整理（New Features / Bug Fixes / Refactoring）
3. **Test Plan**: 変更に応じたテスト手順を提案

---

## Step 5: AskUserQuestion で統合確認

`--skip-confirm` が **指定されていない** 場合、以下の形式で確認:

### 確認内容

未コミット変更がある場合:

```markdown
## コミット戦略

### Commit 1: <type>(<scope>): <description>

- `path/to/file1.swift`
- `path/to/file2.swift`

### Commit 2: ...

---

## PR 内容

**タイトル**: <title>

**本文**:

<body>
```

### AskUserQuestion の質問

```yml
question: '以下の内容で実行しますか？'
options:
  - label: '実行'
    description: 'コミット作成 → PR 作成を実行'
  - label: 'コミットのみ'
    description: 'コミットのみ作成（PR は作成しない）'
  - label: 'PR のみ'
    description: '既存コミットで PR のみ作成'
```

---

## Step 6: コミット実行

未コミット変更があり、ユーザーが承認した場合:

1. `TodoWrite` で各コミットをタスクとして登録
2. 各コミットを順番に実行:
   ```bash
   git add <files>
   git commit -m "<message>"
   ```
3. `git log --oneline -N` で結果を確認

---

## Step 7: PR 作成 & オープン

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

```bash
WhisperPad/WhisperPad/
├── App/           → AppReducer, AppDelegate
├── Features/      → Recording, Transcription, Settings
├── Clients/       → AudioRecorder, Transcription, Output, UserDefaults
├── Models/        → データモデル
└── Views/         → 共通View
```

### Logging Categories

- `com.whisperpad` / `RecordingFeature`
- `com.whisperpad` / `TranscriptionFeature`
- `com.whisperpad` / `AudioRecorderClient`
- `com.whisperpad` / `TranscriptionClient`
- `com.whisperpad` / `OutputClient`
- `com.whisperpad` / `UserDefaultsClient`
