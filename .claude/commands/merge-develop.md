---
description: origin/develop をマージしコンフリクトを解消
argument-hint: [--skip-confirm] [--no-push]
allowed-tools: Bash(git -C add:*), Bash(git -C commit:*), Bash(git -C diff:*), Bash(git -C fetch:*), Bash(git -C log:*), Bash(git -C merge:*), Bash(git -C push:*), Bash(git -C stash:*), Bash(git -C status:*), Bash(xcodebuild:*), Read, Edit, Grep, Glob, TodoWrite, EnterPlanMode, ExitPlanMode
---

# Merge Develop: origin/develop マージ & コンフリクト解消

## 引数

- `$ARGUMENTS`:
  - `--skip-confirm`: plan mode 確認をスキップ
  - `--no-push`: マージ後のプッシュをスキップ

## 概要

現在のブランチに origin/develop をマージし、コンフリクトがあれば解消します。
ビルド検証後、リモートにプッシュします。

## 処理フロー

1. 現状確認（未コミット変更、差分コミット）
2. マージ実行
3. コンフリクト解消
4. ビルド検証
5. コミット & プッシュ
6. 後処理（stash 復元）

---

## Step 1: 現状確認

以下のコマンドで現在の状態を取得してください:

```bash
# 未コミット変更の確認
git status --short
```

```bash
# 最新の develop を取得
git fetch origin develop
```

```bash
# 差分コミットの確認（左: 現在ブランチ、右: develop）
git log --oneline HEAD...origin/develop --left-right
```

```bash
# 変更ファイルの確認
git diff --name-only HEAD origin/develop
```

### 判定

- 未コミット変更がある場合 → Step 2a へ
- 未コミット変更がない場合 → Step 2b へ

---

## Step 2a: 未コミット変更の退避

```bash
git stash
```

**注意**: stash した内容は Step 6 で復元します。

---

## Step 2b: マージ実行

```bash
git merge origin/develop
```

### 結果判定

- **成功**: Step 4 へ
- **コンフリクト発生**: Step 3 へ

---

## Step 3: コンフリクト解消

### 3.1 コンフリクトファイルの特定

```bash
git diff --name-only --diff-filter=U
```

### 3.2 コンフリクト箇所の確認

各ファイルのコンフリクトマーカーを検索:

```bash
grep -n "<<<<<<\|======\|>>>>>>" <file>
```

### 3.3 解消戦略

コンフリクトを解消する際の判断基準:

| 状況                           | 戦略                                                |
| ------------------------------ | --------------------------------------------------- |
| 機能追加（両方が新コード追加） | 両方を保持                                          |
| 同一機能の変更                 | コミットメッセージとコンテキストから判断            |
| コード移動/削除                | 移動先を確認し、重複を排除                          |
| 設定値の変更                   | 最新（develop）を優先、ただし現ブランチの意図を確認 |

### 3.4 解消手順

1. `Read` ツールでコンフリクト箇所を読み取り
2. 両ブランチのコミットメッセージを確認
3. `Edit` ツールでコンフリクトマーカーを削除し、適切なコードを残す
4. 未使用変数・import がないか確認

### 3.5 ステージング

```bash
git add <resolved-files>
```

---

## Step 4: ビルド検証

```bash
xcodebuild -project WhisperPad/WhisperPad.xcodeproj -scheme WhisperPad -configuration Debug build 2>&1 | tail -50
```

### 結果判定

- **BUILD SUCCEEDED**: Step 5 へ
- **BUILD FAILED**: エラーを修正し、再度 Step 4

---

## Step 5: コミット & プッシュ

### 5.1 マージコミット作成

コンフリクトがあった場合のみ:

```bash
git commit -m "$(cat <<'EOF'
Merge origin/develop into <current-branch>

Resolved conflicts:
- <file1>: <resolution summary>
- <file2>: <resolution summary>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### 5.2 プッシュ

`--no-push` が **指定されていない** 場合:

```bash
git push origin <current-branch>
```

---

## Step 6: 後処理

### stash があった場合

```bash
git stash pop
```

### 完了報告

- マージ結果のサマリーを表示
- 解消したコンフリクトの一覧
- プッシュした場合は最終コミットハッシュ

---

## プロジェクト固有情報: WhisperPad

### アーキテクチャ

- **TCA** (The Composable Architecture) v1.23.1
- macOS 14.0+ メニューバーアプリ

### コンフリクト頻出ファイル

| ファイル                   | 役割                   | 注意点                             |
| -------------------------- | ---------------------- | ---------------------------------- |
| `App/AppReducer.swift`     | ルートリデューサー     | delegate アクション、Effect の統合 |
| `Features/*/Feature.swift` | 各機能のリデューサー   | State/Action の変更                |
| `Clients/*Client.swift`    | 依存性インターフェース | DependencyKey の変更               |
| `Models/*.swift`           | データモデル           | プロパティ追加/変更                |

### ビルドコマンド

```bash
xcodebuild -project WhisperPad/WhisperPad.xcodeproj -scheme WhisperPad -configuration Debug build
```

### ディレクトリ構造

```
WhisperPad/WhisperPad/
├── App/           → AppReducer, AppDelegate
├── Features/      → Recording, Transcription, Settings, StreamingTranscription
├── Clients/       → AudioRecorder, Transcription, Output, UserDefaults
├── Models/        → データモデル
└── Views/         → 共通View
```
