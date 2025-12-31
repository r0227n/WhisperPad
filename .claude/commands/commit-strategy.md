---
description: 複数変更ファイルを論理的なコミットに分割して実行
argument-hint: [--skip-confirm]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Read, Grep, Glob, TodoWrite, EnterPlanMode, ExitPlanMode
---

# Commit Strategy: 論理的コミット分割

## 引数

- `$ARGUMENTS`: `--skip-confirm` が指定された場合、plan mode 確認をスキップ

## 概要

複数ファイルの変更を論理的なコミットに分割し、依存関係を考慮した順序でコミットを作成します。

## 処理フロー

1. 変更ファイルの収集と分析
2. レイヤーによる分類
3. 依存関係に基づく順序決定
4. コミット戦略の立案
5. ユーザー確認（`--skip-confirm` 未指定時）
6. コミット実行

---

## Step 1: 現在の状態を確認

以下のコマンドで変更状態を取得してください:

```bash
git status --short
```

```bash
git diff --stat
```

```bash
git log --oneline -5
```

---

## Step 2: レイヤー分類ルール

変更ファイルを以下のレイヤーで分類してください:

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

### 分類の原則

- **下位レイヤー → 上位レイヤー** の順でコミット
- 同一レイヤー内は **関連機能** でグループ化
- **新規ファイル** と **変更ファイル** を区別して記載

---

## Step 3: 除外ファイル

以下のファイルはコミットから **除外** してください:

```
*.xcuserstate
xcschememanagement.plist
*.xcuserdatad/
.claude/
.DS_Store
Pods/
```

除外理由を説明し、必要に応じて `.gitignore` への追加を提案してください。

---

## Step 4: コミット戦略の立案

各コミットを以下の形式で整理してください:

```markdown
### Commit N: <type>(<scope>): <short description>

**ファイル:**

- `path/to/file1.swift` (新規/変更)
- `path/to/file2.swift` (新規/変更)

**内容:**
変更内容の簡潔な説明

**コマンド:**
git add <files>
git commit -m "<message>"
```

### コミットメッセージ形式

Conventional Commits 形式を使用:

```
<type>(<scope>): <description>

<body - 変更の詳細説明>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**type の種類:**

- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: リファクタリング
- `docs`: ドキュメント
- `test`: テスト
- `chore`: 雑務

---

## Step 5: ユーザー確認

`--skip-confirm` が **指定されていない** 場合:

1. 立案したコミット戦略を表示
2. `EnterPlanMode` を使用してユーザー確認を求める
3. ユーザーが承認したら Step 6 へ進む

ユーザーは以下のアクションが可能:

- **承認**: そのまま実行
- **修正依頼**: コミットの分割/統合を指示
- **キャンセル**: 実行せずに終了

---

## Step 6: コミット実行

承認後、以下の手順でコミットを実行:

1. `TodoWrite` で各コミットをタスクとして登録
2. 各コミットを順番に実行:
   - `git add <files>`
   - `git commit -m "<message>"`
3. 完了後、`git log --oneline -N` で結果を確認
4. コミット数とサマリーを報告

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

### Logging Categories

- `com.whisperpad` / `RecordingFeature`
- `com.whisperpad` / `TranscriptionFeature`
- `com.whisperpad` / `AudioRecorderClient`
- `com.whisperpad` / `TranscriptionClient`
- `com.whisperpad` / `OutputClient`
- `com.whisperpad` / `UserDefaultsClient`
