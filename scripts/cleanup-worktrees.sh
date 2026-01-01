#!/bin/bash
#
# cleanup-worktrees.sh
#
# Git worktree cleanup script that removes worktrees matching:
#   1. No uncommitted changes (clean git status)
#   2. No OPEN or Draft PR associated with the branch
#
# Usage:
#   ./cleanup-worktrees.sh [--dry-run] [--force|-f]
#
# Options:
#   --dry-run   Show what would be removed without actually removing
#   --force, -f Remove without confirmation prompt
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Main repository root (two levels up from .claude/scripts/)
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Options
DRY_RUN=false
FORCE=false

# Arrays to track worktrees
declare -a TO_REMOVE=()
declare -a REMOVE_PATHS=()
declare -a PRESERVED_CHANGES=()
declare -a PRESERVED_PR=()

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Remove git worktrees that have no changes and no active PR.

OPTIONS:
    --dry-run       Show what would be removed without actually removing
    --force, -f     Remove without confirmation prompt
    -h, --help      Show this help message

REMOVAL CRITERIA:
    A worktree is removed if ALL conditions are met:
    - git status is clean (no uncommitted changes)
    - No OPEN or Draft PR exists for the branch

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}" >&2
            usage
            exit 1
            ;;
    esac
done

# Check if we're in a git repository
if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not a git repository: $REPO_ROOT${NC}" >&2
    exit 1
fi

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: gh CLI is required but not installed.${NC}" >&2
    echo "Install it from: https://cli.github.com/" >&2
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${RED}Error: gh CLI is not authenticated.${NC}" >&2
    echo "Run: gh auth login" >&2
    exit 1
fi

echo -e "${BLUE}Scanning worktrees...${NC}"
echo ""

# Get list of worktrees
while IFS= read -r line; do
    # Parse worktree line: /path/to/worktree  commit  [branch]
    worktree_path=$(echo "$line" | awk '{print $1}')
    branch_info=$(echo "$line" | grep -oE '\[.*\]' || echo "")
    branch_name=$(echo "$branch_info" | tr -d '[]')

    # Skip if path doesn't exist
    if [[ ! -d "$worktree_path" ]]; then
        continue
    fi

    # Skip main repository (bare or main worktree)
    if [[ "$worktree_path" == "$REPO_ROOT" ]]; then
        continue
    fi

    # Skip detached HEAD
    if [[ -z "$branch_name" || "$branch_name" == "detached HEAD" ]]; then
        continue
    fi

    # Check for uncommitted changes
    status_output=$(git -C "$worktree_path" status --porcelain 2>/dev/null || echo "ERROR")

    if [[ "$status_output" == "ERROR" ]]; then
        continue
    fi

    if [[ -n "$status_output" ]]; then
        # Has uncommitted changes - preserve
        PRESERVED_CHANGES+=("$branch_name ($worktree_path)")
        continue
    fi

    # Check for active PR (OPEN or Draft)
    pr_info=$(gh pr list --head "$branch_name" --state open --json number,title,isDraft 2>/dev/null || echo "[]")

    if [[ "$pr_info" != "[]" && "$pr_info" != "" ]]; then
        # Has active PR - preserve
        pr_number=$(echo "$pr_info" | grep -oE '"number":[0-9]+' | head -1 | grep -oE '[0-9]+')
        is_draft=$(echo "$pr_info" | grep -oE '"isDraft":true' || echo "")

        if [[ -n "$is_draft" ]]; then
            PRESERVED_PR+=("$branch_name ($worktree_path) [PR #$pr_number Draft]")
        else
            PRESERVED_PR+=("$branch_name ($worktree_path) [PR #$pr_number Open]")
        fi
        continue
    fi

    # This worktree can be removed
    TO_REMOVE+=("$branch_name")
    REMOVE_PATHS+=("$worktree_path")

done < <(git -C "$REPO_ROOT" worktree list 2>/dev/null)

# Display results
if [[ ${#TO_REMOVE[@]} -gt 0 ]]; then
    echo -e "${GREEN}Worktrees to be removed (clean, no active PR):${NC}"
    for i in "${!TO_REMOVE[@]}"; do
        echo -e "  - ${TO_REMOVE[$i]} (${REMOVE_PATHS[$i]})"
    done
    echo ""
fi

if [[ ${#PRESERVED_CHANGES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Worktrees preserved (has changes):${NC}"
    for item in "${PRESERVED_CHANGES[@]}"; do
        echo -e "  - $item"
    done
    echo ""
fi

if [[ ${#PRESERVED_PR[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Worktrees preserved (PR OPEN/Draft):${NC}"
    for item in "${PRESERVED_PR[@]}"; do
        echo -e "  - $item"
    done
    echo ""
fi

# Exit if nothing to remove
if [[ ${#TO_REMOVE[@]} -eq 0 ]]; then
    echo -e "${BLUE}No worktrees to remove.${NC}"
    exit 0
fi

# Dry run - just show what would be removed
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}Dry run mode - no worktrees were removed.${NC}"
    exit 0
fi

# Confirmation prompt (unless --force)
if [[ "$FORCE" != true ]]; then
    echo -n "Remove ${#TO_REMOVE[@]} worktree(s)? [y/N]: "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Remove worktrees
echo ""
echo -e "${BLUE}Removing worktrees...${NC}"
failed=0
for i in "${!REMOVE_PATHS[@]}"; do
    worktree_path="${REMOVE_PATHS[$i]}"
    branch_name="${TO_REMOVE[$i]}"

    echo -n "  Removing $branch_name... "
    if git -C "$REPO_ROOT" worktree remove "$worktree_path" 2>/dev/null; then
        echo -e "${GREEN}done${NC}"
    else
        echo -e "${RED}failed${NC}"
        ((failed++))
    fi
done

# Prune stale worktree references
echo ""
echo -n "Pruning stale worktree references... "
git -C "$REPO_ROOT" worktree prune
echo -e "${GREEN}done${NC}"

# Summary
removed=$((${#TO_REMOVE[@]} - failed))
echo ""
echo -e "${GREEN}Removed $removed worktree(s).${NC}"
if [[ $failed -gt 0 ]]; then
    echo -e "${RED}Failed to remove $failed worktree(s).${NC}"
fi
