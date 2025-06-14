#!/bin/bash

echo "🔍 Scanning all Git repositories under $(pwd)..."
echo

for dir in */; do
  if [ -d "$dir/.git" ]; then
    cd "$dir" || continue
    echo "📂 Repository: $dir"

    # Check for uncommitted changes
    if ! git diff --quiet || ! git diff --cached --quiet; then
      echo "  ⚠️  Uncommitted changes present"
    fi

    # Check for unpushed commits
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [ -n "$UPSTREAM" ]; then
      AHEAD=$(git rev-list --count HEAD.."$UPSTREAM")
      BEHIND=$(git rev-list --count "$UPSTREAM"..HEAD)
      if [ "$BEHIND" -gt 0 ]; then
        echo "  🚀 Commits pending to push: $BEHIND"
      fi
    else
      echo "  ❓ No upstream tracking branch set"
    fi

    cd .. || continue
    echo
  fi
done
