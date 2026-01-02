---
description: git gtr で worktree 作成 → 機能実装 → コミット分割 → 現在のブランチにマージ
argument-hint: <feature-name> [--skip-planning] [--no-merge] [--skip-test]
allowed-tools: Bash(git gtr:*), Bash(git add:*), Bash(git branch:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*), Bash(git merge:*), Bash(git status:*), Read, Write, Edit, Grep, Glob, TodoWrite, AskUserQuestion, EnterPlanMode, ExitPlanMode, Task
---

# Feature Development: Git Worktree ベースの機能開発

Git worktree を使用した機能開発ワークフローを自動化します。
`git gtr` (git-worktree-runner) を使用して、独立した環境で機能を実装し、TCAレイヤー別にコミットを分割して、メインセッションにマージします。

## 引数

- `<feature-name>`: 機能名（必須） - `feature/` プレフィックスは自動付与
- `--skip-planning`: 計画フェーズをスキップして即実装
- `--no-merge`: マージせずにworktree内で作業のみ
- `--skip-test`: テストworktreeをスキップ

## 処理フロー概要

1. 現在のブランチ情報取得
2. ブランチ名生成と確認
3. worktree作成（git gtr new）
4. 機能実装（git gtr ai で実装）
5. コミット戦略立案（TCAレイヤー別）
6. 自動コミット実行
7. 現在のブランチへマージ
8. テスト用worktree作成
9. テスト実行とfix loop
10. テスト完了後メインセッションにマージ
11. worktree削除確認

---

## Step 1: 現在のブランチ情報取得

まず、現在作業しているブランチを確認します。

```bash
# 現在のブランチ名を取得
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

# 現在のworktree一覧を確認
git gtr list
```

**重要**: マージ先は `develop` ではなく、このコマンドを実行した `$CURRENT_BRANCH` です。

---

## Step 2: ブランチ名生成と確認

引数から適切なブランチ名を生成し、ユーザーに確認します。

### ブランチ名生成ロジック

```python
# Pythonで実装例
feature_name = arguments.strip()

# すでに feature/ で始まる場合はそのまま
if feature_name.startswith('feature/'):
    branch_name = feature_name
else:
    branch_name = f'feature/{feature_name}'

# ブランチ名のサニタイズ（スペース → ハイフン）
branch_name = branch_name.replace(' ', '-')
```

### ユーザー確認

AskUserQuestion を使用して、作成内容を確認：

```yaml
question: '以下の内容で worktree を作成しますか？'
header: 'Worktree作成'
multiSelect: false
options:
  - label: '作成'
    description: 'ブランチ「{branch_name}」で worktree を作成します'
  - label: '名前変更'
    description: 'ブランチ名を変更して作成します'
  - label: 'キャンセル'
    description: '作成せず終了します'
```

「名前変更」が選択された場合は、再度 AskUserQuestion で新しい名前を入力してもらいます。

---

## Step 3: worktree 作成（git gtr new）

`git gtr new` コマンドでworktreeを作成します。

```bash
# worktree 作成
git gtr new $BRANCH_NAME

# 作成確認
echo "✅ Worktree created:"
git gtr list
```

**git gtr の利点**:
- 自動でベースディレクトリ構造を作成
- エディタ統合（`git gtr editor <branch-name>` で切り替え可能）
- 設定ファイルの自動コピー

---

## Step 4: 機能実装（git gtr ai で実装）

### 4.1 実装計画立案（--skip-planning でない場合）

```markdown
Task(
  subagent_type="Plan",
  prompt="""
機能要件: {FEATURE_NAME}
現在のブランチ: {CURRENT_BRANCH}
対象worktree: {BRANCH_NAME}

TCAアーキテクチャに基づいて実装計画を立案してください。

必須項目:
- 変更が必要なファイルのリスト
- レイヤー別の実装順序（Models → Clients → Features → App）
- 各ステップの詳細説明
- 並列実装可能な部分の特定
"""
)
```

### 4.2 worktree内での実装

```bash
# worktree内でClaude Codeを起動
git gtr ai $BRANCH_NAME

# 起動されたClaude Codeセッション内で:
# 1. 実装計画に基づいて実装
# 2. TodoWriteでタスク管理
# 3. 並列可能な作業は並列で実施
# 4. 依存関係があるものは依存先完了後に実施
```

**並列開発戦略**:

| レイヤー | 独立性 | 実装タイミング |
|---------|--------|---------------|
| Models | 高 | 最初に実装可能 |
| Clients | 中 | Models後に実装可能 |
| Features | 低 | Models/Clients完了後 |
| App | 最低 | すべて完了後 |

独立性の高い Models と Clients は並列実装可能です。

---

## Step 5: コミット戦略立案（TCAレイヤー別）

実装完了後、変更ファイルをTCAレイヤー別に分類します。

### レイヤー分類

| 優先度 | レイヤー | パスパターン | コミット順序 |
|--------|----------|--------------|--------------|
| 1 | Models | `*/Models/*.swift` | 1st commit |
| 2 | Clients (Interface) | `*/Clients/*Client.swift` | 2nd commit |
| 2 | Clients (Live) | `*/Clients/*ClientLive.swift` | 3rd commit |
| 3 | Features | `*/Features/*/` | 4th commit |
| 4 | App | `*/App/*.swift` | 5th commit |
| 5 | Misc | その他（tests, docs, etc） | 6th commit |

### コミットメッセージ形式

```
<type>(<scope>): <description>

<body>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**type の種類**:
- `feat`: 新機能追加
- `fix`: バグ修正
- `refactor`: リファクタリング
- `test`: テスト追加
- `docs`: ドキュメント更新

---

## Step 6: 自動コミット実行

worktree内のClaude Codeセッションでレイヤー別にコミットを実行します。

```bash
# worktree内でClaude Codeを起動（まだ起動していない場合）
git gtr ai $BRANCH_NAME

# Claude Codeセッション内で:
# レイヤー別にコミット
for layer in models clients-interface clients-live features app misc; do
    # レイヤーに該当するファイルを追加
    git add <layer-specific-files>

    # 空コミットを避ける
    if git diff --cached --quiet; then
        echo "No changes for layer: $layer"
        continue
    fi

    # コミット作成
    git commit -m "feat($layer): {FEATURE_NAME} implementation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
done

# コミット履歴確認
echo "✅ Commits created:"
git log --oneline -10
```

---

## Step 7: 現在のブランチへマージ

**重要**: `develop` ではなく、**このコマンドを実行したブランチ** にマージします。

```bash
# メインセッションでマージ実行
git merge $BRANCH_NAME --no-ff -m "Merge $BRANCH_NAME: {FEATURE_DESCRIPTION}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# マージ確認
echo "✅ Merged to $CURRENT_BRANCH:"
git log --oneline -5
```

**フラグによる制御**:
- `--no-merge` フラグが指定されている場合、このステップをスキップします
- マージせずにworktree内で作業を継続できます

---

## Step 8: テスト用worktree作成

`--skip-test` フラグが指定されていない場合、テスト専用のworktreeを作成します。

```bash
# テスト用ブランチ名生成
TEST_BRANCH="test/$CURRENT_BRANCH"

# テスト用worktree作成
echo "Creating test worktree: $TEST_BRANCH"
git gtr new $TEST_BRANCH

# 作成確認
echo "✅ Test worktree created:"
git gtr list
```

**目的**: 実装完了後、独立した環境でテストを実行し、テストが合格するまで修正を繰り返します。

---

## Step 9: テスト実行とfix loop

テストworktree内で、テストが合格するまで修正を繰り返します。

```bash
# テストworktree内でClaude Codeを起動
git gtr ai $TEST_BRANCH

# Claude Codeセッション内で:
MAX_ATTEMPTS=5
attempt=0

while [ $attempt -lt $MAX_ATTEMPTS ]; do
    echo "Running tests (attempt $((attempt + 1))/$MAX_ATTEMPTS)..."

    if mise run test; then
        echo "✅ All tests passed!"
        break
    else
        echo "❌ Tests failed. Analyzing failures..."
        attempt=$((attempt + 1))

        if [ $attempt -ge $MAX_ATTEMPTS ]; then
            echo "⚠️ Maximum attempts reached. Please review manually."
            # AskUserQuestion で継続するか確認
            break
        fi

        # Taskツールでテスト失敗分析と修正
        # 修正後、自動コミット
        git add .
        git commit -m "fix: テスト失敗修正 (attempt $attempt)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
    fi
done
```

**修正プロセス**:
1. テスト失敗ログを分析
2. Taskツールで原因特定と修正実施
3. 修正内容をコミット
4. 再度テスト実行
5. 最大5回まで繰り返し（無限ループ回避）

---

## Step 10: テスト完了後メインセッションにマージ

テストが合格したら、テストブランチを現在のブランチにマージします。

```bash
# メインセッションでマージ実行
git merge $TEST_BRANCH --no-ff -m "Merge $TEST_BRANCH: テスト修正完了

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# マージ確認
echo "✅ Test fixes merged to $CURRENT_BRANCH:"
git log --oneline -5
```

---

## Step 11: worktree 削除確認

作業完了後、worktreeを削除するかユーザーに確認します。

### ユーザー確認

```yaml
question: 'worktree を削除しますか？'
header: 'Worktree削除'
multiSelect: false
options:
  - label: '削除'
    description: 'マージ完了後、両方のworktree (feature + test) を削除します'
  - label: '保持'
    description: 'worktree をそのまま保持します（後で手動削除可能）'
```

### 削除実行

```bash
# Feature worktree削除
echo "Removing feature worktree: $BRANCH_NAME"
git gtr rm $BRANCH_NAME

# Test worktree削除（--skip-testでない場合）
if [ -z "$SKIP_TEST" ]; then
    echo "Removing test worktree: $TEST_BRANCH"
    git gtr rm $TEST_BRANCH
fi

# 削除確認
echo "✅ Cleanup completed. Remaining worktrees:"
git gtr list
```

---

## プロジェクト固有情報: WhisperPad

### アーキテクチャ

- **TCA** (The Composable Architecture) v1.23.1
- **macOS** 14.0+ メニューバーアプリ
- **Swift** 5.10

### TCA レイヤー構造

```
WhisperPad/
├── Models/              # データモデル（高独立性）
├── Clients/             # 依存性（中独立性）
│   ├── *Client.swift    # インターフェース
│   └── *ClientLive.swift # 実装
├── Features/            # 機能（低独立性）
│   ├── Recording/
│   ├── Transcription/
│   └── Settings/
└── App/                 # アプリケーション層（統合）
    ├── AppReducer.swift
    └── AppDelegate.swift
```

### 除外ファイル

git gtr が自動で除外するファイル:
- `*.xcuserstate`
- `xcschememanagement.plist`
- `.claude/`（設定ファイルは別途同期）

---

## 使用例

### 基本的な使用方法

```bash
# 新機能「ショートカットカスタマイズ」を実装
/feature-dev shortcut-customization
```

実行フロー:
1. ブランチ名確認（`feature/shortcut-customization`）
2. worktree作成
3. 実装計画立案
4. `git gtr ai feature/shortcut-customization` で実装
5. TCAレイヤー別にコミット分割
6. 現在のブランチにマージ
7. テストworktree作成
8. テスト実行と修正
9. テスト完了後マージ
10. worktree削除確認

### フラグ付き使用

```bash
# 計画をスキップして即実装（経験者向け）
/feature-dev audio-filter --skip-planning

# マージせずにworktreeで作業のみ
/feature-dev experimental-feature --no-merge

# テストworktreeをスキップ
/feature-dev quick-fix --skip-test

# 複数フラグの組み合わせ
/feature-dev prototype --skip-planning --no-merge --skip-test
```

---

## トラブルシューティング

### worktree作成に失敗する

```bash
# エラー確認
git gtr list

# 既存worktreeと名前が重複している場合
git gtr rm <existing-branch>

# または別の名前を使用
```

### テストが無限ループする

- 最大試行回数制限（5回）により自動停止
- 手動でレビューが必要な場合は AskUserQuestion で確認

### マージコンフリクトが発生

```bash
# コンフリクト確認
git status

# 手動でコンフリクト解決後
git add .
git commit
```

---

## 参考リンク

- [git-worktree-runner](https://github.com/coderabbitai/git-worktree-runner)
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- WhisperPad CLAUDE.md - プロジェクト固有の開発ガイドライン
