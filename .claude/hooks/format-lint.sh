#!/bin/bash
# .claude/hooks/format-lint.sh
# PostToolUse hook: 変更ファイルに対してformat + lintを実行

set -o pipefail

# stdin からJSONを読み取り
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# パス検証
if [[ -z "$file_path" ]]; then
    exit 0
fi

if [[ ! -f "$file_path" ]]; then
    exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# 拡張子を取得
ext="${file_path##*.}"

case "$ext" in
    swift)
        echo "Running Swift formatter and linter on: $file_path"
        mise run format:swift 2>&1 || echo "[Warning] format:swift failed"
        mise run lint:swift 2>&1 || echo "[Warning] lint:swift failed"
        ;;
    json | yaml | yml | md)
        echo "Running Prettier on: $file_path"
        mise run format:prettier 2>&1 || echo "[Warning] format:prettier failed"
        mise run lint:prettier 2>&1 || echo "[Warning] lint:prettier failed"
        ;;
    *)
        # 対象外の拡張子はスキップ
        ;;
esac

exit 0
