#!/usr/bin/env bash
# ============================================================
# gstack-gemini 移除腳本
# 從 Gemini CLI 移除所有 gstack 技能的符號連結（symlink）
#
# 原理：
#   install-gemini.sh 建立的是 symlink，不是真實檔案。
#   本腳本只刪除 ~/.gemini/skills/ 裡的 gstack-* 連結，
#   不會動到 gstack 專案本身的任何檔案。
#
# 使用方式：
#   bash uninstall-gemini.sh
#
# 重新安裝：
#   bash install-gemini.sh
# ============================================================
set -euo pipefail

echo "🗑️  從 Gemini CLI 移除 gstack 技能..."

count=0

# 掃描 ~/.gemini/skills/ 目錄下所有 gstack-* 的項目（連結或目錄）
for dir in "$HOME"/.gemini/skills/gstack*; do
  # 若找不到任何匹配（glob 沒有展開），跳過
  [ -e "$dir" ] || continue

  # 刪除連結或目錄
  rm -rf "$dir"
  echo "  已移除 $(basename "$dir")"
  count=$((count + 1))
done

# 結果摘要
if [ "$count" -eq 0 ]; then
  echo "⚠️  在 ~/.gemini/skills/ 找不到任何 gstack 技能（可能已移除過）"
else
  echo "✅ 已從 ~/.gemini/skills/ 移除 $count 個 gstack 技能"
fi
