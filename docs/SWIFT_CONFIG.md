# 開発ツールガイド

このドキュメントでは、本プロジェクトで使用する開発ツール（状態管理ライブラリ、Linter、Formatter）について説明します。

---

## 目次

- [状態管理](#状態管理)
  - [The Composable Architecture (TCA)](#the-composable-architecture-tca)
- [バージョン管理](#バージョン管理)
  - [mise](#mise)
- [Linter](#linter)
  - [SwiftLint](#swiftlint)
- [Formatter](#formatter)
  - [SwiftFormat](#swiftformat)
- [開発フロー](#開発フロー)
- [セットアップ手順](#セットアップ手順)
- [CI/CD統合](#cicd統合)

---

## 状態管理

### The Composable Architecture (TCA)

本プロジェクトでは、状態管理に **The Composable Architecture (TCA)** を採用しています。

| 項目 | 内容 |
|------|------|
| リポジトリ | [pointfreeco/swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) |
| バージョン | 1.23.1+ |
| ライセンス | MIT |
| GitHub Stars | 14,000+ |

#### 採用理由

- **単方向データフロー**: 予測可能な状態変化
- **テスト容易性**: `TestStore` による詳細なテストが可能
- **機能分割**: 大きな機能を小さなコンポーネントに分割・合成
- **Swift 6対応**: 最新のSwift Concurrencyに完全対応
- **活発なメンテナンス**: Point-Freeチームによる継続的な開発

#### インストール

```swift
// Package.swift
dependencies: [
    .package(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        from: "1.23.1"
    ),
]
```

#### 基本構造

```swift
import ComposableArchitecture

@Reducer
struct Feature {
    @ObservableState
    struct State: Equatable {
        var count = 0
    }
    
    enum Action {
        case incrementButtonTapped
        case decrementButtonTapped
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .incrementButtonTapped:
                state.count += 1
                return .none
            case .decrementButtonTapped:
                state.count -= 1
                return .none
            }
        }
    }
}
```

#### 学習リソース

- [公式ドキュメント](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/)
- [Meet the Composable Architecture チュートリアル](https://pointfreeco.github.io/swift-composable-architecture/main/tutorials/meetcomposablearchitecture/)
- [Point-Free 動画シリーズ](https://www.pointfree.co/collections/composable-architecture)

---

## Linter

### SwiftLint

コード品質の維持と一貫性のために **SwiftLint** を使用します。

| 項目 | 内容 |
|------|------|
| リポジトリ | [realm/SwiftLint](https://github.com/realm/SwiftLint) |
| バージョン | 0.62.2+ |
| ルール数 | 200+ |

#### インストール

```bash
# mise経由でインストール（.mise.tomlに基づく）
mise install
```

#### 設定ファイル

プロジェクトルートに `.swiftlint.yml` を配置します。

```yaml
# .swiftlint.yml

# 無効化するルール
disabled_rules:
  - trailing_whitespace
  - todo
  - orphaned_doc_comment

# 有効化するオプトインルール
opt_in_rules:
  - empty_count
  - empty_string
  - closure_spacing
  - contains_over_filter_count
  - contains_over_filter_is_empty
  - contains_over_first_not_nil
  - contains_over_range_nil_comparison
  - discouraged_optional_boolean
  - empty_collection_literal
  - fallthrough
  - fatal_error_message
  - first_where
  - flatmap_over_map_reduce
  - identical_operands
  - joined_default_parameter
  - last_where
  - legacy_multiple
  - modifier_order
  - overridden_super_call
  - override_in_extension
  - pattern_matching_keywords
  - prefer_self_type_over_type_of_self
  - private_action
  - private_outlet
  - prohibited_super_call
  - reduce_into
  - redundant_nil_coalescing
  - redundant_type_annotation
  - sorted_first_last
  - toggle_bool
  - unavailable_function
  - unneeded_parentheses_in_closure_argument
  - unowned_variable_capture
  - untyped_error_in_catch
  - vertical_parameter_alignment_on_call
  - yoda_condition

# 除外するディレクトリ
excluded:
  - .build
  - .swiftpm
  - Pods
  - Carthage
  - DerivedData
  - Package.swift

# ルールのカスタマイズ
line_length:
  warning: 120
  error: 200
  ignores_comments: true
  ignores_urls: true

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000

function_body_length:
  warning: 50
  error: 100

function_parameter_count:
  warning: 6
  error: 8

type_name:
  min_length: 3
  max_length: 50

identifier_name:
  min_length: 2
  max_length: 50
  excluded:
    - id
    - x
    - y
    - i
    - j
    - ok

nesting:
  type_level: 2
  function_level: 3

# カスタムルール
custom_rules:
  no_print:
    name: "No print statements"
    regex: "\\bprint\\s*\\("
    message: "print() はデバッグ用途でのみ使用してください。本番コードでは Logger を使用してください。"
    severity: warning
```

#### Xcodeビルドフェーズへの追加

1. プロジェクト設定を開く
2. ターゲットを選択 → **Build Phases**
3. **+** → **New Run Script Phase**
4. 以下のスクリプトを追加:

```bash
if which mise > /dev/null; then
  eval "$(mise activate bash)"
  swiftlint
elif which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, run 'mise install' in the project directory"
fi
```

#### コマンドライン実行

```bash
# Lint実行
swiftlint

# 自動修正
swiftlint --fix

# 特定のファイルのみ
swiftlint lint --path Sources/
```

---

## Formatter

### SwiftFormat

コードフォーマットには **SwiftFormat** を使用します。

| 項目 | 内容 |
|------|------|
| リポジトリ | [nicklockwood/SwiftFormat](https://github.com/nicklockwood/SwiftFormat) |
| バージョン | 0.58.7+ |
| ルール数 | 100+ |

#### インストール

```bash
# mise経由でインストール（.mise.tomlに基づく）
mise install
```

#### 設定ファイル

プロジェクトルートに `.swiftformat` を配置します。

```bash
# .swiftformat

# Swift バージョン
--swiftversion 5.10

# インデント
--indent 4
--tabwidth 4
--smarttabs enabled

# 行の長さ
--maxwidth 120

# 波括弧のスタイル（K&R style）
--allman false

# 引数の折り返し
--wraparguments before-first
--wrapparameters before-first
--wrapcollections before-first
--wrapreturntype preserve
--wrapconditions after-first

# クロージャ
--closingparen balanced
--wrapternary default

# self の扱い
--self remove
--selfrequired 

# インポート
--importgrouping testable-last

# 空行
--trimwhitespace always
--emptybraces no-space

# その他
--semicolons never
--commas always
--stripunusedargs closure-only
--ifdef no-indent

# 無効化するルール
--disable redundantSelf
--disable trailingCommas
--disable wrapMultilineStatementBraces

# 除外するディレクトリ
--exclude .build,.swiftpm,Pods,Carthage,DerivedData
```

#### コマンドライン実行

```bash
# フォーマット実行
swiftformat .

# ドライラン（変更内容の確認）
swiftformat . --dryrun

# Lint モード（CI用）
swiftformat . --lint

# 特定のファイルのみ
swiftformat Sources/
```

---

## 開発フロー

以下のフローでコード品質を維持します。

```
┌─────────────────────────────────────────────────────────────────┐
│                        開発フロー                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [1. コーディング]                                               │
│         │                                                       │
│         ▼                                                       │
│  [2. 保存時 / pre-commit hook]                                  │
│         │                                                       │
│         ├──▶ SwiftFormat 実行（自動整形）                        │
│         │                                                       │
│         ▼                                                       │
│  [3. ビルド時]                                                  │
│         │                                                       │
│         ├──▶ SwiftLint 実行（警告/エラー表示）                   │
│         │                                                       │
│         ▼                                                       │
│  [4. コミット]                                                  │
│         │                                                       │
│         ├──▶ pre-commit hook で再チェック（オプション）          │
│         │                                                       │
│         ▼                                                       │
│  [5. プッシュ / Pull Request]                                   │
│         │                                                       │
│         ├──▶ GitHub Actions で CI チェック                      │
│         │                                                       │
│         ▼                                                       │
│  [6. マージ]                                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## セットアップ手順

### 1. 必要なツールのインストール

```bash
# Homebrew がない場合
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# mise のインストール
brew install mise

# シェルの設定（~/.zshrc に追加）
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc

# プロジェクトディレクトリで依存関係をインストール
cd /path/to/project
mise install
```

### 2. Git Hooks の設定（オプション）

```bash
# .git/hooks/pre-commit
#!/bin/sh

# mise のツールを有効化
eval "$(mise activate bash)"

echo "Running SwiftFormat..."
swiftformat . --lint
if [ $? -ne 0 ]; then
    echo "SwiftFormat found issues. Running auto-fix..."
    swiftformat .
    echo "Please review the changes and commit again."
    exit 1
fi

echo "Running SwiftLint..."
swiftlint --strict
if [ $? -ne 0 ]; then
    echo "SwiftLint found errors. Please fix them before committing."
    exit 1
fi

echo "All checks passed!"
exit 0
```

```bash
# 実行権限を付与
chmod +x .git/hooks/pre-commit
```

### 3. Xcode 設定

#### SwiftLint Build Phase

1. プロジェクト設定 → ターゲット → **Build Phases**
2. **+** → **New Run Script Phase**
3. 名前を「SwiftLint」に変更
4. スクリプトを追加:

```bash
if which mise > /dev/null; then
  eval "$(mise activate bash)"
  swiftlint
elif which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, run 'mise install' in the project directory"
fi
```

---

## CI/CD統合

### GitHub Actions

```yaml
# .github/workflows/lint.yml

name: Lint

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  lint:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install mise
        uses: jdx/mise-action@v2
      
      - name: Install dependencies
        run: mise install
      
      - name: Run SwiftLint
        run: mise exec -- swiftlint --strict --reporter github-actions-logging
      
      - name: Run SwiftFormat
        run: mise exec -- swiftformat . --lint
```

---

## ツール比較表

### 状態管理

| ライブラリ | 学習コスト | テスト容易性 | パフォーマンス | コミュニティ |
|-----------|:--------:|:----------:|:------------:|:----------:|
| TCA | 高 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Verge | 中 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| OneWay | 低 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| SwiftUI標準 | 低 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### Linter / Formatter

| ツール | 目的 | 自動修正 | ルール数 | Xcode統合 |
|--------|------|:------:|:------:|:--------:|
| SwiftLint | Linter | △ | 200+ | ◎ |
| SwiftFormat | Formatter | ◎ | 100+ | ○ |

---

## 参考リンク

### 状態管理
- [TCA GitHub](https://github.com/pointfreeco/swift-composable-architecture)
- [TCA ドキュメント](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/)
- [Point-Free](https://www.pointfree.co/)

### Linter / Formatter
- [SwiftLint GitHub](https://github.com/realm/SwiftLint)
- [SwiftFormat GitHub](https://github.com/nicklockwood/SwiftFormat)
- [mise GitHub](https://github.com/jdx/mise)
- [mise ドキュメント](https://mise.jdx.dev/)

### スタイルガイド
- [Google Swift Style Guide](https://google.github.io/swift/)
- [Kodeco Swift Style Guide](https://github.com/kodecocodes/swift-style-guide)
- [Airbnb Swift Style Guide](https://github.com/airbnb/swift)

---

*最終更新: 2025年12月*
