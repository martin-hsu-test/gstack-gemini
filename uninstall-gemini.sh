#!/usr/bin/env bash
set -euo pipefail

echo "🗑️  Uninstalling gstack skills from Gemini CLI..."

count=0
for dir in "$HOME"/.gemini/skills/gstack*; do
  [ -e "$dir" ] || continue
  rm -rf "$dir"
  echo "  removed $(basename "$dir")"
  count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
  echo "⚠️  No gstack skills found in ~/.gemini/skills/"
else
  echo "✅ Removed $count gstack skills from ~/.gemini/skills/"
fi
